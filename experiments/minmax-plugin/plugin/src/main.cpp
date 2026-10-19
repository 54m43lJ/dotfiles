// Hyprland minimize/maximize feasibility probe.
//
// This plugin does NOT alter window state. It proves that an in-process
// plugin can see the otherwise-dropped app minimize request and the
// maximize request that Hyprland already handles natively.

#define WLR_USE_UNSTABLE

#include <hyprland/src/plugins/PluginAPI.hpp>
#include <hyprland/src/desktop/view/Window.hpp>
#include <hyprland/src/protocols/XDGShell.hpp>
#include <hyprland/src/xwayland/XSurface.hpp>
#include <hyprland/src/event/EventBus.hpp>
#include <hyprland/src/managers/fullscreen/FullscreenController.hpp>

#include <fstream>
#include <optional>
#include <string>

using OnUpdateStateFn = void (*)(Desktop::View::CWindow*);

static HANDLE g_handle = nullptr;
static CFunctionHook* g_updateStateHook = nullptr;
static OnUpdateStateFn g_originalUpdateState = nullptr;
static CHyprSignalListener g_windowOpenListener;
static CHyprSignalListener g_windowFullscreenListener;

static constexpr const char* LOG_PATH = "/tmp/hyprminmax-events.log";

static void logLine(const std::string& line) {
    std::ofstream out(LOG_PATH, std::ios::app);
    out << line << '\n';
}

static std::string optBool(const std::optional<bool>& value) {
    if (!value)
        return "none";
    return *value ? "1" : "0";
}

static std::string windowTag(Desktop::View::CWindow* window) {
    if (!window)
        return "window=null";
    return "class=" + window->m_class + " title=" + window->m_title + " addr=" + std::to_string(reinterpret_cast<uintptr_t>(window));
}

static void hookUpdateState(Desktop::View::CWindow* window) {
    if (window) {
        if (auto xdg = window->m_xdgSurface.lock()) {
            if (auto toplevel = xdg->m_toplevel.lock()) {
                if (toplevel->m_state.requestsMinimize.has_value())
                    logLine("MINIMIZE_REQUEST " + windowTag(window) + " value=" + optBool(toplevel->m_state.requestsMinimize));
                if (toplevel->m_state.requestsMaximize.has_value())
                    logLine("MAXIMIZE_REQUEST " + windowTag(window) + " value=" + optBool(toplevel->m_state.requestsMaximize));
            }
        }

        if (auto x11 = window->m_xwaylandSurface.lock()) {
            if (x11->m_state.requestsMinimize.has_value())
                logLine("MINIMIZE_REQUEST_X11 " + windowTag(window) + " value=" + optBool(x11->m_state.requestsMinimize));
            if (x11->m_state.requestsMaximize.has_value())
                logLine("MAXIMIZE_REQUEST_X11 " + windowTag(window) + " value=" + optBool(x11->m_state.requestsMaximize));
        }
    }

    if (g_originalUpdateState)
        g_originalUpdateState(window);
}

APICALL EXPORT std::string PLUGIN_API_VERSION() {
    return HYPRLAND_API_VERSION;
}

APICALL EXPORT PLUGIN_DESCRIPTION_INFO PLUGIN_INIT(HANDLE handle) {
    g_handle = handle;

    const std::string SERVER_HASH = __hyprland_api_get_hash();
    const std::string CLIENT_HASH = __hyprland_api_get_client_hash();

    logLine("PLUGIN_INIT server_hash=" + SERVER_HASH + " client_hash=" + CLIENT_HASH + " api=" + HYPRLAND_API_VERSION);

    if (SERVER_HASH != CLIENT_HASH) {
        logLine("VERSION_MISMATCH");
        return {"hyprminmax", "Minimize/maximize feasibility probe (version mismatch)", "john", "0.1"};
    }

    g_windowOpenListener = Event::bus()->m_events.window.open.listen([](PHLWINDOW window) {
        if (window)
            logLine("EVENT window.open " + windowTag(window.get()));
    });

    g_windowFullscreenListener = Event::bus()->m_events.window.fullscreen.listen([](PHLWINDOW window) {
        if (!window)
            return;
        const auto MODES = Fullscreen::controller()->getFullscreenModes(window);
        logLine("EVENT window.fullscreen " + windowTag(window.get()) + " internal=" + std::to_string(static_cast<int>(MODES.internal)) +
                " client=" + std::to_string(static_cast<int>(MODES.client)));
    });

    const auto MATCHES = HyprlandAPI::findFunctionsByName(handle, "onUpdateState");
    logLine("FIND onUpdateState matches=" + std::to_string(MATCHES.size()));

    const SFunctionMatch* target = nullptr;
    for (const auto& match : MATCHES) {
        logLine("FUNC addr=" + std::to_string(reinterpret_cast<uintptr_t>(match.address)) + " sig=" + match.signature + " demangled=" + match.demangled);
        if (match.demangled.find("CWindow::onUpdateState") != std::string::npos)
            target = &match;
    }

    if (!target && !MATCHES.empty())
        target = &MATCHES.front();

    if (target) {
        g_updateStateHook = HyprlandAPI::createFunctionHook(handle, target->address, reinterpret_cast<const void*>(&hookUpdateState));
        if (!g_updateStateHook) {
            logLine("HOOK onUpdateState create=failed");
        } else if (!g_updateStateHook->hook()) {
            logLine("HOOK onUpdateState install=failed");
        } else {
            g_originalUpdateState = reinterpret_cast<OnUpdateStateFn>(g_updateStateHook->m_original);
            logLine("HOOK onUpdateState install=ok original=" + std::to_string(reinterpret_cast<uintptr_t>(g_originalUpdateState)));
        }
    } else {
        logLine("HOOK onUpdateState target=not_found");
    }

    return {"hyprminmax", "Minimize/maximize feasibility probe", "john", "0.1"};
}

APICALL EXPORT void PLUGIN_EXIT() {
    if (g_updateStateHook) {
        HyprlandAPI::removeFunctionHook(g_handle, g_updateStateHook);
        g_updateStateHook = nullptr;
        g_originalUpdateState = nullptr;
    }

    g_windowOpenListener.reset();
    g_windowFullscreenListener.reset();

    logLine("PLUGIN_EXIT");
}

-- ~/.config/hypr/hyprland.lua
-- Hyprland v0.55+ Lua configuration

local mainMod       = "SUPER"
local defaultBrowser = "gtk-launch brave-browser"
local hypr_dir       = os.getenv("HOME") .. "/.config/hypr"

-- ============================================
-- Monitor defaults (before device-specific overrides)
-- ============================================
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto-right",
    reserved = { top = -5 },
})

-- Toggle the first monitor's transform between 0 (normal) and 1 (90°)
local function toggle_orientation()
    local mon = hl.get_active_monitor()
    if not mon then return end
    local new_transform = (mon.transform == 0) and 1 or 0
    hl.monitor({
        output    = mon.name,
        transform = new_transform,
    })
    hl.exec_cmd("hyprpaper")
end

-- Per-monitor auto-scale: 1080p and below → 1x, above → 2x
-- FALLBACK (Hyprland's zero-outputs placeholder, seen for ~2s when a real
-- panel re-trains its DP link on wake) must never receive config writes.
local function real_monitors()
    local out = {}
    for _, mon in ipairs(hl.get_monitors()) do
        if mon.name ~= "FALLBACK" then out[#out + 1] = mon end
    end
    return out
end

local function apply_monitor_scales()
    for _, mon in ipairs(real_monitors()) do
        local scale = (mon.height > 1080) and 2 or 1
        hl.monitor({
            output   = mon.name,
            mode     = "preferred",
            position = "auto-right",
            scale    = scale,
            reserved = { top = -5 },
        })
    end
end

-- Per-monitor workspace ranges: monitor N → (N*10+1) .. (N*10+10).
-- MAP_MONITOR learns name → base once per session and only grows ("in,
-- never out"): a monitor keeps its decade across hotplug storms and
-- re-ordering, so no name can ever hold more than one range. CUR_BASE is
-- the highest base handed out; new monitors take the next one. Paranoia
-- cap: past MAX_BASE entries the map is rebuilt from what is connected.
local MAP_MONITOR = {}
local CUR_BASE = -1
local MAX_BASE = 100

local function assign_workspaces()
    for _, mon in ipairs(real_monitors()) do
        if not MAP_MONITOR[mon.name] then
            CUR_BASE = CUR_BASE + 1
            MAP_MONITOR[mon.name] = CUR_BASE
        end
    end

    local n = 0
    for _ in pairs(MAP_MONITOR) do n = n + 1 end
    if n > MAX_BASE then
        MAP_MONITOR = {}
        CUR_BASE = -1
        for _, mon in ipairs(real_monitors()) do
            CUR_BASE = CUR_BASE + 1
            MAP_MONITOR[mon.name] = CUR_BASE
        end
    end

    for name, base in pairs(MAP_MONITOR) do
        for _, mon in ipairs(real_monitors()) do
            if mon.name == name then
                for i = 1, 10 do
                    hl.workspace_rule({
                        workspace  = tostring(base * 10 + i),
                        monitor    = name,
                        persistent = false,
                    })
                end
                break
            end
        end
    end
end

-- ============================================
-- Device-specific configs: load every file deployed into special/.
-- per-device-conf/<device>/module.sh copies its hypr.lua there; no flag
-- gating — whatever is present runs (multiple files merge like multiple
-- flags did). Directory scan via io.popen (no lfs in embedded Lua).
-- ============================================
local scan = io.popen("ls -1 " .. hypr_dir .. "/special/*.lua 2>/dev/null")
if scan then
    for f in scan:lines() do
        dofile(f)
    end
    scan:close()
end

-- ============================================
-- Window rules (always active)
-- ============================================
require("windowrule")

-- Noborder for floating windows
hl.window_rule({
    name  = "noborder-float",
    match = { float = true },
    border_size = 0,
})

-- Vicinae launcher: blur the layer, no animations
hl.layer_rule({ name = "vicinae-blur",         match = { namespace = "vicinae" }, blur = true, ignore_alpha = 0 })
hl.layer_rule({ name = "vicinae-no-animation", match = { namespace = "vicinae" }, no_anim = true })

-- ============================================
-- Look and feel
-- ============================================
hl.config({
    general = {
        gaps_in     = 2,
        gaps_out    = { top = 5, bottom = 8, left = 6, right = 6 },
        border_size = 3,
        col = {
            active_border = {
                colors = { "rgba(FFF7E4ff)", "rgba(231F1Fff)", "rgba(231F1Fff)" },
                angle  = 45,
            },
            inactive_border = "rgba(231F1Faa)",
        },
        layout = "master",
    },
})

-- Curves & animations
hl.curve("myBezier", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })

hl.animation({ leaf = "windows",      enabled = true, speed = 7,  bezier = "myBezier" })
hl.animation({ leaf = "windowsOut",   enabled = true, speed = 7,  bezier = "default",  style = "popin 80%" })
hl.animation({ leaf = "border",       enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "borderangle",  enabled = false })
hl.animation({ leaf = "fade",         enabled = true, speed = 7,  bezier = "default" })
hl.animation({ leaf = "workspaces",   enabled = true, speed = 6,  bezier = "default" })

-- Layouts
hl.config({
    dwindle = {
        preserve_split = true,
    },
})

hl.config({
    master = {
        new_status = "slave",
    },
})

hl.config({
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        focus_on_activate        = true,
        -- focusing a tiled window under a fullscreen/maximized one takes
        -- over WITHOUT dropping the fullscreen/maximized state (default 2
        -- unmaximizes it on every focus switch)
        on_focus_under_fullscreen = 1,
    },
})

-- TODO #1 diagnostics: 0.56 disables the file log by default; keep it on so
-- dpms/wake cycles can be autopsied in $XDG_RUNTIME_DIR/hypr/<sig>/hyprland.log.
-- Remove together with wake_recovery once a release with #15890 ships.
hl.config({
    debug = {
        disable_logs = false,
        disable_time = false,
    },
})

-- Decoration (overridden by device-specific configs)
hl.config({
    decoration = {
        rounding         = 6,
        inactive_opacity = 0.85,
        blur = {
            enabled = true,
            size    = 4,
            passes  = 1,
        },
        shadow = {
            enabled        = true,
            range          = 1,
            offset         = { 2, 2 },
            color          = "rgb(8E7753)",
            color_inactive = "rgba(ffffff00)",
        },
    },
})

-- ============================================
-- Input
-- ============================================
hl.config({
    input = {
        kb_layout           = "us",
        kb_variant          = "",
        kb_model            = "",
        kb_options          = "",
        kb_rules            = "",
        numlock_by_default  = true,
        follow_mouse        = 2,
        mouse_refocus       = false,
        sensitivity         = 0.1,
        accel_profile       = "flat",
        float_switch_override_focus = 0,
        touchpad = {
            disable_while_typing = true,
            natural_scroll       = false,
        },
    },
})

-- ============================================
-- Keybinds
-- ============================================

-- System
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("hyprctl kill"))
hl.bind(mainMod .. " + Q",          hl.dsp.exec_cmd("~/.config/vicinae/power-menu.sh"))
hl.bind(mainMod .. " + SHIFT + Q",  hl.dsp.exec_cmd("hyprshutdown"))
hl.bind(mainMod .. " + P",          toggle_orientation)

-- Utilities & controls
hl.bind(mainMod .. " + SPACE",      hl.dsp.exec_cmd("vicinae toggle"))
hl.bind("ALT + SHIFT + 3",          hl.dsp.exec_cmd("hyprshot -m output -o ~/Desktop/"))
hl.bind("ALT + SHIFT + 4",          hl.dsp.exec_cmd("hyprshot -m region -o ~/Desktop/"))

-- Media keys
hl.bind("XF86AudioPlay",            hl.dsp.exec_cmd("playerctl play-pause"),                                     { locked = true })
hl.bind("XF86AudioPrev",            hl.dsp.exec_cmd("playerctl previous"),                                       { locked = true })
hl.bind("XF86AudioNext",            hl.dsp.exec_cmd("playerctl next"),                                           { locked = true })
hl.bind("XF86AudioMute",            hl.dsp.exec_cmd("pactl set-sink-mute `pactl get-default-sink` toggle"),      { locked = true })
hl.bind("XF86AudioLowerVolume",     hl.dsp.exec_cmd("pactl set-sink-volume `pactl get-default-sink` -5%"),       { locked = true })
hl.bind("XF86AudioRaiseVolume",     hl.dsp.exec_cmd("pactl set-sink-volume `pactl get-default-sink` +5%"),       { locked = true })

-- Applications
hl.bind(mainMod .. " + C",   hl.dsp.exec_cmd("foot"))
hl.bind(mainMod .. " + E",   hl.dsp.exec_cmd("nemo"))
hl.bind(mainMod .. " + B",   hl.dsp.exec_cmd(defaultBrowser))
hl.bind(mainMod .. " + L",   hl.dsp.exec_cmd("gtk-launch obsidian"))
hl.bind("CTRL + ALT + K",    hl.dsp.exec_cmd("gtk-launch org.keepassxc.KeePassXC"))

-- Layout
hl.bind(mainMod .. " + M", hl.dsp.layout("swapwithmaster"))

-- Window management
hl.bind(mainMod .. " + V",            hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + W",            hl.dsp.window.close())
hl.bind(mainMod .. " + mouse:274",    hl.dsp.window.close())
hl.bind(mainMod .. " + left",         hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right",        hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",           hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",         hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + mouse:272",    hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273",    hl.dsp.window.resize(), { mouse = true })
hl.bind(mainMod .. " + GRAVE",        hl.dsp.window.cycle_next())
hl.bind(mainMod .. " + RETURN",              hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(mainMod .. " + SHIFT + RETURN",    hl.dsp.window.fullscreen())

-- Workspaces (per-monitor ranges via workspace rules + selectors)
-- Lua assign_workspaces() binds 1-10 to monitor 1, 11-20 to monitor 2, etc.
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,           hl.dsp.focus({ workspace = "r~" .. i }))
    hl.bind(mainMod .. " + SHIFT + " .. key,   hl.dsp.window.move({ workspace = "r~" .. i }))
end
hl.bind(mainMod .. " + mouse_down",       hl.dsp.focus({ workspace = "m+1" }))
hl.bind(mainMod .. " + mouse_up",         hl.dsp.focus({ workspace = "m-1" }))
hl.bind(mainMod .. " + TAB",              hl.dsp.focus({ workspace = "m+1" }))
hl.bind(mainMod .. " + SHIFT + TAB",      hl.dsp.focus({ workspace = "m-1" }))
hl.bind(mainMod .. " + SHIFT + right",    hl.dsp.window.move({ workspace = "r+1" }))
hl.bind(mainMod .. " + SHIFT + left",     hl.dsp.window.move({ workspace = "r-1" }))
hl.bind(mainMod .. " + N",                hl.dsp.focus({ workspace = "emptym" }))
hl.bind(mainMod .. " + SHIFT + N",        hl.dsp.window.move({ workspace = "emptym" }))

-- ============================================
-- Autostart
-- ============================================
hl.on("hyprland.start", function()
    apply_monitor_scales()
    assign_workspaces()
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("bread")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("vicinae server")
    hl.exec_cmd("udiskie &")
    -- XDG autostart (both system-wide and user entries): takes over
    -- fcitx5, blueman-applet and anything apps register themselves
    -- (Clash Verge, keepassxc, OpenRGB toggles write ~/.config/autostart)
    hl.exec_cmd("dex -a -s /etc/xdg/autostart/:~/.config/autostart/")
    -- hl.exec_cmd("foot")
end)

-- ============================================
-- DPMS/wake recovery workaround (TODO #1)
-- dpms off=>on strands floating windows off-screen and leaves keyboard
-- focus dead: Hyprland <= v0.56.2 corrupts monitor/workspace state through
-- the FALLBACK placeholder interlude (the panel drops HPD when the output
-- is disabled). Upstream: #15800 (same state corruption, crashes there),
-- fixed on main by #15890 (2026-08-24) — no release contains it yet.
-- Until then: after a real monitor (re)appears, drag stranded floats back
-- into view and re-focus the last window so input works without having to
-- switch workspaces.
-- ============================================
local function wake_recovery()
    hl.timer(function()
        -- logical (scale-applied) boxes of every real monitor
        local boxes = {}
        for _, m in ipairs(hl.get_monitors()) do
            if m.name ~= "FALLBACK" and m.scale > 0 then
                boxes[m.name] = {
                    x = m.x, y = m.y,
                    w = math.floor(m.size.width / m.scale),
                    h = math.floor(m.size.height / m.scale),
                }
            end
        end

        for _, w in ipairs(hl.get_windows()) do
            if w.floating and w.mapped and not w.hidden and w.monitor
               and boxes[w.monitor.name] then
                local b      = boxes[w.monitor.name]
                local at, sz = w.at, w.size
                if sz.x > 0 and sz.y > 0 then
                    -- rescue when <25% of the float remains inside its
                    -- monitor's logical box (deliberate partial off-screen
                    -- placement is left alone)
                    local ix = math.max(0, math.min(at.x + sz.x, b.x + b.w) - math.max(at.x, b.x))
                    local iy = math.max(0, math.min(at.y + sz.y, b.y + b.h) - math.max(at.y, b.y))
                    if ix * iy < 0.25 * sz.x * sz.y then
                        local nx = math.max(b.x, b.x + math.floor((b.w - sz.x) / 2))
                        local ny = math.max(b.y, b.y + math.floor((b.h - sz.y) / 2))
                        -- NOTE: hl.dsp.* returns a dispatcher object; it must be
                        -- run through hl.dispatch (calling it directly errors out).
                        -- pass the window OBJECT, not a "0x..." string: only
                        -- "address:0x..." is a valid selector, an unresolved
                        -- selector makes the dispatcher silently no-op
                        hl.dispatch(hl.dsp.window.move({ window = w, x = nx, y = ny }))
                    end
                end
            end
        end

        -- a dpms cycle on the last monitor resets seat focus entirely
        -- (CMonitor::onDisconnect clears window/surface/monitor focus and
        -- the reconnect path may leave focus on a bare layer surface).
        -- Restore it — but never fight hyprlock: while locked, unlock
        -- refocuses anyway.
        if not hl.get_active_window() then
            local lockpid = io.popen("pidof hyprlock 2>/dev/null"):read("*l")
            if not lockpid then
                local act    = hl.get_active_workspace()
                local last   = hl.get_last_window()
                local target = nil
                if last and act and last.workspace and last.workspace.id == act.id then
                    target = last
                elseif act then
                    -- last focused window lives on another workspace (focusing
                    -- it would switch); take any live window on the active one
                    for _, w in ipairs(hl.get_workspace_windows(act)) do
                        if w.mapped and not w.hidden then
                            target = w
                            break
                        end
                    end
                end
                if target then
                    hl.dispatch(hl.dsp.focus({ window = target }))
                end
            end
        end
    end, { timeout = 3000, type = "oneshot" })
end

hl.on("monitor.added", function()
    apply_monitor_scales()
    assign_workspaces()
    wake_recovery()
end)

hl.on("config.reloaded", function()
    apply_monitor_scales()
    assign_workspaces()
end)

-- ============================================
-- Environment
-- ============================================
hl.env("EDITOR", "nvim")
hl.env("XCURSOR_SIZE", "24")
hl.env("XMODIFIERS", "@im=fcitx")
hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")
hl.env("SSH_AUTH_SOCK", os.getenv("XDG_RUNTIME_DIR") .. "/gcr/ssh")

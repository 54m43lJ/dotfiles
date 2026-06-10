-- ~/.config/hypr/hyprland.lua
-- Hyprland v0.55+ Lua configuration

local mainMod       = "SUPER"
local defaultBrowser = "gtk-launch brave-browser"
local hypr_dir       = os.getenv("HOME") .. "/.config/hypr"

package.path = package.path .. ";" .. hypr_dir .. "/?.lua"
package.path = package.path .. ";" .. hypr_dir .. "/special/?.lua"

-- ============================================
-- Monitor defaults (before device-specific overrides)
-- ============================================
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto-right",
    reserved = { top = -5 },
})

-- Per-monitor auto-scale: 1080p and below → 1x, above → 2x
local function apply_monitor_scales()
    for _, mon in ipairs(hl.get_monitors()) do
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

-- Per-monitor workspace ranges: monitor 1 → 1-10, monitor 2 → 11-20, etc.
local function assign_workspaces()
    for idx, mon in ipairs(hl.get_monitors()) do
        local base = (idx - 1) * 10
        for i = 1, 10 do
            hl.workspace_rule({
                workspace  = tostring(base + i),
                monitor    = mon.name,
                persistent = false,
            })
        end
    end
end

-- ============================================
-- Device-specific flags (set by deploy modules)
-- ============================================
local flags = require("flags")

if flags.macbookpro  then require("macbookpro")  end
if flags.pc_changsha then require("pc_changsha") end
if flags.xiaomi_book then require("xiaomi_book") end

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
hl.bind(mainMod .. " + Q",          hl.dsp.exec_cmd("nwg-bar -t hypr.json"))
hl.bind(mainMod .. " + SHIFT + Q",  hl.dsp.exec_cmd("hyprshutdown"))
hl.bind(mainMod .. " + P",          hl.dsp.exec_cmd(hypr_dir .. "/scripts/orientation"))

-- Utilities & controls
hl.bind(mainMod .. " + SPACE",      hl.dsp.exec_cmd("wofi"))
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
hl.bind(mainMod .. " + mouse_down",       hl.dsp.focus({ workspace = "m-1" }))
hl.bind(mainMod .. " + mouse_up",         hl.dsp.focus({ workspace = "m+1" }))
hl.bind(mainMod .. " + TAB",              hl.dsp.focus({ workspace = "m+1" }))
hl.bind(mainMod .. " + SHIFT + TAB",      hl.dsp.focus({ workspace = "m-1" }))
hl.bind(mainMod .. " + SHIFT + right",    hl.dsp.window.move({ workspace = "m+1" }))
hl.bind(mainMod .. " + SHIFT + left",     hl.dsp.window.move({ workspace = "m-1" }))
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
    hl.exec_cmd("eww-launcher")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("udiskie &")
    hl.exec_cmd("blueman-applet &")
    hl.exec_cmd("fcitx5 -d")
    hl.exec_cmd("foot")
    hl.exec_cmd("bash -c 'gtk-launch cfw && eww reload'")
end)

hl.on("monitor.added", function()
    apply_monitor_scales()
    assign_workspaces()
end)

hl.on("monitor.removed", function()
    apply_monitor_scales()
    assign_workspaces()
end)

hl.on("config.reloaded", function()
    apply_monitor_scales()
end)

-- ============================================
-- Environment
-- ============================================
hl.env("EDITOR", "nvim")
hl.env("XCURSOR_SIZE", "24")
hl.env("XMODIFIERS", "@im=fcitx")
hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")
hl.env("SSH_AUTH_SOCK", os.getenv("XDG_RUNTIME_DIR") .. "/gcr/ssh")

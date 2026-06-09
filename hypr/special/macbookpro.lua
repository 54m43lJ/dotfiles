-- ~/.config/hypr/special/macbookpro.lua
-- MacBook Pro specific settings

hl.monitor({
    output = "eDP-1",
    mode   = "preferred",
    scale  = 2,
})

hl.env("HYPR_4K", "1")

hl.workspace_rule({ workspace = "1", monitor = "eDP-1" })

hl.device({
    name           = "bcm5974",
    sensitivity    = 0.12,
    accel_profile  = "adaptive",
    scroll_factor   = 0.5,
    tap_to_click   = true,
    drag_lock      = 1,
    tap_and_drag   = false,
    drag_3fg       = 1,
})

hl.gesture({
    fingers   = 4,
    direction = "horizontal",
    action    = "workspace",
})

hl.config({
    gestures = {
        workspace_swipe_distance = 500,
        workspace_swipe_invert   = false,
    },
    decoration = {
        rounding          = 4,
        inactive_opacity  = 0.85,
        blur = { enabled = false },
        shadow = {
            enabled         = true,
            range           = 1,
            offset          = { 2, 2 },
            color           = "rgb(8E7753)",
            color_inactive  = "rgba(ffffff00)",
        },
    },
})

-- Workaround for macbook keyboard: duplicate media keys with CTRL
hl.bind("CTRL + XF86AudioPlay",         hl.dsp.exec_cmd("playerctl play-pause"),                                     { locked = true })
hl.bind("CTRL + XF86AudioPrev",         hl.dsp.exec_cmd("playerctl previous"),                                       { locked = true })
hl.bind("CTRL + XF86AudioNext",         hl.dsp.exec_cmd("playerctl next"),                                           { locked = true })
hl.bind("CTRL + XF86AudioMute",         hl.dsp.exec_cmd("pactl set-sink-mute `pactl get-default-sink` toggle"),      { locked = true })
hl.bind("CTRL + XF86AudioLowerVolume",  hl.dsp.exec_cmd("pactl set-sink-volume `pactl get-default-sink` -5%"),       { locked = true })
hl.bind("CTRL + XF86AudioRaiseVolume",  hl.dsp.exec_cmd("pactl set-sink-volume `pactl get-default-sink` +5%"),       { locked = true })

-- ~/.config/hypr/special/xiaomi_book.lua
-- Xiaomi Book specific settings (HiDPI display + touchpad gestures)

-- Internal laptop display (3120x2080, HiDPI)
hl.monitor({
    output   = "eDP-1",
    mode     = "preferred",
    scale    = 2,
    position = "0x0",
})

-- External 4K monitor (VG273U PRO, 27" 3840x2160)
-- Positioned upper-right of laptop: x=right, y=bottom-aligned
hl.monitor({
    output     = "DP-4",
    mode       = "3840x2160@60",
    scale      = 2,
    position   = "1560x-40",
})

hl.env("HYPR_4K", "1")

-- Touchpad device config
hl.device({
    name          = "bltp7853:00-347d:7853-touchpad",
    sensitivity   = 0.1,
    accel_profile = "adaptive",
    scroll_factor = 0.5,
    tap_to_click  = true,
    drag_lock     = 1,
    tap_and_drag  = false,
    drag_3fg      = 1,
})

-- 4-finger horizontal swipe → switch workspace
hl.gesture({
    fingers   = 4,
    direction = "horizontal",
    action    = "workspace",
})

hl.config({
    gestures = {
        workspace_swipe_distance = 300,
        workspace_swipe_invert   = false,
    },
})

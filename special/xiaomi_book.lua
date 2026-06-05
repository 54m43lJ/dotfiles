-- ~/.config/hypr/special/xiaomi_book.lua
-- Xiaomi Book specific settings

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

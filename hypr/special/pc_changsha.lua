-- ~/.config/hypr/special/pc_changsha.lua
-- Desktop PC (Changsha) specific settings

hl.config({
    decoration = {
        rounding         = 4,
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

hl.on("hyprland.start", function()
    hl.exec_cmd("openrgb --start-minimized -p default")
end)

-- Dock display path (the VG273U PRO is wired twice: dGPU direct and HP dock
-- HDMI on the APU's USB-C DP alt-mode).
--
-- Deliberately nothing to disable here: connector ids come from a kernel-global
-- per-type IDA handed out in creation order ("DP-4" = 4th DP connector
-- registered by any driver this boot), so `output = "DP-4", disabled` style
-- rules are exactly what silently rots — DP-5/DP-3 became DP-4/DP-2 between
-- kernel 7.2.3 and 7.2.6 and the old rule stopped matching.
--
-- The block lives in userspace instead:
--   * drm-ignore-dock.service (matched by GPU PCI id) force-offs every
--     connector of the APU — and re-enables them when no dGPU display is
--     present, so the iGPU still works as a rescue console;
--   * the same service pins the panel input back to dGPU DisplayPort-1
--     with DDC/CI, in case its auto input-select latched onto the dock HDMI.

-- VG273U PRO: the 60 Hz "preferred" mode flickers under Hyprland 0.57.
-- highrr (3840x2160@160) + VRR is stable.
--
-- The panel is wired twice (dGPU DP and dock HDMI) and both links report
-- the same EDID description. A desc: rule cannot tell them apart, and a
-- bare DP-2 rule can outlive a different monitor on that port.
--
-- monitor_control supports three modes, in this priority:
--   dual (connector + description) > connector-only > description-only
-- Use only connector to target a port regardless of panel; use only
-- description to target a panel regardless of port.  These two entries use
-- the dual mode because the same panel appears on two links.
--
-- Description values are the "description" field from
-- `hyprctl monitors -j` (Hyprland's short description).  scale is omitted
-- on purpose: monitor_control infers it from the target mode / available
-- modes (4K -> 2x, <=1080p -> 1x).  Add an explicit scale only when the
-- automatic result is wrong.
local monitor_control = require("monitor_control")

monitor_control.define({
    {
        connector   = "DP-2",
        description = "HKC OVERSEAS LIMITED VG273U PRO 0000000000001",
        mode        = "highrr",
        position    = "auto",
        reserved    = { top = -5 },
        vrr         = 1,
    },
    {
        -- Rescue path: when the dGPU is absent/off, the panel comes up on
        -- the dock's HDMI link. Use 4K60 there (the dock HDMI link does not
        -- carry the DP link's 4K160 mode).
        connector   = "HDMI-A-1",
        description = "HKC OVERSEAS LIMITED VG273U PRO 0000000000001",
        mode        = "3840x2160@60",
        position    = "auto",
        reserved    = { top = -5 },
        vrr         = 1,
    },
})

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
-- highrr (3840x2160@160) + VRR is stable. hl.monitor() is additive, and
-- hyprland.lua's layout-only pass uses this same "desc:..." rule key
-- (position/scale/reserved, no mode/VRR), so these fields survive startup
-- and monitor hotplug.
hl.monitor({
    output   = "desc:HKC OVERSEAS LIMITED VG273U PRO 0000000000001",
    mode     = "highrr",
    position = "auto",
    scale    = 2,
    reserved = { top = -5 },
    vrr      = 1,
})

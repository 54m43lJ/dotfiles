-- VG273U PRO is wired twice:
--   dGPU direct:  card1-DP-2  (was DP-3 before kernel 7.2.6)
--   HP dock HDMI: card0-DP-4  (was DP-5 before kernel 7.2.6)
-- The dock path must never be driven: it is the same panel on a second link,
-- its link training interferes with cold-start detection on the direct one,
-- and enabling it produces a phantom second monitor.
--
-- Connector names are kernel-assigned and have shifted once already (the
-- stale DP-5-only rules silently stopped matching), so disable both
-- generations. After a kernel upgrade, verify with:
--   ls /sys/class/drm | grep -v disconnected
hl.monitor({ output = "DP-4", disabled = true }) -- current dock name
hl.monitor({ output = "DP-5", disabled = true }) -- pre-7.2.6 dock name

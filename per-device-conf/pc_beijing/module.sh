#!/bin/bash
# Sub-module: pc_beijing device settings

install_module() {
    mkdir -p ~/.config/hypr/special
    cp "$WD/per-device-conf/pc_beijing/hypr.lua" ~/.config/hypr/special/pc_beijing.lua

    # Desktop idle policy: lock + dpms, no auto-suspend (overrides hypr module)
    cp "$WD/per-device-conf/pc_beijing/hypridle.conf" ~/.config/hypr/hypridle.conf

    # --- kernel-level dock-path block ---
    # The VG273U PRO is wired twice: dGPU direct (card1-DP-2) and dock HDMI
    # (card0-DP-4). Force the dock link off at KMS probe so no stage — fbcon,
    # SDDM's kwin_wayland greeter, the Hyprland session — ever sees it, and
    # the direct link's cold-start detection stays clean (historically the
    # dock link-training interfered with it: greeter reads no EDID, fails
    # every modeset, black screen). amdgpu rejects runtime sysfs force writes
    # on `status` (-EINVAL, i915-only extension), so the only lever is the
    # cmdline, applied by the DRM core before any compositor.
    #
    # Names shifted once already (7.2.6: dGPU DP-3 -> DP-2, dock DP-5 ->
    # DP-4), which silently disarmed the old DP-5-only rule, so keep both
    # generations in the cmdline. Verify after a kernel upgrade:
    #   ls /sys/class/drm | grep -v disconnected
    local DOCK_BLOCK=(video=DP-4:d video=DP-5:d)
    local add=() t
    for t in "${DOCK_BLOCK[@]}"; do
        grep -qF -- "$t" /etc/default/grub || add+=("$t")
    done
    if [ ${#add[@]} -gt 0 ]; then
        log "Adding ${add[*]} to kernel cmdline..."
        sudo sed -i -E "s/^(GRUB_CMDLINE_LINUX_DEFAULT=\")(.*)(\")$/\1\2 ${add[*]}\3/" /etc/default/grub
        sudo grub-mkconfig -o /boot/grub/grub.cfg
    fi

    log "Enabled: pc_beijing"
}

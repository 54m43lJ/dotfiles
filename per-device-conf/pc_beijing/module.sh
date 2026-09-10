#!/bin/bash
# Sub-module: pc_beijing device settings

install_module() {
    mkdir -p ~/.config/hypr/special
    cp "$WD/per-device-conf/pc_beijing/hypr.lua" ~/.config/hypr/special/pc_beijing.lua

    # Desktop idle policy: no lock, no auto-suspend (overrides hypr module)
    cp "$WD/per-device-conf/pc_beijing/hypridle.conf" ~/.config/hypr/hypridle.conf

    # --- kernel-level DP-5 block ---
    # The monitor is wired twice: card1-DP-3 (dGPU, direct) and card0-DP-5
    # (iGPU, dock). Force DP-5 off at KMS probe so no stage — fbcon, SDDM's
    # kwin_wayland greeter, the Hyprland session — ever sees the dock path,
    # and DP-3 detection stays clean (historically the dock link-training
    # interfered with cold-start detection). amdgpu rejects runtime sysfs
    # force writes on `status` (-EINVAL, i915-only extension), so the only
    # lever is the cmdline, applied by the DRM core before any compositor.
    if ! grep -q 'video=DP-5:d' /etc/default/grub; then
        log "Adding video=DP-5:d to kernel cmdline..."
        sudo sed -i -E 's/^(GRUB_CMDLINE_LINUX_DEFAULT=")(.*)(")$/\1\2 video=DP-5:d\3/' /etc/default/grub
        sudo grub-mkconfig -o /boot/grub/grub.cfg
    fi

    log "Enabled: pc_beijing"
}

#!/bin/bash
# Sub-module: pc_beijing device settings

install_module() {
    mkdir -p ~/.config/hypr/special
    cp "$WD/per-device-conf/pc_beijing/hypr.lua" ~/.config/hypr/special/pc_beijing.lua

    # Desktop idle policy: lock + dpms, no auto-suspend (overrides hypr module)
    cp "$WD/per-device-conf/pc_beijing/hypridle.conf" ~/.config/hypr/hypridle.conf

    # ============================================================
    # Dock display path: three layers, because connector names are not stable
    # ============================================================
    # The VG273U PRO is wired twice: dGPU direct and dock HDMI (iGPU USB-C DP
    # alt-mode). The dock link must never be driven: it is the same panel on a
    # second link, its link training interferes with cold-start detection on
    # the direct link, and enabling it produces a phantom second monitor.
    #
    # Connector names are a kernel-global per-type IDA handed out in creation
    # order (drm_connector_init), so they shift with probe order, BIOS/DC
    # changes or a different physical port: on this box dGPU DP-3 -> DP-2 and
    # dock DP-5 -> DP-4 between 7.2.3 and 7.2.6, which disarmed the old
    # DP-5-only rules. Hence three layers:
    #
    #   1. video= cmdline: the only lever applied before the kernel's first
    #      KMS probe, so it is what actually keeps the dock link quiet at
    #      cold boot. Name-based, therefore fragile — keep both known names.
    #   2. drm-ignore-dock.service: force-offs every connector of the iGPU by
    #      PCI id (name-, cardN- and port-independent catch-all, runs before
    #      the greeter).
    #   3. hypr.lua monitor rules: cheap last resort if layers 1-2 failed.
    #
    # After a kernel/BIOS upgrade, verify with:
    #   ls /sys/class/drm | grep -v disconnected
    #   cat /sys/class/drm/card*/device/{vendor,device}
    # If the dock ever lights up, layer 1 needs the new name; layers 2-3
    # already cover it.
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

    # amdgpu *does* honour runtime force writes on connector `status`
    # (DRM_FORCE_OFF: the core reports the connector disconnected and skips
    # detect on later probes), but userspace runs after the first probe.
    sudo install -m755 "$WD/per-device-conf/pc_beijing/drm-ignore-dock" /usr/local/bin/
    sudo install -m644 "$WD/per-device-conf/pc_beijing/drm-ignore-dock.service" \
        /etc/systemd/system/drm-ignore-dock.service
    sudo systemctl daemon-reload
    sudo systemctl enable --now drm-ignore-dock.service

    log "Enabled: pc_beijing"
}

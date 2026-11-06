#!/bin/bash
# Sub-module: pc_beijing device settings

install_module() {
    mkdir -p ~/.config/hypr/special
    cp "$WD/per-device-conf/pc_beijing/hypr.lua" ~/.config/hypr/special/pc_beijing.lua

    # Desktop idle policy: lock + dpms, no auto-suspend (overrides hypr module)
    cp "$WD/per-device-conf/pc_beijing/hypridle.conf" ~/.config/hypr/hypridle.conf

    # ============================================================
    # Dock display path: one userspace layer
    # ============================================================
    # The VG273U PRO is wired twice: dGPU direct and dock HDMI (iGPU USB-C DP
    # alt-mode). While the dGPU drives the panel the dock link must not be
    # driven: it is the same panel on a second link, its link training
    # interferes with cold-start detection on the direct link, and enabling it
    # produces a phantom second monitor.
    #
    # Minimal setup: no video= cmdline block and no greeter-side EDID/RA24
    # guards. drm-ignore-dock runs before the greeter and:
    #   1. force-offs every connector of the iGPU by PCI id (name- and
    #      cardN-independent), with the APU re-enabled as a rescue console
    #      when no non-ignored GPU has a connected output;
    #   2. pins the panel input back to dGPU DisplayPort-1 with DDC/CI, since
    #      the panel's auto input-select can otherwise latch onto the dock
    #      HDMI while that link is briefly alive.
    #
    # Connector names are a kernel-global per-type IDA handed out in creation
    # order, so they shift with probe order/BIOS/DC changes; matching by PCI
    # id and by monitor EDID model is deliberate.
    #
    # After a kernel/BIOS upgrade, verify with:
    #   ls /sys/class/drm | grep -v disconnected
    #   cat /sys/class/drm/card*/device/{vendor,device}

    # amdgpu *does* honour runtime force writes on connector `status`
    # (DRM_FORCE_OFF: the core reports the connector disconnected and skips
    # detect on later probes), but userspace runs after the first probe.
    #
    # Fallback safety: the service only disables the ignored GPU while a
    # non-ignored GPU has a connected output. If the dGPU is removed, dead,
    # has no monitor on it, or the direct cable is unplugged, the APU outputs
    # are re-enabled instead — the motherboard HDMI / USB-C works as a rescue
    # console. A keeper that is connected but has no EDID yet is *not* a
    # fallback: the compositor can re-probe it; enabling the dock link during
    # the wake-up is exactly what disturbs the dGPU link.
    # Kill switches:
    #   - cmdline `drm_ignore_dock=0` (editable from the GRUB menu)
    #   - live session: echo detect | sudo tee /sys/class/drm/cardN-XXX/status
    #     or `sudo systemctl disable --now drm-ignore-dock`
    sudo install -m755 "$WD/per-device-conf/pc_beijing/drm-ignore-dock" /usr/local/bin/
    sudo install -m644 "$WD/per-device-conf/pc_beijing/drm-ignore-dock.service" \
        /etc/systemd/system/drm-ignore-dock.service

    sudo systemctl daemon-reload
    sudo systemctl enable --now drm-ignore-dock.service

    log "Enabled: pc_beijing"
}

#!/bin/bash
# OpenRGB + i2c kernel modules (SMBus driver auto-detected per CPU vendor)
# Autostart lives in the per-device hypr flags (openrgb --start-minimized -p default)

install_module() {
    log "Installing OpenRGB..."

    local RGB_PKGS=(openrgb i2c-tools)
    pac_ins "${RGB_PKGS[@]}"

    # SMBus controller driver: AMD = i2c-piix4, Intel = i2c-i801
    local bus_mod=i2c-piix4
    grep -qm1 "GenuineIntel" /proc/cpuinfo && bus_mod=i2c-i801
    log "SMBus module: $bus_mod"

    # Rewrite (not append) so re-runs stay idempotent
    printf "i2c-dev\n%s\n" "$bus_mod" | sudo tee /etc/modules-load.d/i2c.conf >/dev/null
    sudo modprobe i2c-dev
    sudo modprobe "$bus_mod" 2>/dev/null \
        || warn "modprobe $bus_mod failed (no such controller on this hardware?)"

    log "OpenRGB configured."
}

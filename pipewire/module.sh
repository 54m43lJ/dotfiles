#!/bin/bash
# Pipewire audio system

install_module() {
    log "Installing Pipewire..."

    # jack2 (possibly pulled in by an earlier module) and pipewire-jack
    # conflict and cannot coexist; pacman refuses the swap itself. Drop
    # jack2 with dependency checks skipped — pipewire-jack provides jack
    # and takes over right after.
    if pacman -Qq jack2 &>/dev/null; then
        log "Replacing jack2 with pipewire-jack..."
        sudo pacman -Rdd --noconfirm --noprogressbar jack2 >/dev/null || {
            FAILED="$FAILED jack2"
            err "Failed: jack2"
        }
    fi

    local PW=(
        pipewire wireplumber pipewire-audio pipewire-alsa
        pipewire-pulse pipewire-jack pavucontrol
    )
    pac_ins "${PW[@]}"

    sudo mkdir -p /usr/share/pipewire/pipewire.conf.d
    sudo cp "$WD/pipewire/samplerate.conf" /usr/share/pipewire/pipewire.conf.d/

    log "Pipewire configured."
}

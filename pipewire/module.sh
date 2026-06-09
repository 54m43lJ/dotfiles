#!/bin/bash
# Pipewire audio system

install_module() {
    log "Installing Pipewire..."
    local PW=(
        pipewire wireplumber pipewire-audio pipewire-alsa
        pipewire-pulse pipewire-jack pavucontrol
    )
    pac_ins "${PW[@]}"

    sudo mkdir -p /usr/share/pipewire/pipewire.conf.d
    sudo cp "$WD/pipewire/samplerate.conf" /usr/share/pipewire/pipewire.conf.d/

    log "Pipewire configured."
}

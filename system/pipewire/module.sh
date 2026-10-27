#!/bin/bash
# Pipewire audio system

install_module() {
    log "Installing Pipewire..."
    local PW=(
        pipewire wireplumber pipewire-audio pipewire-alsa
        pipewire-pulse pipewire-jack pavucontrol
    )
    pac_ins "${PW[@]}"

    sudo mkdir -p /etc/pipewire/pipewire.conf.d
    sudo cp "$WD/system/pipewire/samplerate.conf" /etc/pipewire/pipewire.conf.d/
    # Remove the old location used by earlier versions of this dotfiles repo.
    sudo rm -f /usr/share/pipewire/pipewire.conf.d/samplerate.conf

    log "Pipewire configured."
}

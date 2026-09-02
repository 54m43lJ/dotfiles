#!/bin/bash
# Clash Verge Rev — AUR package

install_module() {
    if ! confirm "Install Clash Verge Rev?"; then
        return 0
    fi

    log "Installing Clash Verge Rev..."
    yay_ins clash-verge-rev-bin
    log "Clash Verge Rev installed."
}

#!/bin/bash
# nwg-bar exit menu

install_module() {
    log "Installing nwg-bar..."
    yay_ins nwg-bar 2>/dev/null || true

    mkdir -p ~/.config/nwg-bar
    cp -r "$WD/nwg-bar/"* ~/.config/nwg-bar/
    sudo mkdir -p /usr/local/share/nwg-bar/

    log "nwg-bar configured."
}

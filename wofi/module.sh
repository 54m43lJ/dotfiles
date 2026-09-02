#!/bin/bash
# Wofi application launcher

install_module() {
    log "Installing wofi..."
    pac_ins wofi
    mkdir -p ~/.config/wofi
    cp -r "$WD/wofi/"* ~/.config/wofi/
    log "Wofi configured."
}

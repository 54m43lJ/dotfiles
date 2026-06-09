#!/bin/bash
# Foot terminal emulator

install_module() {
    log "Installing foot terminal..."
    pac_ins foot
    mkdir -p ~/.config/foot
    cp -r "$WD/foot/"* ~/.config/foot/
    log "Foot terminal configured."
}

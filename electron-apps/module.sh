#!/bin/bash
# Electron app flags (ozone platform, wayland)

install_module() {
    log "Deploying electron app configs..."
    mkdir -p ~/.config
    cp -r "$WD/electron-apps/"* ~/.config/
    log "Electron app flags deployed."
}

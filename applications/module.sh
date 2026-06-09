#!/bin/bash
# Desktop entry files (.desktop)

install_module() {
    log "Deploying desktop entries..."
    xdg-user-dirs-update
    mkdir -p ~/.local/share/applications
    cp -r "$WD/applications/"* ~/.local/share/applications/
    sed -i "s|\$HOME|$HOME|g" ~/.local/share/applications/cfw.desktop 2>/dev/null || true
    sed -i "s|\$HOME|$HOME|g" ~/.local/share/applications/qqmusic.desktop 2>/dev/null || true
    log "Desktop entries deployed."
}

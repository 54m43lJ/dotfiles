#!/bin/bash
# OpenCode desktop via AUR opencode-desktop-bin; updates ride the AUR helper.

install_module() {
    log "Installing OpenCode (AUR opencode-desktop-bin)..."
    yay_ins opencode-desktop-bin
    log "OpenCode configured."
}

#!/bin/bash
# Remote management: remmina + RDP support

install_module() {
    log "Installing remote management tools..."
    local REMOTE_PKGS=(remmina freerdp)
    pac_ins "${REMOTE_PKGS[@]}"
    log "Remote tools configured."
}

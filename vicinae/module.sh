#!/bin/bash
# Vicinae launcher (AUR vicinae-bin); takes over wofi's launcher and
# power menu duties.

install_module() {
    log "Installing Vicinae (AUR vicinae-bin)..."
    yay_ins vicinae-bin
    mkdir -p ~/.config/vicinae
    cp "$WD/vicinae/power-menu.sh" ~/.config/vicinae/
    chmod +x ~/.config/vicinae/power-menu.sh
    log "Vicinae configured."
}

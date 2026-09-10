#!/bin/bash
# Breeze theme for Qt and GTK

install_module() {
    log "Installing Breeze theme..."

    local THEMES=(qt6ct breeze breeze-gtk)
    pac_ins "${THEMES[@]}"
    gsettings set org.gnome.desktop.interface gtk-theme Breeze

    log "Breeze theme installed."
}

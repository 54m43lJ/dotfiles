#!/bin/bash
# Breeze theme for Qt and GTK
source "$WD/pkgs.sh"

pac_ins "${THEMES[@]}"
gsettings set org.gnome.desktop.interface gtk-theme Breeze

log "Breeze theme installed."

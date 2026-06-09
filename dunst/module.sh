#!/bin/bash
# Dunst notification daemon

install_module() {
    log "Installing dunst..."
    pac_ins dunst
    mkdir -p ~/.config/dunst
    cp -r "$WD/dunst/"* ~/.config/dunst/
    log "Dunst configured."
}

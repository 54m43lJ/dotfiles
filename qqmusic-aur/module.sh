#!/bin/bash
# QQ Music via AUR qqmusic-bin: the official client repackaged; updates ride
# the AUR helper. Alternative to the qqmusic-appimage module — pick one.

install_module() {
    log "Installing QQ Music (AUR qqmusic-bin)..."
    yay_ins qqmusic-bin
    log "QQ Music configured."
}

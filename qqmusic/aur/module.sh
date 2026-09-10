#!/bin/bash
# QQ Music via AUR qqmusic-bin: the official client repackaged; updates ride
# the AUR helper.
# Selected by the qqmusic module (AUR vs AppImage) — or install directly.

install_module() {
    log "Installing QQ Music (AUR qqmusic-bin)..."
    yay_ins qqmusic-bin
    log "QQ Music configured."
}

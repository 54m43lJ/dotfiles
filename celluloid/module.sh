#!/bin/bash
# Celluloid media player: mpv-based GTK4 frontend, default video player

install_module() {
    log "Installing Celluloid..."
    pac_ins celluloid xdg-utils

    # Default handler for common video containers. Audio MIME types are not
    # pinned here; they keep whatever the desktop already resolves to.
    local MIMES=(
        video/mp4
        video/x-matroska
        video/webm
        video/quicktime
        video/x-msvideo
        video/mpeg
        video/ogg
        video/x-flv
        video/3gpp
        video/x-ms-wmv
        video/mp2t
        video/x-m4v
        video/x-ms-asf
    )
    local mime
    for mime in "${MIMES[@]}"; do
        xdg-mime default io.github.celluloid_player.Celluloid.desktop "$mime"
    done

    log "Celluloid installed as the default video player."
}

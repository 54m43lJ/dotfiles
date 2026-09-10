#!/bin/bash
# QQ Music official AppImage installed to /opt/qqmusic.
# Re-running this module re-downloads the AppImage, which is the update path.

install_module() {
    log "Installing QQ Music (official AppImage)..."
    local DEST=/opt/qqmusic/qqmusic.AppImage

    # AppImage runtime needs FUSE2
    pac_ins fuse2

    # No stable download link: the official page embeds signed, versioned
    # URLs (currently e.g. qqmusic-1.1.8.AppImage), so scrape it each run.
    local URL
    URL=$(curl -fsSL 'https://y.qq.com/download/download.html' \
        | grep -oE 'https://[^"'"'"'<> ]+\.AppImage[^"'"'"'<> ]*' | head -1)
    [[ -n "$URL" ]] || { err "Failed to resolve QQ Music AppImage URL."; return 1; }

    sudo mkdir -p /opt/qqmusic
    sudo curl -fL --retry 3 -o "$DEST" "$URL" || { err "QQ Music AppImage download failed."; return 1; }
    sudo chmod +x "$DEST"

    # Desktop entry; Electron app, same Wayland/IME flags as cfw.desktop
    sudo mkdir -p /usr/local/share/applications
    sudo tee /usr/local/share/applications/qqmusic-appimage.desktop >/dev/null <<'EOF'
[Desktop Entry]
Type=Application
Name=QQ Music (AppImage)
Exec=/opt/qqmusic/qqmusic.AppImage --no-sandbox --enable-features=UseOzonePlatform --ozone-platform=wayland --enable-wayland-ime
StartupNotify=false
Terminal=false
MimeType=
Icon=qqmusic
StartupWMClass=qqmusic
Categories=AudioVideo;
EOF

    # Best-effort icon extraction for the desktop entry
    local tmp; tmp=$(mktemp -d)
    if (cd "$tmp" && "$DEST" --appimage-extract 'usr/share/icons/*' >/dev/null 2>&1); then
        local icon
        icon=$(find "$tmp/squashfs-root" -path '*256x256*/qqmusic.png' | head -1)
        if [[ -n "$icon" ]]; then
            sudo mkdir -p /usr/local/share/pixmaps
            sudo cp "$icon" /usr/local/share/pixmaps/qqmusic.png
        fi
    fi
    rm -rf "$tmp"

    log "QQ Music configured. Re-run this module to update."
}

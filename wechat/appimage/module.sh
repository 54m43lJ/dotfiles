#!/bin/bash
# WeChat official AppImage installed to /opt/wechat.
# Selected by the wechat module (AUR vs AppImage) — or install directly.
# Re-running this module re-downloads the AppImage, which is the update path.

install_module() {
    log "Installing WeChat (official AppImage)..."
    local URL="https://dldir1v6.qq.com/weixin/Universal/Linux/WeChatLinux_x86_64.AppImage"
    local DEST=/opt/wechat/WeChatLinux_x86_64.AppImage

    # AppImage runtime needs FUSE2
    pac_ins fuse2

    sudo mkdir -p /opt/wechat
    sudo curl -fL --retry 3 -o "$DEST" "$URL" || { err "WeChat AppImage download failed."; return 1; }
    sudo chmod +x "$DEST"

    # Desktop entry; IME env for fcitx5 (WeChat is Qt-based)
    sudo mkdir -p /usr/local/share/applications
    sudo tee /usr/local/share/applications/wechat-appimage.desktop >/dev/null <<'EOF'
[Desktop Entry]
Name=WeChat (AppImage)
Exec=env QT_IM_MODULE=fcitx QT_IM_MODULES=fcitx XMODIFIERS=@im=fcitx /opt/wechat/WeChatLinux_x86_64.AppImage
Type=Application
Categories=Network;InstantMessaging;
Icon=wechat
StartupWMClass=WeChat
Terminal=false
EOF

    # Best-effort icon extraction for the desktop entry
    local tmp; tmp=$(mktemp -d)
    if (cd "$tmp" && "$DEST" --appimage-extract '*.png' >/dev/null 2>&1); then
        local icon
        icon=$(find "$tmp/squashfs-root" -iname '*wechat*.png' -o -iname '*.DirIcon.png' 2>/dev/null | sort -V | tail -1)
        if [[ -n $icon ]]; then
            sudo cp "$icon" /usr/local/share/pixmaps/wechat.png
        fi
    fi
    rm -rf "$tmp"

    log "WeChat configured. Re-run this module to update."
}

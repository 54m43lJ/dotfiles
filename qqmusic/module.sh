#!/bin/bash
# QQ Music installer: pick AUR (qqmusic-bin) or official AppImage.

install_module() {
    local method
    select_one method "qqmusic/aur" "qqmusic/appimage" \
        || { warn "QQ Music install skipped."; return 0; }
    install_modules "$method"
}

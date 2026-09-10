#!/bin/bash
# WeChat installer: pick AUR (wechat-universal-bwrap) or official AppImage.

install_module() {
    local method
    select_one method "wechat/aur" "wechat/appimage" \
        || { warn "WeChat install skipped."; return 0; }
    install_modules "$method"
}

#!/bin/bash
# WeChat via AUR wechat-universal-bwrap: the official Linux client inside a
# bubblewrap sandbox; the packager maintains IME (fcitx5), clipboard and
# misc workarounds. Updates ride the AUR helper.
# Selected by the wechat module (AUR vs AppImage) — or install directly.

install_module() {
    log "Installing WeChat (AUR wechat-universal-bwrap)..."
    yay_ins wechat-universal-bwrap
    log "WeChat configured."
}

#!/bin/bash
# Fcitx5 input method framework: packages + pinyin default config
# (autostart and env vars live in the hypr module)

install_module() {
    log "Installing fcitx5..."
    pac_ins fcitx5-im fcitx5-chinese-addons fcitx5-breeze

    mkdir -p ~/.config/fcitx5/conf
    cp "$WD/fcitx5/config" ~/.config/fcitx5/config
    cp "$WD/fcitx5/profile" ~/.config/fcitx5/profile
    cp "$WD/fcitx5/conf/classicui.conf" ~/.config/fcitx5/conf/classicui.conf
    log "Fcitx5 configured."
}

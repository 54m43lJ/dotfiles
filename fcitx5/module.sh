#!/bin/bash
# Fcitx5 input method framework: packages + pinyin default config
# (autostart and env vars live in the hypr module)

install_module() {
    log "Installing fcitx5..."
    pac_ins fcitx5-im fcitx5-chinese-addons

    mkdir -p ~/.config/fcitx5/conf
    cp "$WD/fcitx5/config" ~/.config/fcitx5/config
    cp "$WD/fcitx5/profile" ~/.config/fcitx5/profile
    cp "$WD/fcitx5/conf/classicui.conf" ~/.config/fcitx5/conf/classicui.conf
    cp "$WD/fcitx5/conf/chttrans.conf" ~/.config/fcitx5/conf/chttrans.conf

    # Theme: dark/light palettes from palette/README.md. Fcitx5 scans
    # $XDG_DATA_HOME/fcitx5/themes (data dir, not config dir). Both themes
    # ship together; classicui.conf follows the system light/dark mode.
    mkdir -p ~/.local/share/fcitx5/themes
    rm -rf ~/.local/share/fcitx5/themes/palette-light \
           ~/.local/share/fcitx5/themes/palette-dark
    cp -r "$WD/fcitx5/themes/"* ~/.local/share/fcitx5/themes/

    # Pick up the new theme in a running session.
    fcitx5-remote -r 2>/dev/null || true
    log "Fcitx5 configured."
}

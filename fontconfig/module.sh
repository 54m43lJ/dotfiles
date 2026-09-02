#!/bin/bash
# Font configuration: Noto fonts, CJK, emoji, nerd fonts

install_module() {
    log "Installing fonts..."

    local FONTS=(
        noto-fonts-emoji noto-fonts-cjk
        ttf-noto-nerd ttf-roboto ttf-nerd-fonts-symbols
    )
    pac_ins "${FONTS[@]}"

    mkdir -p ~/.config/fontconfig/conf.d
    cp "$WD/fontconfig/fonts.conf" ~/.config/fontconfig/
    fc-cache

    log "Fonts configured."
}

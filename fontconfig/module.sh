#!/bin/bash
# Font configuration: Maple Mono Normal NF CN (unhinted) for monospace,
# Noto fonts as fallback

install_module() {
    log "Installing fonts..."

    # --- archlinuxcn repo: ttf-maplemono-nf-cn lives there ---
    # Appended once (guarded). USTC/TUNA mirrors, consistent with
    # setup_mirrors(). archlinuxcn-keyring imports the repo signing
    # keys per the upstream README.
    if ! grep -q '^\[archlinuxcn\]' /etc/pacman.conf; then
        log "Enabling archlinuxcn repository..."
        sudo tee -a /etc/pacman.conf >/dev/null <<'EOF'

[archlinuxcn]
Server = https://mirrors.ustc.edu.cn/archlinuxcn/$arch
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/$arch
EOF
    fi
    sudo pacman -Sy --noconfirm --noprogressbar >/dev/null
    pac_ins archlinuxcn-keyring

    # Maple Mono Normal NF CN (normal preset, unhinted; latin + nerd icons
    # + CJK in one font) takes over monospace only; the Noto packages stay
    # installed as fallbacks for sans/serif and behind Maple (see fonts.conf).
    local FONTS=(
        ttf-maplemononormal-nf-cn-unhinted
        noto-fonts-emoji noto-fonts-cjk
        ttf-noto-nerd ttf-roboto ttf-nerd-fonts-symbols
    )
    pac_ins "${FONTS[@]}"

    # Superseded package from an earlier iteration (different pkgname, so
    # it would linger alongside the Normal variant otherwise).
    if pacman -Qi ttf-maplemono-nf-cn &>/dev/null; then
        sudo pacman -R --noconfirm --noprogressbar ttf-maplemono-nf-cn
    fi

    mkdir -p ~/.config/fontconfig/conf.d
    cp "$WD/fontconfig/fonts.conf" ~/.config/fontconfig/
    fc-cache

    log "Fonts configured."
}

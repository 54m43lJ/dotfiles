#!/bin/bash
# VSCode (Code-OSS): packages, wayland flags, keyring backend

install_module() {
    log "Installing VSCode..."
    pac_ins code

    local AUR=(
        code-features code-marketplace
    )
    yay_ins "${AUR[@]}" 2>/dev/null || true

    cp "$WD/vscode/code-flags.conf" ~/.config/

    # Store secrets via libsecret (gnome-keyring from the system module)
    local argv=~/.vscode/argv.json
    mkdir -p ~/.vscode
    if [[ ! -f "$argv" ]]; then
        printf '{\n    "password-store": "gnome-libsecret"\n}\n' > "$argv"
    elif ! grep -q '"password-store"' "$argv"; then
        sed -i '/^{/a\    "password-store": "gnome-libsecret",' "$argv"
    fi

    log "VSCode configured."
}

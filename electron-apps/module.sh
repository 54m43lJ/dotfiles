#!/bin/bash
# Electron app flags (ozone platform, wayland) + VSCode OSS keyring backend

install_module() {
    log "Deploying electron app configs..."
    mkdir -p ~/.config
    cp -r "$WD/electron-apps/"*.conf ~/.config/

    # VSCode OSS: store secrets via libsecret (gnome-keyring, see gnome-keyring module)
    local argv=~/.vscode-oss/argv.json
    mkdir -p ~/.vscode-oss
    if [[ ! -f "$argv" ]]; then
        printf '{\n    "password-store": "gnome-libsecret"\n}\n' > "$argv"
    elif ! grep -q '"password-store"' "$argv"; then
        sed -i '/^{/a\    "password-store": "gnome-libsecret",' "$argv"
    fi

    log "Electron app flags deployed."
}

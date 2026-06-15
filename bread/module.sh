#!/bin/bash
# Bread — GTK4 desktop shell (BreadKnife)

install_module() {
    if ! confirm "Install bread (BreadKnife)?"; then
        return 0
    fi

    log "Installing bread..."

    local BREAD_DEPS=(gtk4 gtk4-layer-shell libadwaita)
    pac_ins "${BREAD_DEPS[@]}"
    yay_ins libastal-meta

    log "Fetching latest preview release..."
    local url
    url=$(curl -sS 'https://api.github.com/repos/54m43lJ/BreadKnife/releases/tags/preview' \
        | grep -oP '"browser_download_url":\s*"\K[^"]*x86_64[^"]*\.tar\.gz')

    if [[ -z "$url" ]]; then
        err "Failed to find x86_64 tarball in preview release."
        return 1
    fi

    log "Downloading $url"
    curl -sSL "$url" | sudo tar xzf - -C /usr/local/bin

    log "Bread installed to /usr/local/bin/bread."
}

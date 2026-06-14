#!/bin/bash
# Bread — GTK4 desktop shell (BreadKnife)

install_module() {
    if ! confirm "Install bread (BreadKnife)?"; then
        return 0
    fi

    log "Installing bread..."

    local BREAD_DEPS=(
        rustup gtk4 gtk4-layer-shell libadwaita meson desktop-file-utils gcc
    )
    pac_ins "${BREAD_DEPS[@]}"
    yay_ins libastal-meta

    rustup install stable
    rustup default stable

    mkdir -p ~/Applications
    git clone https://github.com/54m43lJ/BreadKnife.git ~/Applications/BreadKnife
    (cd ~/Applications/BreadKnife && cargo build --release --bin bread)
    sudo cp ~/Applications/BreadKnife/target/release/bread /usr/local/bin/

    log "Bread installed."
}

#!/bin/bash
# Neovim — LazyVim starter clone + custom plugins/config overlay

install_module() {
    log "Installing Neovim (LazyVim starter + custom config)..."
    local NVIM_PKGS=(neovim ripgrep sshfs)
    pac_ins "${NVIM_PKGS[@]}"

    git_clone https://github.com/LazyVim/starter ~/.config/nvim || return 1
    cp -r "$WD/nvim/lua/plugins/"* ~/.config/nvim/lua/plugins/
    cat "$WD/nvim/lua/config/keymaps.lua" >> ~/.config/nvim/lua/config/keymaps.lua
    cat "$WD/nvim/lua/config/options.lua" >> ~/.config/nvim/lua/config/options.lua
    sed -i 's/colorscheme = {[^}]*}/colorscheme = { "alabaster" }/' ~/.config/nvim/lua/config/lazy.lua

    log "Neovim configured."
}

#!/bin/bash
# Developer environment: tools, Neovim

install_module() {
    if ! confirm "Install developer environment?"; then
        return 0
    fi

    log "Installing developer tools..."

    local DEV_PKGS=(ripgrep python make gcc npm remmina freerdp sshfs)
    pac_ins "${DEV_PKGS[@]}"

    # Neovim — LazyVim starter + custom plugins
    git clone https://github.com/LazyVim/starter ~/.config/nvim
    cp -r "$WD/dev/nvim/lua/plugins/"* ~/.config/nvim/lua/plugins/
    cat "$WD/dev/nvim/lua/config/keymaps.lua" >> ~/.config/nvim/lua/config/keymaps.lua
    cat "$WD/dev/nvim/lua/config/options.lua" >> ~/.config/nvim/lua/config/options.lua
    sed -i 's/colorscheme = {[^}]*}/colorscheme = { "alabaster" }/' ~/.config/nvim/lua/config/lazy.lua

    log "Developer environment configured."
}

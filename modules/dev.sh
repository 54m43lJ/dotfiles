#!/bin/bash
# Developer environment: tools, VSCode, Neovim
source "$WD/pkgs.sh"

pac_ins "${DEV[@]}"
yay_ins "${AUR_DEV[@]}"

# VSCode — use gnome-keyring for credential storage
if [[ -f ~/.vscode/argv.json ]]; then
    grep -v '//' ~/.vscode/argv.json | jq '."password-store" = "gnome-keyring"' > /tmp/argv.json
    cp /tmp/argv.json ~/.vscode/argv.json
    rm -f /tmp/argv.json
fi

# Neovim — LazyVim starter + custom plugins
git clone https://github.com/LazyVim/starter ~/.config/nvim
cp -r "$WD/nvim/lua/plugins/"* ~/.config/nvim/lua/plugins/
cat "$WD/nvim/lua/config/keymaps.lua" >> ~/.config/nvim/lua/config/keymaps.lua
cat "$WD/nvim/lua/config/options.lua" >> ~/.config/nvim/lua/config/options.lua
sed -i 's/colorscheme = {[^}]*}/colorscheme = { "alabaster" }/' ~/.config/nvim/lua/config/lazy.lua

log "Developer environment configured."

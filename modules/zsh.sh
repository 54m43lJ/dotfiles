#!/bin/bash
# Zsh + Oh My Zsh setup
source "$WD/pkgs.sh"

pac_ins zsh

# Oh My Zsh
if [[ ! -d ~/.oh-my-zsh ]]; then
    log "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Deploy .zshrc
cp "$WD/zsh/.zshrc" ~/.zshrc

# Set zsh as default shell
if [[ "$SHELL" != *zsh ]]; then
    chsh -s /bin/zsh
    log "Default shell changed to zsh. Re-login for it to take effect."
fi

log "Zsh configured."

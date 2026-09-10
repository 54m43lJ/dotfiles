#!/bin/bash
# Zsh + Oh My Zsh

install_module() {
    log "Installing Zsh..."
    pac_ins zsh

    # Oh My Zsh
    if [[ ! -d ~/.oh-my-zsh ]]; then
        log "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi

    # Deploy .zshrc
    cp "$WD/zsh/.zshrc" ~/.zshrc

    # Set zsh as default shell.
    # Plain `chsh` runs as the user and prompts for their login password
    # mid-install (PAM); do it from the root side instead.
    if ! getent passwd "$USER" | grep -q ':/bin/zsh$'; then
        sudo usermod -s /bin/zsh "$USER"
        log "Default shell changed to zsh. Re-login for it to take effect."
    fi

    log "Zsh configured."
}

#!/bin/bash
# Core system: base packages, yay, AUR packages, system scripts

install_module() {
    log "Installing core system packages..."

    # --- base system ---
    local BASE=(
        sbctl git base-devel unzip neovim
        man-pages man-db texinfo
        socat jq zoxide fzf brightnessctl blueman
        gnome-keyring polkit-kde-agent
        xdg-user-dirs xdg-desktop-portal-gtk
        playerctl
    )
    pac_ins "${BASE[@]}"

    # --- desktop applications ---
    local SOFTWARE=(
        obsidian syncthing thunderbird seahorse
        nemo nemo-fileroller nemo-share meld
        gvfs-smb keepassxc
    )
    pac_ins "${SOFTWARE[@]}"

    # --- yay (AUR helper) ---
    if confirm "Install yay (AUR helper) and AUR packages?"; then
        mkdir -p ~/Applications
        git clone https://aur.archlinux.org/yay.git ~/Applications/yay
        (cd ~/Applications/yay && makepkg -si --noconfirm)

        local AUR=(
            brave-bin nemo-compare
        )
        yay_ins "${AUR[@]}"
    fi

    # --- system scripts ---
    sudo cp "$WD/system/suspend.sh" /usr/local/bin/

    # --- ssh-agent ---
    systemctl --user enable gcr-ssh-agent --now

    # --- nemo default terminal ---
    gsettings set org.cinnamon.desktop.default-applications.terminal exec foot

    log "Core system packages installed."
}

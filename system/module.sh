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

    # --- AUR packages (yay itself is a hard dependency of main.sh) ---
    local AUR=(
        brave-bin nemo-compare
    )
    yay_ins "${AUR[@]}"

    # --- electron app flags (wayland / ime) ---
    # brave reads ~/.config/brave-flags.conf, generic electron apps read
    # ~/.config/electron-flags.conf, obsidian reads
    # ~/.config/obsidian/user-flags.conf (see /usr/bin/obsidian)
    mkdir -p ~/.config/obsidian
    cp "$WD/system/brave-flags.conf" ~/.config/
    cp "$WD/system/electron-flags.conf" ~/.config/
    cp "$WD/system/obsidian/user-flags.conf" ~/.config/obsidian/

    # --- system scripts ---
    sudo cp "$WD/system/suspend.sh" /usr/local/bin/

    # --- ssh-agent ---
    systemctl --user enable gcr-ssh-agent --now

    # --- nemo default terminal ---
    gsettings set org.cinnamon.desktop.default-applications.terminal exec foot
    gsettings set org.cinnamon.desktop.default-applications.terminal exec-arg ''
    # GLib hardcodes a terminal whitelist that doesn't include foot.
    # xdg-terminal-exec is the first fallback — symlink it to foot so
    # Terminal=true .desktop apps (e.g. nvim) can find a terminal.
    sudo ln -sf /usr/bin/foot /usr/local/bin/xdg-terminal-exec

    log "Core system packages installed."
}

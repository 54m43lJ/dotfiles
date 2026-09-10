#!/bin/bash
# Core system: base packages, yay, AUR packages, system scripts

install_module() {
    log "Installing core system packages..."

    # Audio stack first: pipewire-jack must be in place before anything in
    # this module resolves a `jack` dependency (thunderbird -> ffmpeg ->
    # libjack.so), or pacman's default provider choice pulls in jack2, which
    # conflicts with pipewire-jack.
    install_modules pipewire

    # --- base system ---
    local BASE=(
        sbctl git base-devel unzip neovim
        man-pages man-db texinfo
        socat jq zoxide fzf brightnessctl ddcutil blueman
        gnome-keyring
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

    # --- gnome-keyring PAM: unlock the keyring on login ---
    # Inserted at the end of the auth/session stacks (pam_gnome_keyring is
    # order-sensitive only within its own stack). The session line's
    # auto_start brings up gnome-keyring-daemon, so no exec_cmd is needed
    # in Hyprland. Rewritten atomically; guarded so re-runs are a no-op.
    if ! grep -q pam_gnome_keyring /etc/pam.d/login; then
        log "Adding gnome-keyring PAM entries to /etc/pam.d/login..."
        sudo cp -n /etc/pam.d/login /etc/pam.d/login.bak
        awk '
            { lines[NR] = $0
              if ($1 ~ /^-?auth$/)    a = NR
              if ($1 ~ /^-?session$/) s = NR }
            END { for (i = 1; i <= NR; i++) {
                      print lines[i]
                      if (i == a) print "auth       optional     pam_gnome_keyring.so"
                      if (i == s) print "session    optional     pam_gnome_keyring.so auto_start"
                  } }' /etc/pam.d/login | sudo tee /etc/pam.d/login.tmp >/dev/null
        sudo mv /etc/pam.d/login.tmp /etc/pam.d/login
    fi

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

#!/bin/bash
# greetd + regreet greeter inside the cage kiosk compositor.
# Replaces SDDM (the sddm/ module is retired; its minimal theme lives on
# as the reference design for regreet.css).

install_module() {
    log "Installing greetd + regreet..."
    local PKGS=(greetd cage greetd-regreet accountsservice)
    pac_ins "${PKGS[@]}"

    sudo install -m644 "$WD/greetd/config.toml" /etc/greetd/config.toml
    sudo install -m644 "$WD/greetd/regreet.toml" /etc/greetd/regreet.toml
    sudo install -m644 "$WD/greetd/regreet.css" /etc/greetd/regreet.css
    sudo install -m644 "$WD/greetd/background.jpg" /etc/greetd/background.jpg

    # --- gnome-keyring PAM: unlock the keyring on greeter login ---
    # greetd has its own PAM stack (/etc/pam.d/greetd ships with system-
    # local-login includes), so the system module's /etc/pam.d/login edit
    # does not apply here. Same guarded, atomic insertion.
    if ! grep -q pam_gnome_keyring /etc/pam.d/greetd; then
        log "Adding gnome-keyring PAM entries to /etc/pam.d/greetd..."
        sudo cp -n /etc/pam.d/greetd /etc/pam.d/greetd.bak
        awk '
            { lines[NR] = $0
              if ($1 ~ /^-?auth$/)    a = NR
              if ($1 ~ /^-?session$/) s = NR }
            END { for (i = 1; i <= NR; i++) {
                      print lines[i]
                      if (i == a) print "auth       optional     pam_gnome_keyring.so"
                      if (i == s) print "session    optional     pam_gnome_keyring.so auto_start"
                  } }' /etc/pam.d/greetd | sudo tee /etc/pam.d/greetd.tmp >/dev/null
        sudo mv /etc/pam.d/greetd.tmp /etc/pam.d/greetd
    fi

    # bluetooth enablement used to live in the sddm module; keep parity
    sudo systemctl enable --now bluetooth

    # --- display manager handover ---
    sudo systemctl disable sddm 2>/dev/null || true
    sudo systemctl enable greetd

    log "greetd configured."
}

#!/bin/bash
# SDDM display manager + minimal theme.
# The greeter runs on kwin_wayland: the X11 greeter hits a cold-boot EDID
# failure on the DP-3 link (falls back to 1024x768, black screen) which the
# Wayland stack does not have.

install_module() {
    log "Installing SDDM..."
    local SDDM_PKGS=(
        sddm kwin layer-shell-qt
    )
    pac_ins "${SDDM_PKGS[@]}"

    sudo rm -rf /usr/share/sddm/themes/minimal /usr/share/sddm/themes/sugar-dark
    sudo cp -r "$WD/sddm/minimal" /usr/share/sddm/themes/minimal
    sudo mkdir -p /etc/sddm.conf.d/
    sudo cp "$WD/sddm/theme.conf" /etc/sddm.conf.d/
    sudo cp "$WD/sddm/greeter.conf" /etc/sddm.conf.d/
    sudo systemctl enable sddm
    sudo systemctl enable --now bluetooth

    log "SDDM configured."
}

#!/bin/bash
# SDDM display manager + sugar-dark theme

install_module() {
    log "Installing SDDM..."
    local SDDM_PKGS=(
        sddm qt5-graphicaleffects qt5-quickcontrols2 qt5-svg
    )
    pac_ins "${SDDM_PKGS[@]}"

    sudo cp -r "$WD/sddm/sugar-dark" /usr/share/sddm/themes/
    sudo mkdir -p /etc/sddm.conf.d/
    sudo cp "$WD/sddm/theme.conf" /etc/sddm.conf.d/
    sudo systemctl enable sddm
    sudo systemctl enable --now bluetooth

    log "SDDM configured."
}

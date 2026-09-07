#!/bin/bash
# SDDM display manager + minimal theme
# Theme depends only on QtQuick (sddm hard dep), so it survives Qt updates.

install_module() {
    log "Installing SDDM..."
    pac_ins sddm

    sudo rm -rf /usr/share/sddm/themes/minimal /usr/share/sddm/themes/sugar-dark
    sudo cp -r "$WD/sddm/minimal" /usr/share/sddm/themes/minimal
    sudo mkdir -p /etc/sddm.conf.d/
    sudo cp "$WD/sddm/theme.conf" /etc/sddm.conf.d/
    sudo systemctl enable sddm
    sudo systemctl enable --now bluetooth

    log "SDDM configured."
}

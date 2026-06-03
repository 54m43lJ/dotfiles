#!/bin/bash
# HiDPI display scaling
if confirm "Are you using a HiDPI display?"; then
    ln -sr ~/.config/hypr/4k.conf ~/.config/hypr/conf.d/4k.conf
    sudo cp "$WD/sddm/dpi.conf" /etc/sddm.conf.d/
    log "HiDPI config linked."
fi

#!/bin/bash
# Laptop/desktop device-specific Hyprland config
if confirm "Are you on a laptop?"; then
    ln -sr ~/.config/hypr/macbook.conf ~/.config/hypr/conf.d/macbook.conf
    log "Laptop config linked."
else
    ln -sr ~/.config/hypr/pc.conf ~/.config/hypr/conf.d/pc.conf
    log "Desktop config linked."
fi

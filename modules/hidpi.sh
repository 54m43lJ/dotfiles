#!/bin/bash
# HiDPI display scaling
if confirm "Are you using a HiDPI display?"; then
    set_flag hidpi ~/.config/hypr/flags.lua
    sudo cp "$WD/sddm/dpi.conf" /etc/sddm.conf.d/
    log "HiDPI mode enabled."
fi

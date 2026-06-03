#!/bin/bash
# Laptop/desktop device-specific Hyprland config
if confirm "Are you on a laptop?"; then
    set_flag laptop ~/.config/hypr/flags.lua
    log "Laptop mode enabled."
else
    set_flag pc ~/.config/hypr/flags.lua
    log "Desktop mode enabled."
fi

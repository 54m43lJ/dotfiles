#!/bin/bash
# Hyprland compositor: packages and config

install_module() {
    log "Installing Hyprland..."

    # --- packages ---
    local HYPR=(
        hyprland hyprpolkitagent hyprpaper hypridle hyprshot hyprlock
        xdg-desktop-portal-hyprland qt5-wayland qt6-wayland
        hyprshutdown
    )
    pac_ins "${HYPR[@]}"

    local AUR=(
        hyprshot
    )
    yay_ins "${AUR[@]}" 2>/dev/null || true

    # --- config files ---
    # (device configs live in per-device-conf/<device>/, deployed there)
    mkdir -p ~/.config/hypr
    cp -r "$WD/hypr/"*.lua ~/.config/hypr/
    cp -r "$WD/hypr/"*.conf ~/.config/hypr/
    cp -r "$WD/hypr/"*.jpg ~/.config/hypr/
    cp -r "$WD/hypr/scripts" ~/.config/hypr/

    # Reload if Hyprland is running
    hyprctl reload 2>/dev/null || true

    log "Hyprland configured."
}

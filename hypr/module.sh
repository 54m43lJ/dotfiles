#!/bin/bash
# Hyprland compositor: packages, config, device-specific flags

install_module() {
    log "Installing Hyprland..."

    # --- packages ---
    local HYPR=(
        hyprland hyprpolkitagent hyprpaper hypridle hyprshot hyprlock
        xdg-desktop-portal-hyprland qt5-wayland qt6-wayland
        fcitx5-im fcitx5-chinese-addons fcitx5-breeze
        hyprshutdown
    )
    pac_ins "${HYPR[@]}"

    local AUR=(
        hyprshot
    )
    yay_ins "${AUR[@]}" 2>/dev/null || true

    # --- config files ---
    mkdir -p ~/.config/hypr/special
    cp -r "$WD/hypr/"*.lua ~/.config/hypr/
    cp -r "$WD/hypr/"*.conf ~/.config/hypr/
    cp -r "$WD/hypr/"*.jpg ~/.config/hypr/
    cp -r "$WD/hypr/scripts" ~/.config/hypr/
    cp -r "$WD/hypr/special/"* ~/.config/hypr/special/

    # Reload if Hyprland is running
    hyprctl reload 2>/dev/null || true

    log "Hyprland configured."
}

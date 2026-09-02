#!/bin/bash
# Nvidia drivers + Hyprland wrapper

install_module() {
    if ! confirm "Install Nvidia drivers?"; then
        return 0
    fi

    log "Installing Nvidia drivers..."

    local NVIDIA_PKGS=(nvidia libva-nvidia-driver)
    pac_ins "${NVIDIA_PKGS[@]}"

    sudo cp "$WD/nvidia/Hyprland-nvidia" /usr/bin/
    sudo cp "$WD/nvidia/hyprland-nvidia.desktop" /usr/share/wayland-sessions/

    log "Nvidia drivers configured."
}

#!/bin/bash
# Nvidia drivers + Hyprland wrapper
source "$WD/pkgs.sh"

pac_ins "${NVIDIA[@]}"
sudo bash "$WD/hypr/nvidia.sh"

log "Nvidia drivers configured."

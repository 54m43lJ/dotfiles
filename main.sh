#!/bin/bash
export WD="$(cd "$(dirname "$0")" && pwd)"
source "$WD/lib.sh"

# Parse flags
YES=""
for arg in "$@"; do
    case "$arg" in
        --yes|-y) YES=1 ;;
        --help|-h)
            echo "Usage: ./main.sh [--yes|-y]"
            echo "  --yes, -y   Run non-interactively (accept all prompts)"
            exit 0
            ;;
    esac
done

# Idempotency check
if [[ -f ~/.finished ]]; then
    warn "Installation already marked as complete (~/.finished exists)."
    confirm "Continue anyway?" || exit 0
fi

log "Arch Linux dotfiles deployment"
log "=============================="

# --- guards ---
is_root
is_arch

# --- proxy ---
setup_proxy

# --- mirrors ---
setup_mirrors

# --- base packages ---
source "$WD/pkgs.sh"

if confirm "Install all base packages?"; then
    pac_ins "${BASE[@]}"
    pac_ins "${SOFTWARE[@]}"
else
    warn "Base packages skipped."
    exit 1
fi

# --- base configuration ---
source "$WD/deploy.sh"

# --- zsh + oh-my-zsh ---
source "$WD/modules/zsh.sh"

# --- yay + AUR packages ---
if confirm "Install yay (AUR helper) and AUR packages?"; then
    mkdir -p ~/Applications
    git clone https://aur.archlinux.org/yay.git ~/Applications/yay
    (cd ~/Applications/yay && makepkg -si --noconfirm)
    yay_ins "${AUR[@]}"
fi

# --- optional modules ---
confirm "Install Nvidia drivers?" && source "$WD/modules/nvidia.sh"
source "$WD/modules/laptop.sh"
confirm "Configure RGB (OpenRGB)?" && source "$WD/modules/rgb.sh"
confirm "Install Breeze theme?" && source "$WD/modules/breeze.sh"
confirm "Install eww widget framework?" && source "$WD/modules/eww.sh"
confirm "Install developer environment?" && source "$WD/modules/dev.sh"

# --- final report ---
echo
if [[ -n "$FAILED" ]]; then
    for pkg in $FAILED; do err "Failed to install: $pkg"; done
    err "Some packages failed. Check the list above."
    exit 1
fi

touch ~/.finished
log "All done. Reboot or launch Hyprland to start."

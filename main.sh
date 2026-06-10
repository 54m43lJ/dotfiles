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
            echo
            echo "Modules (installed in order):"
            echo "  system hypr fontconfig foot wofi dunst sddm pipewire"
            echo "  applications grub electron-apps nwg-bar zsh eww"
            echo "  nvidia rgb breeze dev per-device-conf clash"
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

# --- modules ---
MODULES=(
    system
    hypr
    fontconfig
    foot
    wofi
    dunst
    sddm
    pipewire
    applications
    grub
    electron-apps
    nwg-bar
    zsh
    eww
    nvidia
    rgb
    breeze
    dev
    per-device-conf
    clash
)

for mod in "${MODULES[@]}"; do
    script="$WD/$mod/module.sh"
    if [[ -f "$script" ]]; then
        echo
        log "[$mod]"
        source "$script"
        install_module
    else
        warn "Module '$mod' not found at $script, skipping."
    fi
done

# --- final report ---
echo
if [[ -n "$FAILED" ]]; then
    for pkg in $FAILED; do err "Failed to install: $pkg"; done
    err "Some packages failed. Check the list above."
    exit 1
fi

touch ~/.finished
log "All done. Reboot or launch Hyprland to start."

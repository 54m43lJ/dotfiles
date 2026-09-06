#!/bin/bash
export WD="$(cd "$(dirname "$0")" && pwd)"
source "$WD/lib.sh"

MODULES=(
    system
    pipewire
    hypr
    fontconfig
    foot
    wofi
    dunst
    sddm
    applications
    grub
    electron-apps
    nwg-bar
    zsh
    bread
    nvidia
    rgb
    breeze
    dev
    per-device-conf
    clash
)
# Modules checked by default in the interactive picker
# DEFAULTS=("${MODULES[@]}")
DEFAULTS=()

# Parse flags
YES=""
DRY_RUN=""
for arg in "$@"; do
    case "$arg" in
        --yes|-y) YES=1 ;;
        --dry-run) DRY_RUN=1 ;;
        --help|-h)
            echo "Usage: ./main.sh [--yes|-y] [--dry-run]"
            echo "  --yes, -y   Run non-interactively (accept all prompts)"
            echo "  --dry-run   Show what would run without making any changes"
            echo
            echo "Modules (installed in order):"
            printf '  %s\n' "${MODULES[@]}"
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

# --- module selection ---
if [[ -n "$YES" ]]; then
    SELECTED=("${DEFAULTS[@]}")
else
    select_modules
fi

# --- proxy ---
setup_proxy

# --- mirrors ---
if [[ -n "$DRY_RUN" ]]; then
    log "Dry run: skipping mirror configuration."
else
    setup_mirrors
fi

# --- modules ---
if [[ -n "$DRY_RUN" ]]; then
    log "Dry run: no modules executed. Would run:"
    printf '  %s\n' "${SELECTED[@]}"
    exit 0
fi

for mod in "${SELECTED[@]}"; do
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

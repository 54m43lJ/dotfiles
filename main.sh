#!/bin/bash
export WD="$(cd "$(dirname "$0")" && pwd)"
source "$WD/lib.sh"

MODULES=(
    bundle-base
    bundle-desktop
    bundle-dev
    system
    pipewire
    hypr
    fcitx5
    fontconfig
    foot
    wofi
    dunst
    greetd
    applications
    grub
    vscode
    nwg-bar
    zsh
    bread
    nvidia
    openrgb
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
VERBOSE=""
for arg in "$@"; do
    case "$arg" in
        --yes|-y) YES=1 ;;
        --dry-run) DRY_RUN=1 ;;
        --verbose|-v) VERBOSE=1 ;;
        --help|-h)
            echo "Usage: ./main.sh [--yes|-y] [--dry-run] [--verbose|-v]"
            echo "  --yes, -y      Run non-interactively (accept all prompts)"
            echo "  --dry-run      Show what would run without making any changes"
            echo "  --verbose, -v  Print all command output (default: quiet)"
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
# select_multi treats entries already in SELECTED as pre-checked; with
# $YES it accepts them as-is.
SELECTED=("${DEFAULTS[@]}")
select_multi SELECTED "${MODULES[@]}" || exit 0

# --- proxy ---
setup_proxy

# --- mirrors ---
if [[ -n "$DRY_RUN" ]]; then
    log "Dry run: skipping mirror configuration."
else
    setup_mirrors
    log "Refreshing package databases..."
    sudo pacman -Sy --noconfirm --noprogressbar >/dev/null \
        || { err "Failed to refresh package databases."; exit 1; }
fi

# --- modules ---
if [[ -n "$DRY_RUN" ]]; then
    log "Dry run: no modules executed. Would run:"
    printf '  %s\n' "${SELECTED[@]}"
    exit 0
fi

# Silence module stdout; log/err write to stderr so they stay visible.
# --verbose keeps all command output on the terminal.
[[ -n $VERBOSE ]] || exec 1>/dev/null

# Hard dependencies for module execution, installed quietly; any failure
# aborts the whole script. git/base-devel are needed to build yay, which
# several modules rely on for AUR installs.
sudo pacman --noconfirm --needed --noprogressbar -Sq git base-devel >/dev/null \
    || { err "Failed to install git/base-devel."; exit 1; }

if ! command -v yay >/dev/null; then
    log "Installing yay (AUR helper)..."
    mkdir -p ~/Applications
    git_clone https://aur.archlinux.org/yay.git ~/Applications/yay || exit 1
    (cd ~/Applications/yay && makepkg -si --noconfirm) \
        || { err "Failed to build yay."; exit 1; }
fi
command -v yay >/dev/null || { err "yay not available."; exit 1; }

install_modules "${SELECTED[@]}"

# --- final report ---
echo >&2
if [[ -n "$FAILED" ]]; then
    for pkg in $FAILED; do err "Failed to install: $pkg"; done
    err "Some packages failed. Check the list above."
    exit 1
fi

touch ~/.finished
log "All done. Reboot or launch Hyprland to start."

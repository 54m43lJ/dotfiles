#!/bin/bash
# Shared utilities for dotfiles deployment

# All script messaging goes to stderr, so module stdout can be silenced
# wholesale (exec 1>/dev/null in main.sh) while errors stay visible.
log()  { echo "==> $*" >&2; }
warn() { echo " !! $*" >&2; }
err()  { echo "ERR: $*" >&2; }

# Confirm with user. Respects $YES for non-interactive mode.
confirm() {
    local prompt="$1"
    [[ -n "$YES" ]] && return 0
    read -p "$prompt (y/N) " -n 1 reply && echo >&2
    [[ "$reply" == [yY] ]]
}

# pacman install helper
pac_ins() {
    for pkg in "$@"; do
        sudo pacman --noconfirm --needed --noprogressbar -Sq "$pkg" || {
            FAILED="$FAILED $pkg"
            err "Failed: $pkg"
        }
    done
}

# yay install helper
yay_ins() {
    for pkg in "$@"; do
        yay -Sq "$pkg" --answerclean None --answerdiff None \
            --noconfirm --noprogressbar --norebuild --noredownload || {
            FAILED="$FAILED $pkg"
            err "Failed: $pkg"
        }
    done
}

# git clone helper: reuses an existing checkout instead of failing on a
# previous (possibly interrupted) clone, so installs can safely re-run.
git_clone() {
    local url="$1" dir="$2"
    if [[ -d "$dir" ]]; then
        warn "$dir already exists, reusing it."
        git -C "$dir" pull --quiet 2>/dev/null || warn "Update failed, using existing checkout: $dir"
    else
        git clone --quiet "$url" "$dir" || { err "Failed to clone $url."; return 1; }
    fi
}

# Read proxy from env or prompt user
setup_proxy() {
    # Normalize both lowercase and uppercase variants
    if [[ -n "$http_proxy" || -n "$https_proxy" || -n "$HTTP_PROXY" || -n "$HTTPS_PROXY" ]]; then
        export http_proxy="${http_proxy:-$HTTP_PROXY}"
        export https_proxy="${https_proxy:-$HTTPS_PROXY}"
        export HTTP_PROXY="$http_proxy"
        export HTTPS_PROXY="$https_proxy"
        log "Using proxy: $http_proxy"
        return 0
    fi
    read -p "Enter proxy (e.g. http://127.0.0.1:7890), or leave empty to skip: " proxy
    if [[ -n "$proxy" ]]; then
        export http_proxy="$proxy"
        export https_proxy="$proxy"
        export HTTP_PROXY="$proxy"
        export HTTPS_PROXY="$proxy"
        log "Proxy set to: $proxy"
    else
        warn "No proxy configured. Some downloads may fail."
    fi
}

# Configure Chinese mirrors for all package ecosystems
setup_mirrors() {
    log "Configuring mirrors..."
    # pacman
    sudo sed -i 's/#Color/Color/' /etc/pacman.conf
    sudo bash -c "echo 'Server = https://mirrors.ustc.edu.cn/archlinux/\$repo/os/\$arch' > /etc/pacman.d/mirrorlist"
    sudo bash -c "echo 'Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/\$repo/os/\$arch' >> /etc/pacman.d/mirrorlist"
    # rustup
    export RUSTUP_DIST_SERVER=https://mirrors.tuna.tsinghua.edu.cn/rustup
    # cargo
    mkdir -p ~/.cargo
    cat > ~/.cargo/config.toml <<'EOF'
[source.crates-io]
replace-with = 'mirror'

[source.mirror]
registry = "sparse+https://mirrors.tuna.tsinghua.edu.cn/crates.io-index/"

[registries.mirror]
index = "sparse+https://mirrors.tuna.tsinghua.edu.cn/crates.io-index/"
EOF
    # go
    export GOPROXY=https://goproxy.cn,direct
    # npm
    npm config set registry https://registry.npmmirror.com 2>/dev/null || true
}

# Modules already reached in this run: the flatten semantics (a module
# executes at most once, include cycles terminate naturally) live here
# rather than in a separate expansion step.
declare -A MODULE_SEEN

# Install a list of modules in order. Shared execution path for main.sh
# and bundles.
install_modules() {
    local mod script
    for mod in "$@"; do
        [[ -n "${MODULE_SEEN[$mod]:-}" ]] && continue
        MODULE_SEEN[$mod]=1
        script="$WD/$mod/module.sh"
        if [[ -f "$script" ]]; then
            log "[$mod]"
            source "$script"
            install_module
        else
            warn "Module '$mod' not found at $script, skipping."
        fi
    done
}

# Guards
is_root() { [[ $(id -u) -eq 0 ]] && err "Do not run as root." && exit 1; }
is_arch() { grep -q 'NAME="Arch Linux"' /etc/os-release || { err "Arch Linux required."; exit 1; }; }

# Interactive selection primitives: the y/N, multi-select and single-select
# prompt paradigms. Rendering goes to stderr so module stdout stays silenced
# (exec 1>/dev/null in main.sh); results are written through a nameref to
# the caller's variable, return codes carry the interactive outcome.

# Shared TUI engine behind select_multi/select_one: renders a cursor list,
# handles up/down (plus space-toggle in multi mode), enter confirms, esc
# cancels. Returns 1 on cancel / unusable selection.
# Usage: _select_tui <multi|one> <result_var> [items...]
_select_tui() {
    local mode="$1" result_var="$2"
    shift 2
    local -a items=("$@")
    local n=${#items[@]}
    (( n > 0 )) || { warn "Nothing to select."; return 1; }

    local -a checked=()
    local -A pre=()
    local i key seq mark cursor=0 cancelled=0
    if [[ "$mode" == multi ]]; then
        local -n pre_ref="$result_var"
        for i in "${!pre_ref[@]}"; do pre["${pre_ref[$i]}"]=1; done
        for i in "${!items[@]}"; do checked[$i]=${pre["${items[$i]}"]:-0}; done
    fi

    trap 'tput cnorm 2>/dev/null' EXIT
    tput civis 2>/dev/null
    if [[ "$mode" == multi ]]; then
        echo "Space: toggle  Up/Down: move  Enter: confirm  Esc: cancel" >&2
    else
        echo "Up/Down: move  Enter: select  Esc: cancel" >&2
    fi
    while true; do
        for i in "${!items[@]}"; do
            mark=""
            if [[ "$mode" == multi ]]; then
                mark="[ ] "
                (( checked[$i] )) && mark="[x] "
            fi
            if (( i == cursor )); then
                printf '> %s%s\e[K\n' "$mark" "${items[$i]}" >&2
            else
                printf '  %s%s\e[K\n' "$mark" "${items[$i]}" >&2
            fi
        done
        IFS= read -rsn1 key
        case "$key" in
            $'\x1b')
                if IFS= read -rsn2 -t 0.01 seq; then
                    case "$seq" in
                        '[A'|'OA') cursor=$(( (cursor - 1 + n) % n )) ;;
                        '[B'|'OB') cursor=$(( (cursor + 1) % n )) ;;
                    esac
                else
                    cancelled=1
                    break
                fi
                ;;
            ' ') [[ "$mode" == multi ]] && checked[$cursor]=$(( 1 - checked[$cursor] )) ;;
            '') break ;;
        esac
        printf '\e[%dA' "$n" >&2
    done

    printf '\e[%dA\e[J' "$((n + 1))" >&2
    tput cnorm 2>/dev/null
    if (( cancelled )); then
        warn "Cancelled."
        return 1
    fi

    local -n out="$result_var"
    if [[ "$mode" == multi ]]; then
        out=()
        for i in "${!items[@]}"; do
            (( checked[$i] )) && out+=("${items[$i]}")
        done
        if (( ${#out[@]} == 0 )); then
            warn "Nothing selected."
            return 1
        fi
        log "Selected:"
        printf '  %s\n' "${out[@]}" >&2
    else
        out="${items[$cursor]}"
    fi
    return 0
}

# Generic multi-select. Entries already present in result_var are
# pre-checked; the confirmed selection (input order) replaces its
# contents. $YES accepts the pre-filled entries as-is.
# Usage: select_multi <result_var> [items...]
select_multi() {
    local result_var="$1"; shift
    if [[ -n "$YES" ]]; then
        local -n out="$result_var"
        if (( ${#out[@]} > 0 )); then
            log "Selected:"
            printf '  %s\n' "${out[@]}" >&2
        fi
        return 0
    fi
    _select_tui multi "$result_var" "$@"
}

# Generic single-select. With --none, a "None" entry is shown first and
# choosing it sets result_var empty; the cursor always starts on the first
# item. $YES picks the first item (empty with --none). Returns 1 on cancel.
# Usage: select_one <result_var> [--none] [items...]
select_one() {
    local result_var="$1" none=""
    shift
    [[ "$1" == "--none" ]] && { none=1; shift; }
    local -n out="$result_var"
    if [[ -n "$YES" ]]; then
        out=""
        [[ -n "$none" || $# -eq 0 ]] || out="$1"
        return 0
    fi
    (( $# > 0 )) || { warn "Nothing to select."; return 1; }
    if [[ -n "$none" ]]; then
        _select_tui one "$result_var" "None" "$@" || return 1
        [[ "$out" == "None" ]] && out=""
        return 0
    fi
    _select_tui one "$result_var" "$@"
}

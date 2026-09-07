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
        sudo pacman --noconfirm --needed --noprogressbar -Sq "$pkg" >/dev/null || {
            FAILED="$FAILED $pkg"
            err "Failed: $pkg"
        }
    done
}

# yay install helper
yay_ins() {
    for pkg in "$@"; do
        yay -Sq "$pkg" --answerclean None --answerdiff None \
            --noconfirm --noprogressbar --norebuild --noredownload >/dev/null || {
            FAILED="$FAILED $pkg"
            err "Failed: $pkg"
        }
    done
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

# Flip a flag in a Lua flags file
set_flag() {
    # set_flag <flag_name> <file>
    sed -i -E "s/(    ${1}.*= *)false/\1true/" "${2}"
}

# Guards
is_root() { [[ $(id -u) -eq 0 ]] && err "Do not run as root." && exit 1; }
is_arch() { grep -q 'NAME="Arch Linux"' /etc/os-release || { err "Arch Linux required."; exit 1; }; }

# Interactive module picker.
# Reads MODULES (available) and DEFAULTS (pre-checked) arrays,
# fills SELECTED with chosen modules, keeping MODULES order.
# Keys: up/down move cursor, space toggles, enter confirms, esc cancels.
select_modules() {
    local -A is_default=()
    local -a checked=()
    local i key seq mark cursor=0 n=${#MODULES[@]}
    for i in "${!DEFAULTS[@]}"; do is_default["${DEFAULTS[$i]}"]=1; done
    for i in "${!MODULES[@]}"; do checked[$i]=${is_default["${MODULES[$i]}"]:-0}; done

    trap 'tput cnorm 2>/dev/null' EXIT
    tput civis 2>/dev/null
    echo "Space: toggle  Up/Down: move  Enter: run  Esc: cancel" >&2
    while true; do
        for i in "${!MODULES[@]}"; do
            mark=" "; (( checked[$i] )) && mark="x"
            if (( i == cursor )); then
                printf '> [%s] %s\e[K\n' "$mark" "${MODULES[$i]}" >&2
            else
                printf '  [%s] %s\e[K\n' "$mark" "${MODULES[$i]}" >&2
            fi
        done
        IFS= read -rsn1 key
        case "$key" in
            $'\x1b')
                if IFS= read -rsn2 -t 0.01 seq; then
                    case "$seq" in
                        '[A'|'OA') (( cursor > 0 )) && (( cursor-- )) ;;
                        '[B'|'OB') (( cursor < n - 1 )) && (( cursor++ )) ;;
                    esac
                else
                    err "Cancelled."
                    exit 0
                fi
                ;;
            ' ') checked[$cursor]=$(( 1 - checked[$cursor] )) ;;
            '') break ;;
        esac
        printf '\e[%dA' "$n" >&2
    done

    SELECTED=()
    for i in "${!MODULES[@]}"; do
        (( checked[$i] )) && SELECTED+=("${MODULES[$i]}")
    done
    printf '\e[%dA\e[J' "$n" >&2
    if (( ${#SELECTED[@]} == 0 )); then
        err "No module selected."
        exit 0
    fi
    log "Selected modules:"
    printf '  %s\n' "${SELECTED[@]}" >&2
}

#!/bin/bash
# Shared utilities for dotfiles deployment

log()  { echo "==> $*"; }
warn() { echo " !! $*"; }
err()  { echo "ERR: $*"; }

# Confirm with user. Respects $YES for non-interactive mode.
confirm() {
    local prompt="$1"
    [[ -n "$YES" ]] && return 0
    read -p "$prompt (y/N) " -n 1 reply && echo
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
replace-with = 'tuna'
[source.tuna]
registry = "https://mirrors.tuna.tsinghua.edu.cn/git/crates.io-index.git"
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

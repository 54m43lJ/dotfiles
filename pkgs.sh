#!/bin/bash
# All package lists — data only, sourced by other scripts

# --- pacman: base system ---
BASE=(
    sbctl
    neovim
    git
    base-devel
    unzip
    pipewire
    wireplumber
    pipewire-audio
    pipewire-alsa
    pipewire-pulse
    pipewire-jack
    pavucontrol
    playerctl
    sddm
    qt5-graphicaleffects
    qt5-quickcontrols2
    qt5-svg
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    qt5-wayland
    qt6-wayland
    socat
    jq
    hyprland
    hyprpolkitagent
    foot
    fish
    noto-fonts-emoji
    noto-fonts-cjk
    ttf-noto-nerd
    ttf-roboto
    ttf-nerd-fonts-symbols
    man-pages
    man-db
    texinfo
    xdg-user-dirs
    polkit-kde-agent
    dunst
    gnome-keyring
    fcitx5-im
    fcitx5-chinese-addons
    fcitx5-breeze
    hyprpaper
    hypridle
    hyprshot
    hyprlock
    zoxide
    fzf
    brightnessctl
)

# --- pacman: desktop applications ---
SOFTWARE=(
    obsidian
    syncthing
    thunderbird
    seahorse
    wofi
    nemo
    nemo-fileroller
    nemo-share
    meld
    gvfs-smb
    keepassxc
)

# --- optional: nvidia drivers ---
NVIDIA=(
    nvidia
    libva-nvidia-driver
)

# --- optional: RGB control ---
OPENRGB=(
    openrgb
    i2c-tools
)

# --- optional: Breeze theme ---
THEMES=(
    qt6ct
    breeze
    breeze-gtk
)

# --- optional: eww build dependencies ---
EWW_DEPS=(
    gtk3
    gtk-layer-shell
    pango
    gdk-pixbuf2
    cairo
    glib2
    gcc-libs
    glibc
    rustup
)

# --- optional: developer tools ---
DEV=(
    ripgrep
    python
    make
    gcc
    npm
    remmina
    freerdp
    sshfs
    code
)

# --- AUR packages ---
AUR=(
    brave-bin
    nwg-bar
    nemo-compare
    hyprshot
)

AUR_DEV=(
    code-features
    code-marketplace
)

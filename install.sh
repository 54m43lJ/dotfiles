#!/bin/bash

read -P "Install basic software?(Y/N)" -n 1 base_ins
if [ base_ins = y -o base_ins = Y ]; then
    hardware=sbctl pipewire wireplumber pipewire-audio pipewire-alsa pipewire-pulse pipewire-jack pavucontrol playerctl
    desktop=sddm qt5-graphicaleffects qt5-quickcontrols2 qt5-svg xdg-desktop-portal-hyprland xdg-desktop-portal-gtk qt5-wayland qt6-wayland socat jq hyprland foot fish noto-fonts-emoji noto-fonts-cjk ttf-noto-nerd ttf-roboto
    utility=man-pages man-db texinfo xdg-user-dirs polkit-kde-agent dunst gnome-keyring seahorse wofi nemo nemo-fileroller nemo-share meld gvfs-smb fcitx5-im fcitx5-chinese-addons fcitx5-breeze hyprpaper zoxide fzf
    software=obsidian syncthing thunderbird firefox
    sudo pacman -Sq $hardware $desktop $utility $software
    sudo pacman -Sq gtk3 gtk-layer-shell pango gdk-pixbuf2 cairo glib2 gcc-libs glibc rustup
    rustup default stable
    git clone https://github.com/elkowar/eww.git
    cd eww
    cargo build --release --no-default-features --features=wayland
    mkdir -p ~/.local/bin
    cp ./target/release/eww ~/.local/bin/
fi

read -P "Are you using Nvidia?(Y/N)" -n 1 nv_ins
if [ nv_ins = y -o nv_ins = Y ]; then
    sudo pacman -Sq nvidia libva-nvidia-driver
fi

read -P "Do you wish to install yay now?(Y/N)" -n 1 yay_ins
if [ yay_ins = y -o yay_ins = Y ]; then
    git clone https://aur.archlinux.com/yay.git
    cd yay
    makepkg -sic
fi

read -P "Install packages from AUR now?(Y/N)" -n 1 aur_ins
if [ aur_ins = y -o aur_ins = Y ]; then
    yay -Sq brave-bin nwg-bar nemo-compare hyprshot
fi

read -P "Install developer environment?(Y/N)" -n 1 dev_ins
if [ aur_ins = y -o aur_ins = Y ]; then
    sudo pacman -Sq ripgrep lazygit python make gcc npm
    yay -Sq vscodium-bin vscodium-bin-marketplace vscodium-bin-features
    # TODO automatically use latest LunarVim version
    LV_BRANCH='release-1.4/neovim-0.9' bash <(curl -s https://raw.githubusercontent.com/LunarVim/LunarVim/release-1.4/neovim-0.9/utils/installer/install.sh)
fi

read -P "Intall Breeze theme?(Y/N)" -n 1 brz_inst
if [ brz_ins = y -o brz_ins = Y ]; then
    sudo pacman -Qs qt6ct breeze breeze-gtk
    gsettings set org.gnome.desktop.interface gtk-theme Breeze
fi

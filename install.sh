#!/bin/env bash

# Preliminary check
if [ $(id -u) -eq 0 ]; then echo "DO NOT RUN THIS SCRIPT AS root. Exiting..."; exit; fi

# Arch packages
base='sbctl
neovim
networkmanager
git
base-devel
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
zoxide
fzf'
software='obsidian
syncthing
thunderbird
seahorse
wofi
nemo
nemo-fileroller
nemo-share
meld
gvfs-smb'
nvidia='nvidia libva-nvidia-driver'
eww='gtk3 gtk-layer-shell pango gdk-pixbuf2 cairo glib2 gcc-libs glibc rustup'
dev='ripgrep python make gcc npm'
themes='qt6ct breeze breeze-gtk'
# AUR packages
aur='brave-bin nwg-bar nemo-compare hyprshot'
aur_dev='vscodium-bin vscodium-bin-marketplace vscodium-bin-features'
# etc

# macro for installation
failed=""
pac_ins() {
    for i in $@; do
	sudo pacman --noconfirm -Sq $i
	if [ $? -eq 1 ]; then
	     failed="${failed} ${i}"
	fi
    done
}

work_dir=$(pwd)
# install script
read -P "Install basic software? (Y/N)" -n 1 base_ins
if [ $base_ins = y -o $base_ins = Y ]; then
    echo "Setting up system software..."
    pac_ins $base
    xdg-users-dirs-update
    pac_ins $software
    echo "Setting up eww..."
    pac_ins $eww
    rustup default stable
    mkdir ~/Applications
    git clone https://github.com/elkowar/eww.git ~/Applications
    cd ~/Applications/eww
    cargo build --release --no-default-features --features=wayland
    mkdir -p ~/.local/bin
    cp ./target/release/eww ~/.local/bin/
    read -P "Enter path to your Clash for Windows install:" -n 1 clash
    tar -C ~/Applications -xf $clash
    echo "Writing personalizations..."
    cd $work_dir
    mkdir -p ~/.local/share
    cp -r ./applications ~/.local/share/
    cp -r fish ~/.config/
    fish ~/.config/fish/init.sh
    echo "Include optional settings by manually linking the customized files"
    echo "e.g. ln -s ~/.config/fish/custom.fish ~/.config/fish/conf.d"
    cp -r foot ~/.config/
    cp -r hypr ~/.config/
    sudo cp -r ./sddm/sugar-dark /usr/share/sddm/themes/
    sudo cp ./sddm/theme.conf /etc/sddm.conf.d/
    read -P "Are you using an HiDPI display? (Y/N)" -n 1 hidpi
    if [ $hidpi = y -o $hidpi = Y ]; then sudo cp ./sddm/dpi.conf /etc/sddm.conf.d/; fi
    cp -r ./fontconfig ~/.config/
    cp -r ./eww ~/.config/
    cp ./eww/eww-launcher ~/.local/bin
    cp ./nwg-bar ~/.config/
    cp -r ./dunst ~/.config/
    cp -r ./wofi ~/.config/
    sudo cp -r ./arch-linux /boot/grub/themes/
    sudo sed -E 's/^(GRUB_TIMEOUT=).*$/\130/g' /etc/default/grub
    sudo sed -E 's/^(GRUB_DEFAULT=).*$/\1saved/g' /etc/default/grub
    sudo sed -E 's/^#(GRUB_THEME=).*$/\1"\/boot\/grub\/themes\/arch-linux\/theme\.txt"/g' /etc/default/grub
    sudo sed -E 's/^#(GRUB_SAVEDEFAULT=true).*$/\1/g' /etc/default/grub
    sudo sed -E 's/^#(GRUB_DISABLE_OS_PROBER=false).*$/\1/g' /etc/default/grub
    sudo grub-mkconfig -o /boot/grub/grub.cfg
fi

read -P "Are you using Nvidia? (Y/N)" -n 1 nv_ins
if [ nv_ins = y -o nv_ins = Y ]; then
    pac_ins $nvidia
    sudo ~/.config/hypr/nvidia.sh
fi

echo "Please configure Clash before this step:"
read -P "Do you wish to install yay? (Y/N)" -n 1 yay_ins
if [ yay_ins = y -o yay_ins = Y ]; then
    git clone https://aur.archlinux.com/yay.git ~/Applications
    cd ~/Applications/yay
    makepkg -si
fi

read -P "Install packages from AUR? (Y/N)" -n 1 aur_ins
if [ aur_ins = y -o aur_ins = Y ]; then
    yay -Sq $aur
fi

read -P "Install developer environment? (Y/N)" -n 1 dev_ins
if [ aur_ins = y -o aur_ins = Y ]; then
    pac_ins $dev
    yay -Sq $aur_dev
    git clone https://github.com/NvChad/starter ~/.config/nvim
fi

read -P "Intall Breeze theme? (Y/N)" -n 1 brz_inst
if [ brz_ins = y -o brz_ins = Y ]; then
    pac_ins $themes
    gsettings set org.gnome.desktop.interface gtk-theme Breeze
fi

# final breakdown
if [ -n "$failed" ]; then
    printf "\n"
    for i in $failed; do echo "Failed to install [${i}]"; done
fi

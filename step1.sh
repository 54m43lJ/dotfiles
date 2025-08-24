#!/bin/env bash
# Step 1
# install everything that does not need clash
# install clash

# Preliminary check
if [ $(id -u) -eq 0 ]; then
  echo "DO NOT RUN THIS SCRIPT AS root. Exiting..."
  exit
fi
work_dir=$(pwd)

mirror='https://mirrors.ustc.edu.cn/archlinux/$repo/os/$arch'
failed=""
if grep 'NAME="Arch Linux"' /etc/os-release; then
  # Arch packages
  base='sbctl
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
  gvfs-smb
  keepassxc'
  nvidia='nvidia libva-nvidia-driver'
  eww='gtk3 gtk-layer-shell pango gdk-pixbuf2 cairo glib2 gcc-libs glibc rustup'
  dev='ripgrep python make gcc npm remmina freerdp sshfs'
  themes='qt6ct breeze breeze-gtk'
  # AUR packages
  aur='brave-bin nwg-bar nemo-compare hyprshot'
  aur_dev='vscodium-bin vscodium-bin-marketplace vscodium-bin-features'
  # etc

  # macro for installation
  pac_ins() {
    for i in $@; do
      sudo pacman --noconfirm --needed --noprogressbar -Sq $i
      if [ $? -eq 1 ]; then
        failed="${failed} ${i}"
      fi
    done
  }

  # install script
  read -p "Install all dependencies? (Y/N)" -n 1 base_ins
  if [ $base_ins = y -o $base_ins = Y ]; then
    echo; echo "Running pacman..."
    # configure pacman
    sudo sed -i 's/#Color/Color/' /etc/pacman.conf
    echo $mirror > /etc/pacman.d/mirrorlist
    # install pkgs
    pac_ins $base
    pac_ins $software
    echo "Writing configurations..."
    xdg-user-dirs-update
    # desktop entries
    cd $work_dir
    mkdir -p ~/.local/share
    cp -r ./applications ~/.local/share/
    sed -i "s|\$HOME|$HOME|g" ~/.local/share/applications/cfw.desktop
    sed -i "s|\$HOME|$HOME|g" ~/.local/share/applications/qqmusic.desktop
    # fish
    cp -r fish ~/.config/
    mkdir ~/.config/fish/conf.d
    fish ~/.config/fish/init.sh
    echo "Include optional settings by manually linking the customized files"
    echo "e.g. ln -s ~/.config/fish/custom.fish ~/.config/fish/conf.d"
    # foot
    cp -r foot ~/.config/
    # hyprland
    cp -r hypr ~/.config/
    mkdir ~/.config/hypr/conf.d
    ln -sr ~/.config/hypr/windowrule.conf ~/.config/hypr/conf.d/windowrule.conf
    # SDDM
    sudo cp -r ./sddm/sugar-dark /usr/share/sddm/themes/
    sudo mkdir /etc/sddm.conf.d/
    sudo cp ./sddm/theme.conf /etc/sddm.conf.d/
    sudo systemctl enable sddm
    # Device-specific options
    read -p "Are you on a laptop? (Y/N)" -n 1 laptop
    if [ $laptop = y -o $laptop = Y ]; then
      ln -sr ~/.config/hypr/macbook.conf ~/.config/hypr/conf.d/macbook.conf
    else
      ln -sr ~/.config/hypr/pc.conf ~/.config/hypr/conf.d/pc.conf
    fi
    read -p "Are you using an HiDPI display? (Y/N)" -n 1 hidpi
    if [ $hidpi = y -o $hidpi = Y ]; then
      ln -sr ~/.config/hypr/4k.conf ~/.config/hypr/conf.d/4k.conf
      sudo cp ./sddm/dpi.conf /etc/sddm.conf.d/
    fi
    # fontconfig
    cp -r ./fontconfig ~/.config/
    mkdir ~/.config/fontconfig/conf.d
    fc-cache
    # nwg-bar
    cp -r ./nwg-bar ~/.config/
    # dunst
    cp -r ./dunst ~/.config/
    # wofi
    cp -r ./wofi ~/.config/
    # pipewire
    sudo mkdir /usr/share/pipewire/pipewire.conf.d
    sudo cp ./pipewire/samplerate.conf /usr/share/pipewire/pipewire.conf.d/
    # nemo
    gsettings set org.cinnamon.desktop.default-applications.terminal exec foot
    # ssh-agent
    systemctl --user enable gcr-ssh-agent --now
    # electron flags
    cp ./electron-apps/user-flags.conf ~/.config/obsidian/
    cp ./electron-apps/codium-flags.conf ~/.config/
    cp ./electron-apps/electron-flags.conf ~/.config/
    cp ./electron-apps/brave-flags.conf ~/.config/
    # grub
    sudo cp -r ./arch-linux /boot/grub/themes/
    sudo sed -i -E 's/^(GRUB_TIMEOUT=).*$/\130/g' /etc/default/grub
    sudo sed -i -E 's/^(GRUB_DEFAULT=).*$/\1saved/g' /etc/default/grub
    sudo sed -i -E 's/^(GRUB_GFXMODE=).*$/\11280x720/g' /etc/default/grub
    sudo sed -i -E 's/^#(GRUB_THEME=).*$/\1"\/boot\/grub\/themes\/arch-linux\/theme\.txt"/g' /etc/default/grub
    sudo sed -i -E 's/^#(GRUB_SAVEDEFAULT=true).*$/\1/g' /etc/default/grub
    sudo sed -i -E 's/^#(GRUB_DISABLE_OS_PROBER=false).*$/\1/g' /etc/default/grub
    sudo grub-mkconfig -o /boot/grub/grub.cfg
    # clash
    read -p "Enter path to your Clash for Windows package (enter nothing to skip):" clash
    if [[ -n $clash ]]; then tar -C ~/Applications -xf $clash; fi
  fi

  echo
  read -p "Are you using Nvidia? (Y/N)" -n 1 nv_ins
  if [ $nv_ins = y -o $nv_ins = Y ]; then
    echo
    pac_ins $nvidia
    sudo ~/.config/hypr/nvidia.sh
  fi

  echo
  read -p "Intall Breeze theme? (Y/N)" -n 1 brz_ins
  if [ $brz_ins = y -o $brz_ins = Y ]; then
    echo
    pac_ins $themes
    gsettings set org.gnome.desktop.interface gtk-theme Breeze
  fi
else
  echo "OS not supported. Aborting..."
  exit 1
fi

# final breakdown
echo
if [ -n "$failed" ]; then
  echo
  for i in $failed; do echo "Failed to install [${i}]"; done
else
  echo "Successfully installed."
fi

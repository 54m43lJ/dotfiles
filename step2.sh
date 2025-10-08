#!/bin/env bash
# Step 2
# install everything that requires VPN connection
# git repos (eww, yay)
# rust, go

# Preliminary check
if [ $(id -u) -eq 0 ]; then
  echo "DO NOT RUN THIS SCRIPT AS root. Exiting..."
  exit
fi
work_dir=$(pwd)

failed=""
  eww='gtk3 gtk-layer-shell pango gdk-pixbuf2 cairo glib2 gcc-libs glibc rustup'
  dev='ripgrep python make gcc npm remmina freerdp sshfs code'
  # AUR packages
  aur='brave-bin nwg-bar nemo-compare hyprshot'
  aur_dev='code-features code-marketplpace'
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
  yay_ins() {
    for i in $@; do
      yay -Sq \
      --answerclean None --answerdiff None \
      --noconfirm --norebuild --noredownload \
      $i
      if [ $? -eq 1 ]; then
        failed="${failed} ${i}"
      fi
    done
  }

  read -p "Install eww? (Y/N)" -n 1 eww_ins
  if [ $eww_ins = y -o $eww_ins = Y ]; then
    echo "Setting up eww..."
    pac_ins $eww
    RUSTUP_DIST_SERVER=https://mirrors.tuna.tsinghua.edu.cn/rustup rustup install stable
    rustup default stable
    mkdir ~/Applications
    git clone https://github.com/elkowar/eww.git ~/Applications/eww
    cd ~/Applications/eww
    cargo build --release --no-default-features --features=wayland
    sudo cp ./target/release/eww /usr/local/bin/
    cd $work_dir
    mkdir -p ~/.local/bin
    cp -r ./eww ~/.config/
    sudo cp ./eww/eww-launcher /usr/local/bin/
    chmod u+x ~/.config/eww/scripts/*
  fi

  echo
  read -p "Install yay and other packages from AUR? (Y/N)" -n 1 yay_ins
  if [ $yay_ins = y -o $yay_ins = Y ]; then
    echo
    git clone https://aur.archlinux.org/yay.git ~/Applications/yay
    cd ~/Applications/yay
    makepkg -si
    yay_ins $aur
  fi

  echo
  read -p "Install developer environment? (Y/N)" -n 1 dev_ins
  if [ $dev_ins = y -o $dev_ins = Y ]; then
    echo
    pac_ins $dev
    yay_ins $aur_dev
    # VSCode
    cd $work_dir
    grep -v '//' ~/.vscode/argv.json | jq '."password-store" = "gnome-keyring"' >argv.json
    cp argv.json ~/.vscode/argv.json
    rm -f argv.json
    # neovim
    #LV_BRANCH='release-1.4/neovim-0.9' bash <(curl -s https://raw.githubusercontent.com/LunarVim/LunarVim/release-1.4/neovim-0.9/utils/installer/install.sh)
    git clone https://github.com/LazyVim/starter ~/.config/nvim
    cd $work_dir
    cp -r ./nvim/lua/plugins/ ~/.config/nvim/lua/
    cat ./nvim/lua/config/keymaps.lua >>~/.config/nvim/lua/config/keymaps.lua
    cat ./nvim/lua/config/options.lua >>~/.config/nvim/lua/config/options.lua
    sed -i 's/colorscheme = {[^}]*}/colorscheme = { "alabaster" }/' ~/.config/nvim/lua/config/lazy.lua
  fi

# final breakdown
echo
if [ -n "$failed" ]; then
  echo
  for i in $failed; do echo "Failed to install [${i}]"; done
else
  echo "Successfully installed."
fi

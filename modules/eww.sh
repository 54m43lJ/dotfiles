#!/bin/bash
# Eww widget framework — build from source + deploy config
source "$WD/pkgs.sh"

pac_ins "${EWW_DEPS[@]}"

rustup install stable
rustup default stable

mkdir -p ~/Applications
git clone https://github.com/elkowar/eww.git ~/Applications/eww
(cd ~/Applications/eww && cargo build --release --no-default-features --features=wayland)
sudo cp ~/Applications/eww/target/release/eww /usr/local/bin/

mkdir -p ~/.local/bin
cp -r "$WD/eww" ~/.config/
sudo ln -sf "$HOME/.config/eww/eww-launcher" /usr/local/bin/eww-launcher
chmod u+x ~/.config/eww/scripts/*

log "Eww installed and configured."

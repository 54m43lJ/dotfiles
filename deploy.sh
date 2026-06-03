#!/bin/bash
# Deploy all base configurations to their target paths

log "Deploying configurations..."

# --- XDG user directories ---
xdg-user-dirs-update

# --- system scripts ---
sudo cp "$WD/suspend.sh" /usr/local/bin/

# --- desktop entries ---
mkdir -p ~/.local/share/applications
cp -r "$WD/applications/"* ~/.local/share/applications/
sed -i "s|\$HOME|$HOME|g" ~/.local/share/applications/cfw.desktop
sed -i "s|\$HOME|$HOME|g" ~/.local/share/applications/qqmusic.desktop

# --- fish shell ---
cp -r "$WD/fish" ~/.config/
mkdir -p ~/.config/fish/conf.d
fish ~/.config/fish/init.sh
log "Include optional fish settings by linking into ~/.config/fish/conf.d/"

# --- foot terminal ---
cp -r "$WD/foot" ~/.config/

# --- hyprland ---
cp -r "$WD/hypr" ~/.config/
mkdir -p ~/.config/hypr/conf.d
ln -sr ~/.config/hypr/windowrule.conf ~/.config/hypr/conf.d/windowrule.conf

# --- SDDM login manager ---
sudo cp -r "$WD/sddm/sugar-dark" /usr/share/sddm/themes/
sudo mkdir -p /etc/sddm.conf.d/
sudo cp "$WD/sddm/theme.conf" /etc/sddm.conf.d/
sudo systemctl enable sddm

# --- fontconfig ---
cp -r "$WD/fontconfig" ~/.config/
mkdir -p ~/.config/fontconfig/conf.d
fc-cache

# --- nwg-bar (exit menu) ---
cp -r "$WD/nwg-bar" ~/.config/
sudo mkdir -p /usr/local/share/nwg-bar/

# --- dunst notifications ---
cp -r "$WD/dunst" ~/.config/

# --- wofi launcher ---
cp -r "$WD/wofi" ~/.config/

# --- pipewire audio ---
sudo mkdir -p /usr/share/pipewire/pipewire.conf.d
sudo cp "$WD/pipewire/samplerate.conf" /usr/share/pipewire/pipewire.conf.d/

# --- nemo file manager ---
gsettings set org.cinnamon.desktop.default-applications.terminal exec foot

# --- ssh-agent ---
systemctl --user enable gcr-ssh-agent --now

# --- electron app flags ---
cp -r "$WD/electron-apps/"* ~/.config/

# --- GRUB theme ---
sudo cp -r "$WD/arch-linux" /boot/grub/themes/
sudo sed -i -E 's/^(GRUB_TIMEOUT=).*$/\130/g' /etc/default/grub
sudo sed -i -E 's/^(GRUB_DEFAULT=).*$/\1saved/g' /etc/default/grub
sudo sed -i -E 's/^(GRUB_GFXMODE=).*$/\11280x720/g' /etc/default/grub
sudo sed -i -E 's/^#(GRUB_THEME=).*$/\1"\/boot\/grub\/themes\/arch-linux\/theme\.txt"/g' /etc/default/grub
sudo sed -i -E 's/^#(GRUB_SAVEDEFAULT=true).*$/\1/g' /etc/default/grub
sudo sed -i -E 's/^#(GRUB_DISABLE_OS_PROBER=false).*$/\1/g' /etc/default/grub
sudo grub-mkconfig -o /boot/grub/grub.cfg

log "Base configuration deployed."

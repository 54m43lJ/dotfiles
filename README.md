# dotfiles
Before everything else run `./install.sh`.

For any additional config, best practice is always creating a symlink to the config file in the include folder:
`ln -s <path_to_file>`, optionally append custom file name as argument. 

Such folder is usually `conf.d/`.
## Desktop Entries
copy `applications` folder to `.local/share/`.
## Neovim
all goes to `~/.config/`, obviously.
## Foot
`~/.config/`
## Fish
`~/.config/`

disable greeting
```sh
fish init.sh
```

Additional config file goes to `conf.d`.

For MacOS run `fish_add_path /opt/homebrew/bin/`.
## Hyprland & Hyprpaper
`~/.config/`

execute `./nvidia.sh` for system with nvidia graphics.

Additional config goes to `conf.d`.

For the browser, it is configured to launch `brave-browser.desktop`, which you can override with your customized version in `~/.local/share/applications/`.
## SDDM
`sugar-dark` goes to `/usr/share/sddm/themes/`.

`theme.conf` goes to `/etc/sddm.conf.d/`. For HiDPI display also copy `dpi.conf`.
## CN Font
copy `fontconfig` to `~/.config/`

```sh
sudo pacman -S ttf-roboto noto-fonts noto-fonts-cjk
sudo pacman -S nerd-fonts # select roboto and/or noto package with ttf-nerd-fonts-symbols
```

Additional config goes to `conf.d/`.

Be mindful of naming conventions, I would call it `52-special.conf` or something.
## EWW
`~/.config/`

Copy `eww-launcher` to `~/.local/bin`.

Install `socat`, `jq`, `nerd-fonts/ttf-noto-nerd` package on Arch Linux.
## nwg-bar
`~/.config/`
## dunst
`~/.config/`
## GRUB
`sudo cp -r arch-linux /boot/grub/themes/`
Edit `/etc/default/grub`
```
...
GRUB_DEFAULT=saved
GRUB_TIMEOUT=30
...
GRUB_THEME="/boot/grub/themes/arch-linux/theme.txt"
...
GRUB_SAVEDEFAULT=true
...
GRUB_DISABLE_OS_PROBER=false
```
Run `sudo grub-mkconfig -o /boot/grub/grub.cfg`
## LazyVim
`~/.config/`
## Wofi
`~/.config/`

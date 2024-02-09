# dotfiles
For any additional config, best practice is always creating a symlink to the config file in the include folder:
`ln -s <path_to_file>`, optionally append custom file name as argument. 

The folder is usually `conf.d`.
## Neovim
all goes to `~/.config/`, obviously
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

Additional config goes to `conf.d`.
## SDDM
`sugar-dark` goes to `/usr/share/sddm/themes/`.

`theme.conf` goes to `/etc/sddm.conf.d/`. For HiDPI display also copy `dpi.conf`.
## CN Font
copy `fontconfig` to `~/.config/`

```sh
sudo pacman -S ttf-roboto noto-fonts noto-fonts-cjk
sudo pacman -S nerd-fonts # select roboto and/or noto package with ttf-nerd-fonts-symbols
```

Additional config goes to `conf.d`.

Be mindful of naming conventions, I would call it `52-special.conf` or something.
## EWW
`~/.config/`

Copy `eww-launcher` to `~/.local/bin`.

Install `socat`, `jq`, `nerd-fonts/ttf-noto-nerd` package on Arch Linux.
## nwg-bar
`~/.config/`

## dunst
`~/.config`

## GRUB
`sudo cp -r arch-linux /boot/grub/themes/`
Edit `/etc/default/grub` to load the theme using `GRUB_THEME="/boot/grub/themes/arch-linux/theme.txt"`

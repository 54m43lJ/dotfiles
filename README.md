# dotfiles
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

create a symlink to additional config file in `conf.d`.

For MacOS run `fish_add_path /opt/homebrew/bin/`.
## Hyprland & Hyprpaper
`~/.config/`
## SDDM
`sugar-dark` goes to `/usr/share/sddm/themes/`.

`sddm.conf` goes to `/etc/sddm.conf.d/`.
## CN Font
copy `fontconfig` to `~/.config/`

```sh
sudo pacman -S ttf-roboto noto-fonts noto-fonts-cjk
sudo pacman -S nerd-fonts # select roboto and/or noto package with ttf-nerd-fonts-symbols
```

Additional tweaks can be included by creating a symlink in `conf.d`.

Be mindful of naming conventions, I would call it `52-special.conf` or something.
## EWW
`~/.config/`

Copy `eww-launcher` to `~/.local/bin`.

Install `socat`, `jq`, `nerd-fonts/ttf-noto-nerd` package on Arch Linux.
## nwg-bar
`~/.config/`

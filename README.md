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

copy device specific config to `conf.d` folder

For MacOS run `fish_add_path /opt/homebrew/bin/`

## Hyprland & Hyprpaper

`~/.config/`

## SDDM

`sugar-dark` goes to `/usr/share/sddm/themes/`
`sddm.conf` goes to `/etc/sddm.conf.d/`

## CN Font

copy `fontconfig` to `~/.config/`

```sh
sudo pacman -S ttf-roboto noto-fonts noto-fonts-cjk
sudo pacman -S nerd-fonts # select roboto and/or noto package
```

Don't forget to change the DPI property on HiDPI displays

## EWW

`~/.config/`

copy `eww-launcher` to `~/.local/bin`

Install `socat`, `jq`, `nerd-fonts/ttf-noto-nerd` package on Arch Linux.

## nwg-bar

`~/.config/`

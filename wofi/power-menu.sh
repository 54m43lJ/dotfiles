#!/bin/bash
# Power menu backed by wofi dmenu mode.
# Nerd Font glyphs are used as button icons.
# Destructive actions (Logout/Reboot/Shutdown) require confirmation.

G_LOGOUT=$'\uf08b'   # nf-fa-sign_out
G_LOCK=$'\uf023'     # nf-fa-lock
G_SUSPEND=$'\uf186'  # nf-fa-moon_o
G_REBOOT=$'\uf021'   # nf-fa-refresh
G_SHUTDOWN=$'\uf011' # nf-fa-power

WOFI_DIR="${WOFI_DIR:-$HOME/.config/wofi}"

choice=$(printf '%s\n' \
    "$G_LOGOUT Logout" \
    "$G_LOCK Lock" \
    "$G_SUSPEND Suspend" \
    "$G_REBOOT Reboot" \
    "$G_SHUTDOWN Shutdown" \
    | wofi --dmenu \
        --style "$WOFI_DIR/power.css" \
        --columns 5 --lines 1 --hide-search --no-actions \
        -Dsingle_click=true \
        --width '32%' \
        --cache-file /dev/null)

confirm() {
    local answer
    answer=$(printf 'Yes\nNo' | wofi --dmenu \
        --style "$WOFI_DIR/confirm.css" \
        --columns 2 --lines 1 --no-actions \
        --prompt "$1" -Duse_search_box=false -Dsingle_click=true \
        --width '18%' \
        --cache-file /dev/null)
    [[ "$answer" == "Yes" ]]
}

case "$choice" in
    *Logout)   confirm "Logout?"   && hyprshutdown ;;
    *Lock)     loginctl lock-session ;;
    *Suspend)  /usr/local/bin/suspend.sh ;;
    *Reboot)   confirm "Reboot?"   && hyprshutdown -p 'systemctl reboot' ;;
    *Shutdown) confirm "Shutdown?" && hyprshutdown -p 'systemctl -i poweroff' ;;
esac

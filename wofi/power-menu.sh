#!/bin/bash
# Power menu backed by wofi dmenu mode.
# Nerd Font glyphs are used as button icons.
# Destructive actions (Logout/Reboot/Shutdown) require confirmation.

G_LOGOUT=$'\uf08b'   # nf-fa-sign_out
G_LOCK=$'\uf023'     # nf-fa-lock
G_SUSPEND=$'\uf186'  # nf-fa-moon_o
G_REBOOT=$'\uf021'   # nf-fa-refresh
G_SHUTDOWN=$'\uf011' # nf-fa-power
G_CANCEL=$'\uf00d'   # nf-fa-times

WOFI_DIR="${WOFI_DIR:-$HOME/.config/wofi}"

choice=$(printf '%s\n' \
    "<big>$G_LOGOUT</big> Logout" \
    "<big>$G_LOCK</big> Lock" \
    "<big>$G_SUSPEND</big> Suspend" \
    "<big>$G_REBOOT</big> Reboot" \
    "<big>$G_SHUTDOWN</big> Shutdown" \
    | wofi --dmenu \
        --style "$WOFI_DIR/power.css" \
        --columns 5 --lines 1 --hide-search --no-actions \
        -m -Dparse_action=true \
        -Dsingle_click=true \
        --width 780 \
        --cache-file /dev/null)

confirm() {
    local answer
    answer=$(printf '%s\n' "<big>$2</big> $1" "<big>$G_CANCEL</big> Cancel" | wofi --dmenu \
        --style "$WOFI_DIR/confirm.css" \
        --columns 2 --lines 1 --hide-search --no-actions \
        -m -Dparse_action=true \
        -Dsingle_click=true \
        --width 370 \
        --cache-file /dev/null)
    [[ "$answer" == *"$1" ]]
}

case "$choice" in
    *Logout)   confirm "Logout"   "$G_LOGOUT"   && hyprshutdown ;;
    *Lock)     loginctl lock-session ;;
    *Suspend)  /usr/local/bin/suspend.sh ;;
    *Reboot)   confirm "Reboot"   "$G_REBOOT"   && hyprshutdown -p 'systemctl reboot' ;;
    *Shutdown) confirm "Shutdown" "$G_SHUTDOWN" && hyprshutdown -p 'systemctl -i poweroff' ;;
esac

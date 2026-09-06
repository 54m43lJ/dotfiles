#!/bin/bash
# Power menu backed by wofi dmenu mode.
# Destructive actions (Logout/Reboot/Shutdown) require confirmation.

confirm() {
    [[ "$(printf 'Yes\nNo' | wofi --dmenu --prompt "$1")" == "Yes" ]]
}

choice=$(printf '%s\n' Logout Lock Suspend Reboot Shutdown \
         | wofi --dmenu --prompt "Power")

case "$choice" in
    Logout)   confirm "Logout?"   && hyprshutdown ;;
    Lock)     loginctl lock-session ;;
    Suspend)  /usr/local/bin/suspend.sh ;;
    Reboot)   confirm "Reboot?"   && hyprshutdown -p 'systemctl reboot' ;;
    Shutdown) confirm "Shutdown?" && hyprshutdown -p 'systemctl -i poweroff' ;;
esac

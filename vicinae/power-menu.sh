#!/bin/bash
# Power menu backed by vicinae dmenu mode.
# Destructive actions (Logout/Reboot/Shutdown) require confirmation.

confirm() {
    local answer
    answer=$(printf '%s\n' Confirm Cancel | vicinae dmenu \
        --navigation-title "Power" --no-footer \
        --placeholder "$1?")
    [[ "$answer" == "Confirm" ]]
}

choice=$(printf '%s\n' Logout Lock Suspend Reboot Shutdown | vicinae dmenu \
    --navigation-title "Power" --no-footer \
    --placeholder "Select action")

# Lock/Suspend don't work when called directly from this script: dispatch
# them through hyprctl so Hyprland executes them instead (same pattern as
# the dpms calls in hypridle.conf).
case "$choice" in
    Logout)   confirm "Logout"   && hyprshutdown ;;
    Lock)     hyprctl dispatch 'hl.dsp.exec_cmd("loginctl lock-session")' ;;
    Suspend)  hyprctl dispatch 'hl.dsp.exec_cmd("/usr/local/bin/suspend.sh")' ;;
    Reboot)   confirm "Reboot"   && hyprshutdown -p 'systemctl reboot' ;;
    Shutdown) confirm "Shutdown" && hyprshutdown -p 'systemctl -i poweroff' ;;
esac

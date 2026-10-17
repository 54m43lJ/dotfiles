#!/bin/bash
# Power menu backed by vicinae dmenu mode.
# Styled after the old nwg-bar module (compact floating panel): narrow
# window, entry order Lock/Logout/Reboot/Shutdown, Suspend appended for
# machines that use it.
# Destructive actions (Logout/Reboot/Shutdown) require confirmation.

DMENU=(vicinae dmenu --navigation-title "Power" --no-footer --width 420)

confirm() {
    local answer
    answer=$(printf '%s\n' Confirm Cancel | vicinae dmenu \
        --navigation-title "Power" --no-footer --width 420 \
        --placeholder "$1?")
    [[ "$answer" == "Confirm" ]]
}

choice=$(printf '%s\n' Lock Logout Reboot Shutdown Suspend | "${DMENU[@]}" \
    --placeholder "Select action")

# Lock/Suspend don't work when called directly from this script: dispatch
# them through hyprctl so Hyprland executes them instead (same pattern as
# the dpms calls in hypridle.conf).
case "$choice" in
    Lock)     hyprctl dispatch 'hl.dsp.exec_cmd("loginctl lock-session")' ;;
    Logout)   confirm "Logout"   && hyprshutdown ;;
    Reboot)   confirm "Reboot"   && hyprshutdown -p 'systemctl reboot' ;;
    Shutdown) confirm "Shutdown" && hyprshutdown -p 'systemctl -i poweroff' ;;
    Suspend)  hyprctl dispatch 'hl.dsp.exec_cmd("/usr/local/bin/suspend.sh")' ;;
esac

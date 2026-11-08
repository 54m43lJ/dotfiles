#!/bin/bash
# Test an SDDM greeter theme without logging out.
#
#   ./sddm/test-theme.sh [theme]      # default: Current= from theme.conf
#
# On a Wayland session the greeter runs inside a nested cage window (wlroots
# Wayland backend), so it never touches the real outputs and you can close
# the window when done. Without Wayland/cage it falls back to the greeter's
# own window.
#
# --test-mode only exercises the UI: there is no sddm daemon socket, so the
# "Socket error: QLocalSocket::connectToServer" message and failed logins
# are expected. Use a real logout/reboot to test authentication.

set -u

THEME_DIR="${SDDM_THEME_DIR:-/usr/share/sddm/themes}"
THEME_CONF="${SDDM_THEME_CONF:-/etc/sddm.conf.d/theme.conf}"
theme="${1:-}"
if [[ -z "$theme" ]]; then
    theme=$(sed -n 's/^Current=//p' "$THEME_CONF" 2>/dev/null | tail -n 1)
fi
theme="${theme:-sugar-dark}"
theme_path="$THEME_DIR/$theme"

if [[ ! -d "$theme_path" ]]; then
    echo "SDDM theme not found: $theme_path" >&2
    echo "Available themes:" >&2
    find "$THEME_DIR" -mindepth 1 -maxdepth 1 -type d -printf '  %f\n' >&2
    exit 1
fi

if command -v sddm-greeter-qt6 >/dev/null 2>&1; then
    greeter=sddm-greeter-qt6
elif command -v sddm-greeter >/dev/null 2>&1; then
    greeter=sddm-greeter
else
    echo "sddm-greeter not found" >&2
    exit 1
fi

echo "Testing $theme with $greeter (close the window to exit)."
if [[ -n ${WAYLAND_DISPLAY:-} ]] && command -v cage >/dev/null 2>&1; then
    # cage prints all wlroots INFO lines on stderr; keep them out of the way
    # unless it actually fails to start.
    cage_log=$(mktemp)
    env WLR_BACKENDS=wayland WLR_WL_OUTPUTS=1 \
        cage -s -- "$greeter" --test-mode --theme "$theme_path" 2>"$cage_log"
    rc=$?
    if ((rc != 0)); then
        cat "$cage_log" >&2
    fi
    rm -f "$cage_log"
    exit "$rc"
fi

exec "$greeter" --test-mode --theme "$theme_path"

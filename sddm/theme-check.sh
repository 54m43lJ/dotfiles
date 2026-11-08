#!/bin/bash
# SDDM theme health check: set Current= to the first theme that actually
# renders. Invoked by theme-fallback.hook after sddm/Qt upgrades, or by hand.
# Each theme is tested with the greeter SDDM would use for it: metadata
# QtVersion selects sddm-greeter-qtN, and an absent key means the Qt5
# greeter. Testing everything with the newest greeter would miss Qt5-only
# breakage in minimal.
# The greeter logs to journald, not stderr, so verdicts are read from
# journalctl for the spawned PID:
#   dead    -> "Fallback to embedded theme" / QML load error
#   healthy -> "Adding view" and none of the above
# A timeout alone never kills a theme (avoids false kills). The software
# Qt Quick backend keeps the offscreen check independent of GPU/GL.

THEME_DIR="${SDDM_THEME_DIR:-/usr/share/sddm/themes}"
THEME_CONF="${SDDM_THEME_CONF:-/etc/sddm.conf.d/theme.conf}"
FALLBACK=minimal
PRIORITY=(sugar-dark)
DEAD_RE="Fallback to embedded theme|Theme failed to load|\.qml:[0-9]+:.*(rror|Expected|ot found|ailed)"
OK_RE="Adding view"
WAIT=15

[[ -d "$THEME_DIR" && -f "$THEME_CONF" ]] || exit 0
command -v sddm-greeter >/dev/null 2>&1 \
    || command -v sddm-greeter-qt6 >/dev/null 2>&1 || exit 0
journalctl -q --no-pager _PID=1 >/dev/null 2>&1 \
    || { echo "theme-check: journalctl unavailable, skipped" >&2; exit 0; }
current=$(sed -n 's/^Current=//p' "$THEME_CONF")

# Match the daemon's choice: a theme without QtVersion uses SDDM's default
# greeter (Qt5 in SDDM 0.21); QtVersion=6 selects sddm-greeter-qt6, and so
# on. Testing every theme with the newest greeter would miss Qt5-only
# breakage in minimal.
greeter_for() {
    local qt
    qt=$(sed -n 's/^QtVersion=//p' "$THEME_DIR/$1/metadata.desktop" 2>/dev/null | tail -n 1)
    qt=${qt:-5}
    if [[ "$qt" == 5 ]]; then
        command -v sddm-greeter
    else
        command -v "sddm-greeter-qt$qt"
    fi
}

theme_ok() {
    local greeter pid verdict="" i log exited=0
    greeter=$(greeter_for "$1") || return 1
    # Run the greeter directly (no timeout(1)): the background PID must be
    # the greeter itself so journalctl _PID= can find its entries. The loop
    # below bounds the wait to $WAIT seconds.
    QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software "$greeter" --test-mode \
        --theme "$THEME_DIR/$1" >/dev/null 2>&1 &
    pid=$!
    for ((i = 0; i < WAIT; i++)); do
        sleep 1
        log=$(journalctl -q -o cat --no-pager _PID="$pid" 2>/dev/null)
        if grep -qE "$DEAD_RE" <<<"$log"; then verdict=dead; break; fi
        if grep -q "$OK_RE" <<<"$log"; then verdict=ok; break; fi
        kill -0 "$pid" 2>/dev/null || { exited=1; break; }
    done
    kill "$pid" 2>/dev/null
    wait "$pid" 2>/dev/null
    if [[ -z "$verdict" ]]; then
        ((exited)) && sleep 1
        log=$(journalctl -q -o cat --no-pager _PID="$pid" 2>/dev/null)
        if grep -qE "$DEAD_RE" <<<"$log"; then
            verdict=dead
        elif ((exited)); then
            # Quit before rendering: healthy only if it reached a view.
            grep -q "$OK_RE" <<<"$log" && verdict=ok || verdict=dead
        else
            # Still running after WAIT; do not false-kill a slow start.
            verdict=ok
        fi
    fi
    [[ "$verdict" == ok ]]
}

# Order: PRIORITY (pretty themes) first, guaranteed FALLBACK last. Only
# themes this repo deploys participate — stray upstream themes must not
# end up as Current.
declare -A seen=()
themes=()
for t in "${PRIORITY[@]}" "$current" "$FALLBACK"; do
    [[ -d "$THEME_DIR/$t" && "$t" != "$FALLBACK" && -z "${seen[$t]}" ]] \
        && themes+=("$t") && seen[$t]=1
done
themes+=("$FALLBACK")

for t in "${themes[@]}"; do
    if theme_ok "$t"; then
        if [[ "$t" != "$current" ]]; then
            sed -i "s/^Current=.*/Current=$t/" "$THEME_CONF"
            echo "SDDM theme: Current=$t (was ${current:-unset})"
        else
            echo "SDDM theme: '$t' healthy"
        fi
        exit 0
    fi
done

echo "SDDM theme check: no healthy theme found" >&2
exit 1

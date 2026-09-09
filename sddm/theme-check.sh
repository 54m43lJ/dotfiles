#!/bin/bash
# SDDM theme health check: set Current= to the first theme that actually
# renders. Invoked by theme-fallback.hook after sddm/qt6 upgrades, or by hand.
# The greeter logs to journald, not stderr, so verdicts are read from
# journalctl for the spawned PID:
#   dead    -> "Fallback to embedded theme" / QML load error
#   healthy -> "Adding view" and none of the above
# A timeout alone never kills a theme (avoids false kills).

THEME_DIR="${SDDM_THEME_DIR:-/usr/share/sddm/themes}"
THEME_CONF="${SDDM_THEME_CONF:-/etc/sddm.conf.d/theme.conf}"
GREETER=$(command -v sddm-greeter-qt6 || command -v sddm-greeter)
FALLBACK=minimal
PRIORITY=(sugar-dark)
DEAD_RE="Fallback to embedded theme|Theme failed to load|\.qml:[0-9]+:.*(rror|Expected|ot found|ailed)"
OK_RE="Adding view"
WAIT=15

[[ -x "$GREETER" && -d "$THEME_DIR" && -f "$THEME_CONF" ]] || exit 0
journalctl -q --no-pager _PID=1 >/dev/null 2>&1 \
    || { echo "theme-check: journalctl unavailable, skipped" >&2; exit 0; }
current=$(sed -n 's/^Current=//p' "$THEME_CONF")

theme_ok() {
    local pid verdict="" i log
    # Run the greeter directly (no timeout(1)): the background PID must be
    # the greeter itself so journalctl _PID= can find its entries. The loop
    # below bounds the wait to $WAIT seconds.
    QT_QPA_PLATFORM=offscreen "$GREETER" --test-mode \
        --theme "$THEME_DIR/$1" >/dev/null 2>&1 &
    pid=$!
    for ((i = 0; i < WAIT; i++)); do
        sleep 1
        log=$(journalctl -q -o cat --no-pager _PID="$pid" 2>/dev/null)
        if grep -qE "$DEAD_RE" <<<"$log"; then verdict=dead; break; fi
        if grep -q "$OK_RE" <<<"$log"; then verdict=ok; break; fi
        kill -0 "$pid" 2>/dev/null || break
    done
    kill "$pid" 2>/dev/null
    wait "$pid" 2>/dev/null
    if [[ -z "$verdict" ]]; then
        log=$(journalctl -q -o cat --no-pager _PID="$pid" 2>/dev/null)
        grep -qE "$DEAD_RE" <<<"$log" && verdict=dead || verdict=ok
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

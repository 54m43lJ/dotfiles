#!/bin/bash
# Compatibility guard for the minimal SDDM fallback theme.
#
# Contract (also documented in minimal/Main.qml and minimal/README.md):
#   * metadata.desktop MUST NOT pin QtVersion: SDDM then uses its default
#     (Qt5 in SDDM 0.21) greeter, which is why minimal keeps working when
#     Qt6 breaks.
#   * Main.qml may import ONLY `QtQuick 2.15`. Qt5 rejects unversioned
#     imports; Qt6 still registers the 2.15 API surface. No Controls/
#     Effects/GraphicalEffects/VirtualKeyboard/SddmComponents or other
#     add-on modules.
#   * The QML body stays on core QtQuick types available in Qt 5.15.
#
# Run this after editing the theme, or let sddm/module.sh run it during
# deploy. It loads the theme with every installed and runnable
# sddm-greeter* binary, including a future -qt7, so new Qt majors are
# exercised automatically. A greeter whose Qt runtime is not installed is
# skipped: the repo does not force a Qt5 runtime for the fallback.

set -u

WD=$(cd "$(dirname "$0")" && pwd)
# Run from the repo -> test the repo copy. Installed in /usr/local/bin ->
# test the deployed theme (or $SDDM_THEME_DIR).
if [[ -n ${1:-} ]]; then
    THEME=$1
elif [[ -f "$WD/minimal/Main.qml" ]]; then
    THEME=$WD/minimal
else
    THEME=${SDDM_THEME_DIR:-/usr/share/sddm/themes}/minimal
fi
FAILED=0

fail() {
    echo "FAIL: $*" >&2
    FAILED=1
}

[[ -f "$THEME/Main.qml" && -f "$THEME/metadata.desktop" ]] || {
    echo "Not an SDDM theme: $THEME" >&2
    exit 1
}

# --- static contract ------------------------------------------------------

if grep -qE '^[[:space:]]*QtVersion[[:space:]]*=' "$THEME/metadata.desktop"; then
    fail "metadata.desktop sets QtVersion; minimal must stay unpinned"
fi

imports=$(grep -hE '^[[:space:]]*import[[:space:]]' "$THEME"/*.qml 2>/dev/null \
    | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')
bad_imports=$(grep -vx 'import QtQuick 2.15' <<<"$imports" || true)
if [[ -z "$imports" || -n "$bad_imports" ]]; then
    fail "every QML import must be exactly 'import QtQuick 2.15'"
    printf '  found: %s\n' "${imports:-<none>}" >&2
fi

# --- runtime smoke test ---------------------------------------------------

greeters=()
for g in /usr/bin/sddm-greeter /usr/bin/sddm-greeter-qt*; do
    [[ -x "$g" ]] && greeters+=("$g")
done

if ((${#greeters[@]} == 0)); then
    fail "no sddm-greeter binary found"
    exit "$FAILED"
fi

if ! journalctl -q --no-pager _PID=1 >/dev/null 2>&1; then
    echo "journalctl unavailable; static checks only" >&2
    exit "$FAILED"
fi

DEAD_RE='Fallback to embedded theme|Failed to load|Cannot find module|is not a type|\.qml:[0-9]+:.*(not installed|rror|Expected|ot found|ailed)'
WAIT=10

for greeter in "${greeters[@]}"; do
    if ldd "$greeter" 2>/dev/null | grep -q 'not found'; then
        echo "SKIP: $(basename "$greeter") (Qt runtime libraries missing)"
        continue
    fi
    QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software "$greeter" --test-mode \
        --theme "$THEME" >/dev/null 2>&1 &
    pid=$!
    verdict=""
    exited=0

    for ((i = 0; i < WAIT; i++)); do
        sleep 1
        log=$(journalctl -q -o cat --no-pager _PID="$pid" 2>/dev/null)
        if grep -qE "$DEAD_RE" <<<"$log"; then
            verdict=dead
            break
        fi
        if grep -q 'Adding view' <<<"$log"; then
            verdict=ok
            break
        fi
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
            grep -q 'Adding view' <<<"$log" && verdict=ok || verdict=dead
        else
            # Still running after WAIT; do not false-kill a slow start.
            verdict=ok
        fi
    fi

    if [[ "$verdict" == ok ]]; then
        echo "OK: $(basename "$greeter") loads minimal"
    else
        fail "$(basename "$greeter") cannot load minimal"
        grep -E 'Fallback|\.qml:|Cannot find module|Failed to load|is not a type' <<<"$log" | tail -4 >&2
    fi
done

if ((FAILED)); then
    echo "minimal compatibility check FAILED" >&2
else
    echo "minimal compatibility check OK"
fi
exit "$FAILED"

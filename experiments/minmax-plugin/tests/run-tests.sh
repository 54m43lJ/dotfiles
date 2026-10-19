#!/usr/bin/env bash
# End-to-end feasibility test for the Hyprland minmax plugin.
# It loads a real plugin into the running Hyprland session, so always unloads
# it in the EXIT trap.

set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
BUILD="$ROOT/build"
RESULTS="$ROOT/results"
LOG=/tmp/hyprminmax-events.log
PLUGIN="$BUILD/hyprminmax.so"
PROBE="$BUILD/minmax-probe"
GEN="$BUILD/generated"

mkdir -p "$BUILD" "$RESULTS" "$GEN"
rm -f "$LOG" "$RESULTS"/probe-*.log "$RESULTS"/plugin-events.log "$RESULTS"/summary.txt
: > "$RESULTS/summary.txt"

PASS=0
FAIL=0
SKIP=0

pass() { echo "PASS  $*" | tee -a "$RESULTS/summary.txt"; PASS=$((PASS + 1)); }
skip() { echo "SKIP  $*" | tee -a "$RESULTS/summary.txt"; SKIP=$((SKIP + 1)); }
fail() { echo "FAIL  $*" | tee -a "$RESULTS/summary.txt" >&2; FAIL=$((FAIL + 1)); }

cleanup() {
    if [[ -n "${PROBE_PID:-}" ]]; then
        kill "$PROBE_PID" 2>/dev/null || true
        wait "$PROBE_PID" 2>/dev/null || true
    fi
    if hyprctl plugin list 2>/dev/null | grep -q hyprminmax; then
        hyprctl plugin unload "$PLUGIN" >/dev/null 2>&1 || true
    fi
    cp "$LOG" "$RESULTS/plugin-events.log" 2>/dev/null || true
}
trap cleanup EXIT

wait_log() {
    local pattern=$1
    for _ in $(seq 1 60); do
        grep -q "$pattern" "$LOG" 2>/dev/null && return 0
        sleep 0.1
    done
    return 1
}

wait_probe_ready() {
    for _ in $(seq 1 60); do
        grep -q '^READY$' "$RESULTS/probe-${1}.log" 2>/dev/null && return 0
        sleep 0.1
    done
    return 1
}

start_probe() {
    local tag=$1
    shift
    "$PROBE" "$@" > "$RESULTS/probe-${tag}.log" 2>&1 &
    PROBE_PID=$!
    wait_probe_ready "$tag" || { fail "probe $tag did not map"; return 1; }
}

stop_probe() {
    if [[ -n "${PROBE_PID:-}" ]]; then
        kill "$PROBE_PID" 2>/dev/null || true
        wait "$PROBE_PID" 2>/dev/null || true
        PROBE_PID=""
    fi
}

client_field() {
    local addr=$1 field=$2
    hyprctl clients -j | jq -r --arg a "$addr" --arg f "$field" '.[] | select(.address == $a) | getpath($f | split("."))' | tail -1
}

client_address() {
    hyprctl clients -j | jq -r '.[] | select(.class == "minmax-probe") | .address' | tail -1
}

move_window() {
    local workspace=$1 addr=$2
    hyprctl dispatch "hl.dsp.window.move({ workspace = \"$workspace\", window = \"address:$addr\", follow = false })" >/dev/null
}

echo "== build plugin ==" | tee -a "$RESULTS/summary.txt"
make -C "$ROOT/plugin" clean all 2>&1 | tee "$RESULTS/build-plugin.log"
pass "plugin build"

echo "== build probe ==" | tee -a "$RESULTS/summary.txt"
wayland-scanner client-header /usr/share/wayland-protocols/stable/xdg-shell/xdg-shell.xml "$GEN/xdg-shell-client-protocol.h"
wayland-scanner private-code /usr/share/wayland-protocols/stable/xdg-shell/xdg-shell.xml "$GEN/xdg-shell-protocol.c"
cc -O2 -Wall -Wextra -I"$GEN" -o "$PROBE" "$ROOT/tests/minmax-probe.c" "$GEN/xdg-shell-protocol.c" \
    $(pkg-config --cflags --libs wayland-client) 2>&1 | tee "$RESULTS/build-probe.log"
pass "probe build"

echo "== load plugin ==" | tee -a "$RESULTS/summary.txt"
hyprctl plugin load "$PLUGIN" 2>&1 | tee "$RESULTS/plugin-load.log"
sleep 0.5
hyprctl plugin list 2>&1 | tee "$RESULTS/plugin-list-loaded.log"
if hyprctl plugin list | grep -q hyprminmax && wait_log 'PLUGIN_INIT'; then
    pass "plugin load + pluginInit"
else
    fail "plugin load/init"
fi

if wait_log 'HOOK onUpdateState install=ok'; then
    pass "CWindow::onUpdateState hook installed"
else
    fail "CWindow::onUpdateState hook"
fi

echo "== event: window.open ==" | tee -a "$RESULTS/summary.txt"
start_probe open --hold 2
sleep 0.3
if wait_log 'EVENT window.open.*class=minmax-probe'; then pass "window.open event"; else fail "window.open event"; fi
stop_probe

echo "== event/request: minimize ==" | tee -a "$RESULTS/summary.txt"
start_probe minimize --minimize --hold 3
sleep 0.3
if wait_log 'MINIMIZE_REQUEST.*class=minmax-probe.*value=1'; then pass "app minimize request intercepted"; else fail "app minimize request"; fi
stop_probe

echo "== event/request: maximize ==" | tee -a "$RESULTS/summary.txt"
start_probe maximize --maximize --hold 3
sleep 0.5
if wait_log 'MAXIMIZE_REQUEST.*class=minmax-probe.*value=1'; then pass "app maximize request intercepted"; else fail "app maximize request"; fi
ADDR=$(client_address)
if [[ -n "$ADDR" ]]; then
    FULLSCREEN_CLIENT=$(client_field "$ADDR" fullscreenClient)
    if [[ "$FULLSCREEN_CLIENT" == "1" ]]; then pass "native maximize state (fullscreenClient=1)"; else fail "native maximize state (fullscreenClient=$FULLSCREEN_CLIENT)"; fi
    hyprctl clients -j | jq --arg a "$ADDR" '.[] | select(.address == $a)' > "$RESULTS/client-maximized.json"
else
    fail "maximize probe address"
fi
stop_probe

echo "== action: special workspace move/restore ==" | tee -a "$RESULTS/summary.txt"
start_probe special --hold 8
sleep 0.3
ADDR=$(client_address)
if [[ -z "$ADDR" ]]; then
    fail "special workspace probe address"
else
    ORIG_WS=$(client_field "$ADDR" workspace.id)
    ORIG_NAME=$(client_field "$ADDR" workspace.name)
    move_window "special:minimized" "$ADDR"
    sleep 0.5
    SPECIAL_NAME=$(client_field "$ADDR" workspace.name)
    if [[ "$SPECIAL_NAME" == "special:minimized" ]]; then pass "move to special:minimized"; else fail "move to special:minimized (workspace=$SPECIAL_NAME)"; fi

    move_window "$ORIG_WS" "$ADDR"
    sleep 0.5
    RESTORED_ID=$(client_field "$ADDR" workspace.id)
    if [[ "$RESTORED_ID" == "$ORIG_WS" ]]; then pass "restore to original workspace ($ORIG_NAME)"; else fail "restore to original workspace (got $RESTORED_ID, want $ORIG_WS)"; fi
fi
stop_probe

echo "== unload plugin ==" | tee -a "$RESULTS/summary.txt"
hyprctl plugin unload "$PLUGIN" 2>&1 | tee -a "$RESULTS/plugin-unload.log"
sleep 0.5
hyprctl plugin list 2>&1 | tee "$RESULTS/plugin-list-unloaded.log"
if wait_log 'PLUGIN_EXIT' && ! hyprctl plugin list | grep -q hyprminmax; then pass "plugin unload + pluginExit"; else fail "plugin unload"; fi

cp "$LOG" "$RESULTS/plugin-events.log" 2>/dev/null || true
echo | tee -a "$RESULTS/summary.txt"
echo "summary: PASS=$PASS FAIL=$FAIL SKIP=$SKIP" | tee -a "$RESULTS/summary.txt"
[[ "$FAIL" -eq 0 ]]

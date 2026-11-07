#!/usr/bin/env bash
# Standalone tests for hypr/monitor_control.lua (no compositor required).

set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
REPO=$(cd "$ROOT/../.." && pwd)

command -v lua5.4 >/dev/null || {
    echo "SKIP: lua5.4 is required" >&2
    exit 0
}

lua5.4 "$ROOT/tests/lua/test_monitor_control.lua" "$REPO"

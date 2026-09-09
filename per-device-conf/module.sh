#!/bin/bash
# Device-specific configurations.
# Each subdirectory is a sub-module exposing install_module(), like any
# regular module; this module only asks which devices to enable and runs
# the chosen ones.

install_module() {
    local mod_dir="$WD/per-device-conf"
    local -a devices=()
    local d
    for d in "$mod_dir"/*/; do
        [[ -f "$d/module.sh" ]] && devices+=("$(basename "$d")")
    done
    if [[ ${#devices[@]} -eq 0 ]]; then
        warn "No device sub-modules found."
        return 0
    fi

    echo >&2
    log "Device-specific configurations"

    local sub
    select_one sub --none "${devices[@]}" || { log "No device config selected."; return 0; }
    [[ -n "$sub" ]] || return 0
    log "[$sub]"
    source "$mod_dir/$sub/module.sh"
    install_module
}

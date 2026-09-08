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
    echo "  0) None (default)" >&2
    local i
    for i in "${!devices[@]}"; do
        echo "  $((i+1))) ${devices[$i]}" >&2
    done

    read -p "Select (space-separated numbers, default: 0): " -a selections

    local sel idx sub
    for sel in "${selections[@]}"; do
        if [[ "$sel" == "0" ]]; then
            log "No device config selected."
            break
        fi
        idx=$((sel - 1))
        sub="${devices[$idx]}"
        if [[ -n "$sub" ]]; then
            log "[$sub]"
            source "$mod_dir/$sub/module.sh"
            install_module
        fi
    done
}

#!/bin/bash
# Device-specific configurations.
# Each subdirectory of this module is a device sub-module; the files inside
# (hypr.lua, xorg.conf, ...) are deployed when the device is selected and
# removed otherwise. Selecting flips the device's flag in flags.lua.

install_module() {
    local mod_dir="$WD/per-device-conf"
    local flags_file=~/.config/hypr/flags.lua
    local hypr_special=~/.config/hypr/special
    local xorg_conf_d=/etc/X11/xorg.conf.d

    if [[ ! -f "$flags_file" ]]; then
        warn "flags.lua not found. Run the hypr module first."
        return 1
    fi

    local -a devices=()
    local d
    for d in "$mod_dir"/*/; do
        [[ -d "$d" ]] && devices+=("$(basename "$d")")
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

    local chosen=()
    for sel in "${selections[@]}"; do
        if [[ "$sel" == "0" ]]; then
            log "No device config selected."
            break
        fi
        local idx=$((sel - 1))
        [[ -n "${devices[$idx]}" ]] && chosen+=("${devices[$idx]}")
    done

    mkdir -p "$hypr_special"
    local c active
    for d in "${devices[@]}"; do
        active=""
        for c in "${chosen[@]}"; do
            [[ "$c" == "$d" ]] && active=1
        done

        # Deploy-only: on a clean install there is nothing to undo, so
        # unchosen devices are simply skipped.
        if [[ -n "$active" ]]; then
            set_flag "$d" "$flags_file"
            [[ -f "$mod_dir/$d/hypr.lua" ]] && cp "$mod_dir/$d/hypr.lua" "$hypr_special/$d.lua"
            log "Enabled: $d"

            if [[ -f "$mod_dir/$d/xorg.conf" ]]; then
                sudo mkdir -p "$xorg_conf_d"
                log "Deploying Xorg device config: $d.conf"
                sudo cp "$mod_dir/$d/xorg.conf" "$xorg_conf_d/$d.conf"
            fi
        fi
    done

    log "Device-specific configurations done."
}

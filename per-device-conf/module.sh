#!/bin/bash
# Device-specific configuration selector (Hyprland flags)
# Re-usable after initial install to change device flags

install_module() {
    local special_dir="$WD/hypr/special"
    local flags_file=~/.config/hypr/flags.lua

    if [[ ! -f "$flags_file" ]] || [[ ! -d "$special_dir" ]]; then
        warn "Hyprland flags or special configs not found. Run hypr module first."
        return 1
    fi

    local specials=($(ls "$special_dir"/*.lua 2>/dev/null | xargs -n1 basename | sed 's/\.lua$//'))

    if [[ ${#specials[@]} -eq 0 ]]; then
        warn "No device-specific configs found."
        return 0
    fi

    echo
    log "Device-specific configurations"
    echo "  0) None (default)"
    for i in "${!specials[@]}"; do
        echo "  $((i+1))) ${specials[$i]}"
    done

    read -p "Select (space-separated numbers, default: 0): " -a selections

    if [[ ${#selections[@]} -eq 0 ]]; then
        log "No device config selected."
        return 0
    fi

    for sel in "${selections[@]}"; do
        if [[ "$sel" == "0" ]]; then
            log "No device config selected."
            return 0
        fi
        local idx=$((sel - 1))
        if [[ -n "${specials[$idx]}" ]]; then
            set_flag "${specials[$idx]}" "$flags_file"
            log "Enabled: ${specials[$idx]}"
        fi
    done
}

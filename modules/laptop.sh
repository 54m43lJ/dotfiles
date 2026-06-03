#!/bin/bash
# Device-specific configuration selector
# Lists configs from special/ and lets user toggle flags in ~/.config/hypr/flags.lua

# Gather available special configs
specials=($(ls "$WD/special/"*.lua 2>/dev/null | xargs -n1 basename | sed 's/\.lua$//'))

if [[ ${#specials[@]} -eq 0 ]]; then
    warn "No device-specific configs found in special/"
    return
fi

echo
log "Device-specific configurations"
echo "  0) None (default)"

for i in "${!specials[@]}"; do
    echo "  $((i+1))) ${specials[$i]}"
done

read -p "Select (space-separated numbers, default: 0): " -a selections

# Default to none if empty
if [[ ${#selections[@]} -eq 0 ]]; then
    log "No device config selected."
    return
fi

for sel in "${selections[@]}"; do
    if [[ "$sel" == "0" ]]; then
        log "No device config selected."
        return
    fi
    idx=$((sel - 1))
    if [[ -n "${specials[$idx]}" ]]; then
        set_flag "${specials[$idx]}" ~/.config/hypr/flags.lua
        log "Enabled: ${specials[$idx]}"
    fi
done

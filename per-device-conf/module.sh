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

    echo >&2
    log "Device-specific configurations"
    echo "  0) None (default)" >&2
    for i in "${!specials[@]}"; do
        echo "  $((i+1))) ${specials[$i]}" >&2
    done

    read -p "Select (space-separated numbers, default: 0): " -a selections

    local chosen=()
    for sel in "${selections[@]}"; do
        if [[ "$sel" == "0" ]]; then
            log "No device config selected."
            break
        fi
        local idx=$((sel - 1))
        if [[ -n "${specials[$idx]}" ]]; then
            set_flag "${specials[$idx]}" "$flags_file"
            log "Enabled: ${specials[$idx]}"
            chosen+=("${specials[$idx]}")
        fi
    done

    # Device-specific Xorg snippets (e.g. ignoring outputs for the sddm
    # greeter). Deployed for chosen devices, removed for the rest.
    local xorg_special="$WD/xorg/special"
    if [[ -d "$xorg_special" ]]; then
        sudo mkdir -p /etc/X11/xorg.conf.d
        local f name active c
        for f in "$xorg_special"/*.conf; do
            [[ -e "$f" ]] || continue
            name=$(basename "$f")
            active=""
            for c in "${chosen[@]}"; do
                [[ "$name" == "$c.conf" ]] && active=1
            done
            if [[ -n "$active" ]]; then
                log "Deploying Xorg device config: $name"
                sudo cp "$f" "/etc/X11/xorg.conf.d/$name"
            elif sudo test -f "/etc/X11/xorg.conf.d/$name"; then
                log "Removing Xorg device config: $name"
                sudo rm "/etc/X11/xorg.conf.d/$name"
            fi
        done
    fi
}

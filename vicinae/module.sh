#!/bin/bash
# Vicinae launcher (AUR vicinae-bin); takes over wofi's launcher and
# power menu duties.

install_module() {
    log "Installing Vicinae (AUR vicinae-bin)..."
    yay_ins vicinae-bin
    mkdir -p ~/.config/vicinae
    cp "$WD/vicinae/power-menu.sh" ~/.config/vicinae/
    chmod +x ~/.config/vicinae/power-menu.sh

    # Theme: authoritative palette light mode (themes/palette-light.toml).
    # Vicinae scans Omnicast::dataDir()/themes = ~/.local/share/vicinae/themes
    # (NOT the config dir), and the settings "name" must match the theme ID,
    # which is the FILE STEM (theme-parser.cpp: data.id = filename stem).
    # Force both appearance slots so vicinae keeps the palette look no matter
    # what the system color scheme says. settings.json may carry // comments
    # (vicinae's GUI rewrites strip them anyway), so strip before jq;
    # idempotent.
    mkdir -p ~/.local/share/vicinae/themes
    cp "$WD/vicinae/themes/"*.toml ~/.local/share/vicinae/themes/
    local cfg=~/.config/vicinae/settings.json
    if [[ -f $cfg ]] && command -v jq >/dev/null; then
        local tmp
        tmp=$(mktemp)
        grep -v '^//' "$cfg" \
            | jq '.theme.dark.name = "palette-light"
                  | .theme.light.name = "palette-light"
                  | .font.normal.family = "Maple Mono Normal NF CN"' \
            > "$tmp" && mv "$tmp" "$cfg"
    fi

    # Apply now if the server is running (theme/settings hot path is not
    # guaranteed across versions); otherwise Hyprland autostart picks it up.
    if pgrep -x vicinae-server >/dev/null; then
        pkill -x vicinae-server 2>/dev/null
        sleep 0.3
    fi
    ( exec vicinae server ) >/dev/null 2>&1 </dev/null &

    log "Vicinae configured."
}

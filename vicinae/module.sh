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
    # (the GUI writer preserves them; glz reads JSONC), so strip before jq;
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
    # FONT NOTES (2026-10-17): use the CN family — it carries the CJK glyphs,
    # so Chinese app names render in Maple directly (the non-CN variant
    # leaves them unrendered). The server MUST also start without
    # QT_QPA_PLATFORMTHEME (hyprland.lua autostart does `env -u`; the
    # session-level qt5ct env was removed — qt5ct was never installed, the
    # env var was stale 2024 boilerplate): the qt5ct platform theme
    # overrides the app font on QML scene init, which silently disabled the
    # configured font after every restart (upstream vicinae #1022).

    # Extension: icon power menu (supersedes power-menu.sh). Vicinae scans
    # dataDir()/extensions/<dir>/, entrypoint = <command-name>.js at the
    # bundle root (extension-manifest.cpp); the extension runtime injects
    # @vicinae/api/react into require, so plain CJS works, no build step.
    # SUPER+Q opens it via
    # `vicinae deeplink vicinae://launch/@john/power-menu/index?toggle=true`.
    mkdir -p ~/.local/share/vicinae/extensions
    cp -r "$WD/vicinae/extension/power-menu" ~/.local/share/vicinae/extensions/

    # Apply now if the server is running (theme/settings hot path is not
    # guaranteed across versions); otherwise Hyprland autostart picks it up.
    # env -u: see FONT CAVEAT above.
    if pgrep -x vicinae-server >/dev/null; then
        pkill -x vicinae-server 2>/dev/null
        sleep 0.3
    fi
    ( exec env -u QT_QPA_PLATFORMTHEME vicinae server ) >/dev/null 2>&1 </dev/null &

    log "Vicinae configured."
}

#!/bin/bash
# AGS (Aylur's GTK Shell) — Astal/GTK4 bar

install_module() {
    if ! confirm "Install ags bar?"; then
        return 0
    fi

    log "Installing ags..."
    yay_ins aylurs-gtk-shell libastal-meta

    log "Deploying ags config..."
    mkdir -p ~/.config/ags

    cp "$WD"/ags/app.tsx ~/.config/ags/
    cp "$WD"/ags/style.scss ~/.config/ags/
    cp -r "$WD"/ags/widgets ~/.config/ags/
    cp -r "$WD"/ags/windows ~/.config/ags/

    ags types -d ~/.config/ags -u

    log "ags configured."
}

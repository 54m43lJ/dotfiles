#!/bin/bash
# SDDM display manager + minimal theme.
# The greeter runs on kwin_wayland: the X11 greeter hits a cold-boot EDID
# failure on the DP-3 link (falls back to 1024x768, black screen) which the
# Wayland stack does not have.

install_module() {
    log "Installing SDDM..."
    local SDDM_PKGS=(
        sddm kwin layer-shell-qt
    )
    pac_ins "${SDDM_PKGS[@]}"

    sudo rm -rf /usr/share/sddm/themes/minimal /usr/share/sddm/themes/sugar-dark
    sudo cp -r "$WD/sddm/minimal" /usr/share/sddm/themes/minimal
    sudo cp -r "$WD/sddm/sugar-dark" /usr/share/sddm/themes/sugar-dark
    sudo mkdir -p /etc/sddm.conf.d/
    sudo cp "$WD/sddm/theme.conf" /etc/sddm.conf.d/
    sudo cp "$WD/sddm/greeter.conf" /etc/sddm.conf.d/
    # Theme auto-fallback: after sddm/qt6 upgrades the hook re-validates the
    # current theme offscreen and steps down/up Current= as themes heal.
    sudo install -m755 "$WD/sddm/theme-check.sh" /usr/local/bin/
    sudo install -m644 "$WD/sddm/theme-fallback.hook" /usr/share/libalpm/hooks/theme-fallback.hook

    # Cold-boot EDID race guard (see drm-wait-edid): the panel drops HPD in
    # deep sleep, so kwin can start while the connector is "connected" but
    # still has no EDID -> zero modes -> black greeter until reboot.
    sudo install -m755 "$WD/sddm/drm-wait-edid" /usr/local/bin/
    sudo mkdir -p /etc/systemd/system/sddm.service.d/
    sudo install -m644 "$WD/sddm/wait-edid.conf" /etc/systemd/system/sddm.service.d/10-wait-edid.conf
    sudo systemctl daemon-reload

    sudo systemctl enable sddm
    sudo systemctl enable --now bluetooth

    log "SDDM configured."
}

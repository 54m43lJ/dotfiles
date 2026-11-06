#!/bin/bash
# SDDM display manager + minimal theme.
# The greeter runs on cage (see greeter.conf): the X11 greeter hits a
# cold-boot EDID failure on the DP-3 link and kwin_wayland has its own RA24
# scanout-format trap on RDNA4. Cage avoids both with the smallest possible
# compositor surface; no extra wait/guard layers are installed here.

install_module() {
    log "Installing SDDM..."
    # qt6-wayland provides the Qt Wayland platform plugin the greeter needs;
    # sddm does not depend on it directly.
    local SDDM_PKGS=(
        sddm cage qt6-wayland
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

    sudo systemctl enable sddm
    sudo systemctl enable --now bluetooth

    log "SDDM configured."
}

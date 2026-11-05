#!/bin/bash
# CoolerControl — cooling device monitoring and fan/pump/RGB control.
# liquidctl and lm_sensors are optional dependencies of coolercontrold;
# without liquidctl the daemon logs a Python Environment Error on every
# startup while liquidctl integration is enabled (the default).

install_module() {
    log "Installing CoolerControl..."

    # CoolerControl lives in [extra] since 5.1.1. The older AUR -bin
    # packages conflict with it and are no longer available upstream.
    local -a old=()
    pacman -Qi coolercontrol-bin &>/dev/null && old+=(coolercontrol-bin)
    pacman -Qi coolercontrold-bin &>/dev/null && old+=(coolercontrold-bin)
    if (( ${#old[@]} > 0 )); then
        log "Replacing AUR ${old[*]} with the official packages..."
        sudo pacman -R --noconfirm --noprogressbar "${old[@]}"
    fi

    # pacman does not pull optdepends, so install these explicitly. liquidctl
    # must be present before the daemon starts to avoid the startup warning.
    pac_ins liquidctl lm_sensors coolercontrol

    # The package ships the unit but does not enable it. Restart rather than
    # --now: when replacing the old -bin package the running process still
    # uses the unlinked binary.
    sudo systemctl enable coolercontrold
    sudo systemctl restart coolercontrold

    log "CoolerControl installed."
}

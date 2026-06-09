#!/bin/bash
# OpenRGB + i2c kernel modules

install_module() {
    if ! confirm "Configure RGB (OpenRGB)?"; then
        return 0
    fi

    log "Installing OpenRGB..."

    local RGB_PKGS=(openrgb i2c-tools)
    pac_ins "${RGB_PKGS[@]}"

    sudo touch /etc/modules-load.d/i2c.conf
    sudo bash -c 'echo "i2c-dev" >> /etc/modules-load.d/i2c.conf'

    if confirm "Are you using an AMD CPU?"; then
        sudo bash -c 'echo "i2c-piix4" >> /etc/modules-load.d/i2c.conf'
    else
        sudo bash -c 'echo "i2c-i801" >> /etc/modules-load.d/i2c.conf'
    fi

    log "RGB control configured."
}

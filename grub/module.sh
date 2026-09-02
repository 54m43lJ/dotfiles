#!/bin/bash
# GRUB bootloader theme

install_module() {
    log "Installing GRUB theme..."

    sudo cp -r "$WD/grub" /boot/grub/themes/

    sudo sed -i -E 's/^(GRUB_TIMEOUT=).*$/\130/g' /etc/default/grub
    sudo sed -i -E 's/^(GRUB_DEFAULT=).*$/\10/g' /etc/default/grub

    if ! confirm "Do you have integrated graphics (iGPU)?"; then
        sudo sed -i -E 's/^(GRUB_GFXMODE=).*$/\11280x720/g' /etc/default/grub
    fi

    sudo sed -i -E 's/^#(GRUB_THEME=).*$/\1"\/boot\/grub\/themes\/grub\/theme\.txt"/g' /etc/default/grub
    sudo sed -i -E 's/^(GRUB_SAVEDEFAULT=).*$/\1false/g' /etc/default/grub
    sudo sed -i -E 's/^#(GRUB_DISABLE_OS_PROBER=false).*$/\1/g' /etc/default/grub
    sudo grub-mkconfig -o /boot/grub/grub.cfg

    log "GRUB theme installed."
}

#!/bin/bash
# Virtualization: QEMU/KVM + libvirt + virt-manager

install_module() {
    log "Installing virtualization tools..."
    local VIRT_PKGS=(qemu-full virt-manager virt-viewer libvirt dnsmasq edk2-ovmf)
    pac_ins "${VIRT_PKGS[@]}"

    sudo systemctl enable --now libvirtd

    # libvirt group: passwordless access to qemu:///system; takes effect on
    # next login.
    sudo usermod -aG libvirt "$USER"

    log "Virtualization configured."
}

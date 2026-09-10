#!/bin/bash
# Bundle: full desktop (optional NVIDIA, pick per machine)

install_module() {
    install_modules system hypr sddm clash dunst fcitx5 fontconfig foot \
        qqmusic wechat wofi zsh breeze
    confirm "Install NVIDIA drivers?" && install_modules nvidia
    confirm "Install virtualization (QEMU/KVM + libvirt)?" && install_modules virt
}

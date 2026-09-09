#!/bin/bash
# Sub-module: xiaomi_book device settings

install_module() {
    mkdir -p ~/.config/hypr/special
    cp "$WD/per-device-conf/xiaomi_book/hypr.lua" ~/.config/hypr/special/xiaomi_book.lua
    log "Enabled: xiaomi_book"
}

#!/bin/bash
# Sub-module: xiaomi_book device settings

install_module() {
    mkdir -p ~/.config/hypr/special
    set_flag xiaomi_book ~/.config/hypr/flags.lua
    cp "$WD/per-device-conf/xiaomi_book/hypr.lua" ~/.config/hypr/special/xiaomi_book.lua
    log "Enabled: xiaomi_book"
}

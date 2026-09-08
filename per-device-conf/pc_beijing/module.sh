#!/bin/bash
# Sub-module: pc_beijing device settings

install_module() {
    mkdir -p ~/.config/hypr/special
    set_flag pc_beijing ~/.config/hypr/flags.lua
    cp "$WD/per-device-conf/pc_beijing/hypr.lua" ~/.config/hypr/special/pc_beijing.lua
    log "Enabled: pc_beijing"
}

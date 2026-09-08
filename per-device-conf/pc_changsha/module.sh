#!/bin/bash
# Sub-module: pc_changsha device settings

install_module() {
    mkdir -p ~/.config/hypr/special
    set_flag pc_changsha ~/.config/hypr/flags.lua
    cp "$WD/per-device-conf/pc_changsha/hypr.lua" ~/.config/hypr/special/pc_changsha.lua
    log "Enabled: pc_changsha"
}

#!/bin/bash
# Sub-module: pc_beijing device settings

install_module() {
    mkdir -p ~/.config/hypr/special
    cp "$WD/per-device-conf/pc_beijing/hypr.lua" ~/.config/hypr/special/pc_beijing.lua

    # Desktop idle policy: no lock, no auto-suspend (overrides hypr module)
    cp "$WD/per-device-conf/pc_beijing/hypridle.conf" ~/.config/hypr/hypridle.conf
    restart_hypridle

    log "Enabled: pc_beijing"
}

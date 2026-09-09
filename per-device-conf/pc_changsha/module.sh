#!/bin/bash
# Sub-module: pc_changsha device settings

install_module() {
    mkdir -p ~/.config/hypr/special
    cp "$WD/per-device-conf/pc_changsha/hypr.lua" ~/.config/hypr/special/pc_changsha.lua

    # Desktop idle policy: no lock, no auto-suspend (overrides hypr module)
    cp "$WD/per-device-conf/pc_changsha/hypridle.conf" ~/.config/hypr/hypridle.conf

    log "Enabled: pc_changsha"
}

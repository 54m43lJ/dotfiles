#!/bin/bash
# Sub-module: macbookpro device settings

install_module() {
    mkdir -p ~/.config/hypr/special
    cp "$WD/per-device-conf/macbookpro/hypr.lua" ~/.config/hypr/special/macbookpro.lua
    log "Enabled: macbookpro"
}

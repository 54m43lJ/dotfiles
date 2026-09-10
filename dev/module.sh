#!/bin/bash
# Developer environment: language toolchains + tool modules

install_module() {
    log "Setting up developer environment..."

    # Language toolchains: per-language multi-select, all on by default
    local -a langs=("Python" "C/C++" "Rust" "Node.js")
    local -a sel=("${langs[@]}")
    local lang
    if select_multi sel "${langs[@]}"; then
        for lang in "${sel[@]}"; do
            case "$lang" in
                Python)    pac_ins python ;;
                "C/C++")   pac_ins gcc make ;;
                Rust)      pac_ins rustup
                           rustup default stable
                           rustup component add rust-src clippy rustfmt ;;
                "Node.js") pac_ins npm ;;
            esac
        done
    else
        warn "No languages selected, skipping toolchains."
    fi

    # Dev tools: module multi-select, all on by default
    local -a tools=(nvim vscode remote opencode-desktop)
    local -a tsel=("${tools[@]}")
    if select_multi tsel "${tools[@]}"; then
        install_modules "${tsel[@]}"
    else
        warn "No dev tools selected, skipping."
    fi

    log "Developer environment configured."
}

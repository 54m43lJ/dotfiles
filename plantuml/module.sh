#!/bin/bash
# PlantUML: diagram-as-code renderer (sequence/class/component/...), used to
# illustrate design docs. The official jar ships in ~/Applications so it sits
# outside pacman and updates are a re-download.

install_module() {
    log "Installing PlantUML..."

    # Runtime: a JRE for the jar; graphviz for the graph-based layouts
    # (the embedded smetana engine covers most cases, dot is more accurate).
    pac_ins jre-openjdk graphviz

    # Official latest jar; keep an existing one so re-runs stay offline-safe.
    mkdir -p ~/Applications
    if [[ ! -f ~/Applications/plantuml.jar ]]; then
        log "Downloading plantuml.jar (latest release)..."
        curl -fL --retry 3 -o ~/Applications/plantuml.jar \
            https://github.com/plantuml/plantuml/releases/latest/download/plantuml.jar \
            || { FAILED="$FAILED plantuml.jar"; err "Failed: plantuml.jar download"; return 0; }
    fi

    # CLI wrapper in ~/.local/bin (on PATH via zshrc). A script, not an
    # alias, so non-interactive shells (opencode) resolve it too.
    mkdir -p ~/.local/bin
    cat > ~/.local/bin/plantuml <<'EOF'
#!/bin/bash
exec java -jar "$HOME/Applications/plantuml.jar" "$@"
EOF
    chmod +x ~/.local/bin/plantuml

    log "PlantUML configured."
}

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

    # CLI alias, idempotent so the module can re-run safely.
    if ! grep -q 'alias plantuml=' ~/.zshrc 2>/dev/null; then
        cat >> ~/.zshrc <<'EOF'

# PlantUML (managed by plantuml module)
alias plantuml='java -jar ~/Applications/plantuml.jar'
EOF
        log "Added plantuml alias to ~/.zshrc (re-login or `source ~/.zshrc`)."
    fi

    log "PlantUML configured."
}

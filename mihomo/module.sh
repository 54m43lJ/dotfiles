#!/bin/bash
# Mihomo (Clash Meta) — download latest release, deploy binary + config + systemd service

install_module() {
    if ! confirm "Install mihomo (Clash Meta)?"; then
        return 0
    fi

    log "Installing mihomo..."

    # --- fetch latest release assets ---
    log "Fetching latest release from GitHub..."
    local api_url="https://api.github.com/repos/MetaCubeX/mihomo/releases/latest"
    local -a urls
    local -a names
    local idx=1

    while IFS= read -r url; do
        urls+=("$url")
        names+=("$(basename "$url")")
        echo "  $idx) $(basename "$url")"
        ((idx++))
    done < <(curl -sL "$api_url" | grep -oE '"browser_download_url":\s*"https://[^"]*mihomo-linux-amd64[^"]*"' | grep -oE 'https://[^"]*')

    if [[ ${#urls[@]} -eq 0 ]]; then
        err "Failed to parse download URLs."
        return 1
    fi

    if [[ -n "$YES" ]]; then
        # non-interactive: pick first
        local choice=1
        log "Non-interactive mode: selecting option 1 (${names[0]})"
    else
        read -p "Select file to download (1-${#urls[@]}): " choice
        if [[ ! "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#urls[@]} )); then
            err "Invalid choice: $choice"
            return 1
        fi
    fi

    local chosen_url="${urls[$((choice - 1))]}"
    local chosen_name="${names[$((choice - 1))]}"
    log "Downloading: $chosen_name"

    # --- download ---
    local tmp_deb="/tmp/${chosen_name}"
    curl -L --progress-bar -o "$tmp_deb" "$chosen_url"

    # --- extract ---
    log "Extracting..."
    gzip -dkc "$tmp_deb" > /tmp/mihomo
    chmod +x /tmp/mihomo

    # --- install binary ---
    log "Installing binary to /usr/bin/mihomo..."
    sudo cp /tmp/mihomo /usr/bin/mihomo

    # --- deploy config ---
    log "Deploying config..."
    sudo mkdir -p /etc/mihomo
    sudo cp "$WD/mihomo/config.yaml" /etc/mihomo/config.yaml

    # --- deploy web UI ---
    log "Downloading MetaCubeXD web UI..."
    local ui_url="https://github.com/MetaCubeX/metacubexd/releases/latest/download/compressed-dist.tgz"
    sudo mkdir -p /etc/mihomo/ui
    curl -L --progress-bar "$ui_url" | sudo tar -xz -C /etc/mihomo/ui/

    # --- deploy systemd service ---
    log "Enabling mihomo service..."
    sudo cp "$WD/mihomo/mihomo.service" /etc/systemd/system/mihomo.service
    sudo systemctl daemon-reload
    sudo systemctl enable --now mihomo.service

    # --- cleanup ---
    rm -f "$tmp_deb" /tmp/mihomo

    log "Mihomo installed and running."
}

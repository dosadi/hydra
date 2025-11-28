#!/usr/bin/env bash
# Router Administration Configuration
# Set up connection details for router remote administration

set -euo pipefail

CONFIG_FILE="$HOME/.router_admin_config"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[ROUTER-CONFIG]${NC} $*" >&2; }
log_warn() { echo -e "${YELLOW}[ROUTER-CONFIG]${NC} $*" >&2; }
log_success() { echo -e "${GREEN}[ROUTER-CONFIG]${NC} $*" >&2; }

# Load existing config
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
    fi
}

# Save config
save_config() {
    cat > "$CONFIG_FILE" << EOF
# Router Administration Configuration
# Generated on $(date)

export ROUTER_IP="$ROUTER_IP"
export ROUTER_USER="$ROUTER_USER"
export ROUTER_SSH_PORT="$ROUTER_SSH_PORT"
export SSH_KEY="$SSH_KEY"
export ROUTER_MODEL="$ROUTER_MODEL"
export ROUTER_FIRMWARE="$ROUTER_FIRMWARE"
EOF

    chmod 600 "$CONFIG_FILE"
    log_success "Configuration saved to $CONFIG_FILE"
}

# Detect router IP (common router IPs)
detect_router_ip() {
    log_info "Attempting to detect router IP..."

    # Common router IPs to try
    local common_ips=("192.168.1.1" "192.168.0.1" "10.0.0.1" "192.168.2.1" "192.168.100.1")

    for ip in "${common_ips[@]}"; do
        log_info "Testing $ip..."
        if ping -c 1 -W 1 "$ip" >/dev/null 2>&1; then
            log_success "Found router at $ip"
            ROUTER_IP="$ip"
            return 0
        fi
    done

    log_warn "Could not auto-detect router IP"
    return 1
}

# Test router connection
test_router_connection() {
    local ip="$1"
    local user="${2:-admin}"
    local port="${3:-22}"

    log_info "Testing connection to $user@$ip:$port..."

    if ssh -i "$SSH_KEY" -p "$port" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
           -o ConnectTimeout=5 "$user@$ip" "echo 'Connection successful'" >/dev/null 2>&1; then
        log_success "SSH connection successful"
        return 0
    else
        log_warn "SSH connection failed"
        return 1
    fi
}

# Get router info
get_router_info() {
    local ip="$ROUTER_IP"
    local user="$ROUTER_USER"
    local port="$ROUTER_SSH_PORT"

    log_info "Getting router information..."

    ROUTER_MODEL=$(ssh -i "$SSH_KEY" -p "$port" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
                     "$user@$ip" "
        cat /proc/cpuinfo | grep 'model name' | head -1 | cut -d: -f2 | xargs || \
        uname -a | awk '{print \$2}' || \
        echo 'Unknown'
    " 2>/dev/null || echo "Unknown")

    ROUTER_FIRMWARE=$(ssh -i "$SSH_KEY" -p "$port" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
                        "$user@$ip" "
        cat /etc/openwrt_release 2>/dev/null | grep DISTRIB_DESCRIPTION | cut -d\"'\" -f2 || \
        cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d\"'\" -f2 || \
        uname -sr || \
        echo 'Unknown'
    " 2>/dev/null || echo "Unknown")

    log_info "Model: $ROUTER_MODEL"
    log_info "Firmware: $ROUTER_FIRMWARE"
}

# Interactive configuration
interactive_config() {
    echo "=== Router Administration Configuration ==="
    echo

    # Router IP
    if [[ -z "$ROUTER_IP" ]]; then
        read -rp "Router IP address (or 'auto' to detect): " ip_input
        if [[ "$ip_input" == "auto" ]]; then
            if detect_router_ip; then
                log_info "Using detected IP: $ROUTER_IP"
            else
                read -rp "Enter router IP address: " ROUTER_IP
            fi
        else
            ROUTER_IP="$ip_input"
        fi
    fi

    # Router user
    if [[ -z "$ROUTER_USER" ]]; then
        read -rp "Router SSH username (default: admin): " ROUTER_USER
        ROUTER_USER="${ROUTER_USER:-admin}"
    fi

    # SSH port
    if [[ -z "$ROUTER_SSH_PORT" ]]; then
        read -rp "Router SSH port (default: 22): " ROUTER_SSH_PORT
        ROUTER_SSH_PORT="${ROUTER_SSH_PORT:-22}"
    fi

    # SSH key
    if [[ -z "$SSH_KEY" ]]; then
        read -rp "SSH key path (default: $HOME/.ssh/id_ed25519): " SSH_KEY
        SSH_KEY="${SSH_KEY:-$HOME/.ssh/id_ed25519}"
    fi

    # Test connection
    echo
    log_info "Testing configuration..."
    if test_router_connection "$ROUTER_IP" "$ROUTER_USER" "$ROUTER_SSH_PORT"; then
        get_router_info
        save_config
        log_success "Router configuration complete!"
        echo
        echo "=== Router Connection Info ==="
        echo "IP: $ROUTER_IP"
        echo "User: $ROUTER_USER"
        echo "Port: $ROUTER_SSH_PORT"
        echo "Model: $ROUTER_MODEL"
        echo "Firmware: $ROUTER_FIRMWARE"
        echo
        echo "To start administering your router:"
        echo "source $CONFIG_FILE"
        echo "./scripts/router_admin.sh"
    else
        log_error "Configuration test failed"
        log_info "Please check your settings and try again"
        return 1
    fi
}

# Command line configuration
cli_config() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --ip) ROUTER_IP="$2"; shift 2 ;;
            --user) ROUTER_USER="$2"; shift 2 ;;
            --port) ROUTER_SSH_PORT="$2"; shift 2 ;;
            --key) SSH_KEY="$2"; shift 2 ;;
            --auto-detect) detect_router_ip; shift ;;
            --test) test_router_connection "$ROUTER_IP" "$ROUTER_USER" "$ROUTER_SSH_PORT" && get_router_info; exit $? ;;
            *) log_error "Unknown option: $1"; exit 1 ;;
        esac
    done

    if [[ -n "$ROUTER_IP" ]]; then
        if test_router_connection "$ROUTER_IP" "$ROUTER_USER" "$ROUTER_SSH_PORT"; then
            get_router_info
            save_config
        else
            log_error "Connection test failed"
            exit 1
        fi
    else
        log_error "Router IP not specified"
        exit 1
    fi
}

# Main
main() {
    load_config

    if [[ $# -eq 0 ]]; then
        interactive_config
    else
        cli_config "$@"
    fi
}

main "$@"
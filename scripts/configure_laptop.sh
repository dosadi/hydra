#!/usr/bin/env bash
# Laptop Administration Configuration
# Set up connection details for laptop remote administration

set -euo pipefail

CONFIG_FILE="$HOME/.laptop_admin_config"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[CONFIG]${NC} $*" >&2; }
log_warn() { echo -e "${YELLOW}[CONFIG]${NC} $*" >&2; }
log_success() { echo -e "${GREEN}[CONFIG]${NC} $*" >&2; }

# Load existing config
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
    fi
}

# Save config
save_config() {
    cat > "$CONFIG_FILE" << EOF
# Laptop Administration Configuration
# Generated on $(date)

export LAPTOP_IP="$LAPTOP_IP"
export LAPTOP_USER="$LAPTOP_USER"
export LAPTOP_SSH_PORT="$LAPTOP_SSH_PORT"
export SSH_KEY="$SSH_KEY"
export LAPTOP_NAME="$LAPTOP_NAME"
export LAPTOP_OS="$LAPTOP_OS"
EOF

    chmod 600 "$CONFIG_FILE"
    log_success "Configuration saved to $CONFIG_FILE"
}

# Detect laptop IP (if on same network)
detect_laptop_ip() {
    log_info "Attempting to detect laptop IP..."

    # Try common local network ranges
    local networks=("192.168.1.0/24" "192.168.0.0/24" "10.0.0.0/24" "172.16.0.0/12")

    for network in "${networks[@]}"; do
        log_info "Scanning $network..."
        # Use nmap if available, otherwise try basic ping sweep
        if command -v nmap >/dev/null; then
            nmap -sn "$network" 2>/dev/null | grep "Nmap scan report" | awk '{print $5}' | head -10
        else
            log_warn "nmap not available for network scanning"
            log_info "Please manually enter your laptop IP"
            return
        fi
    done
}

# Test connection with given IP
test_ip() {
    local ip="$1"
    local user="${2:-$(whoami)}"
    local port="${3:-22}"
    local key="${4:-$HOME/.ssh/id_ed25519}"

    log_info "Testing connection to $user@$ip:$port..."

    if ssh -i "$key" -p "$port" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 "$user@$ip" "echo 'Connection successful'" >/dev/null 2>&1; then
        log_success "Connection successful!"
        return 0
    else
        log_warn "Connection failed to $ip"
        return 1
    fi
}

# Interactive setup
interactive_setup() {
    echo "=== Laptop Administration Configuration ==="
    echo

    # Load existing config
    load_config

    # Get laptop IP
    if [[ -z "${LAPTOP_IP:-}" ]]; then
        echo "Detecting available IPs on your network..."
        detect_laptop_ip
        echo
    fi

    read -rp "Enter your laptop IP address [${LAPTOP_IP:-}]: " input_ip
    LAPTOP_IP="${input_ip:-${LAPTOP_IP:-}}"

    if [[ -z "$LAPTOP_IP" ]]; then
        log_error "Laptop IP is required"
        exit 1
    fi

    # Get username
    read -rp "Enter laptop username [${LAPTOP_USER:-$(whoami)}]: " input_user
    LAPTOP_USER="${input_user:-${LAPTOP_USER:-$(whoami)}}"

    # Get SSH port
    read -rp "Enter SSH port [${LAPTOP_SSH_PORT:-22}]: " input_port
    LAPTOP_SSH_PORT="${input_port:-${LAPTOP_SSH_PORT:-22}}"

    # Get SSH key path
    read -rp "Enter SSH key path [${SSH_KEY:-$HOME/.ssh/id_ed25519}]: " input_key
    SSH_KEY="${input_key:-${SSH_KEY:-$HOME/.ssh/id_ed25519}}"

    # Get laptop name (optional)
    read -rp "Enter laptop name/alias [${LAPTOP_NAME:-MyLaptop}]: " input_name
    LAPTOP_NAME="${input_name:-${LAPTOP_NAME:-MyLaptop}}"

    # Test connection
    echo
    if test_ip "$LAPTOP_IP" "$LAPTOP_USER" "$LAPTOP_SSH_PORT" "$SSH_KEY"; then
        # Get OS info
        LAPTOP_OS=$(ssh -i "$SSH_KEY" -p "$LAPTOP_SSH_PORT" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$LAPTOP_USER@$LAPTOP_IP" "uname -a" 2>/dev/null || echo "Unknown")

        log_success "Configuration complete!"
        save_config

        echo
        echo "=== Configuration Summary ==="
        echo "Laptop Name: $LAPTOP_NAME"
        echo "IP Address: $LAPTOP_IP"
        echo "Username: $LAPTOP_USER"
        echo "SSH Port: $LAPTOP_SSH_PORT"
        echo "SSH Key: $SSH_KEY"
        echo "OS: $LAPTOP_OS"
        echo
        echo "To start administering your laptop, run:"
        echo "  source $CONFIG_FILE"
        echo "  /workspaces/hydra/scripts/laptop_admin.sh"
    else
        log_error "Connection test failed. Please check your settings and try again."
        log_info "Make sure:"
        log_info "  1. SSH is running on your laptop"
        log_info "  2. Your SSH key is added to ~/.ssh/authorized_keys on the laptop"
        log_info "  3. Firewall allows SSH connections"
        exit 1
    fi
}

# Quick setup with arguments
quick_setup() {
    LAPTOP_IP="$1"
    LAPTOP_USER="${2:-$(whoami)}"
    LAPTOP_SSH_PORT="${3:-22}"
    SSH_KEY="${4:-$HOME/.ssh/id_ed25519}"
    LAPTOP_NAME="${5:-MyLaptop}"

    if test_ip "$LAPTOP_IP" "$LAPTOP_USER" "$LAPTOP_SSH_PORT" "$SSH_KEY"; then
        LAPTOP_OS=$(ssh -i "$SSH_KEY" -p "$LAPTOP_SSH_PORT" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$LAPTOP_USER@$LAPTOP_IP" "uname -a" 2>/dev/null || echo "Unknown")
        save_config
        log_success "Quick setup complete!"
    else
        log_error "Connection test failed"
        exit 1
    fi
}

# Show current config
show_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        echo "=== Current Laptop Configuration ==="
        cat "$CONFIG_FILE"
    else
        log_warn "No configuration found. Run setup first."
    fi
}

# Usage
usage() {
    echo "Usage: $0 [setup|quick|show|test]"
    echo
    echo "Commands:"
    echo "  setup          - Interactive configuration setup"
    echo "  quick IP [USER] [PORT] [KEY] [NAME] - Quick setup with arguments"
    echo "  show           - Show current configuration"
    echo "  test           - Test current configuration"
    echo
    echo "Examples:"
    echo "  $0 setup"
    echo "  $0 quick 192.168.1.100"
    echo "  $0 quick 192.168.1.100 myuser 22 ~/.ssh/id_rsa MyLaptop"
}

# Main
case "${1:-}" in
    setup) interactive_setup ;;
    quick)
        if [[ $# -lt 2 ]]; then
            usage
            exit 1
        fi
        quick_setup "$2" "${3:-}" "${4:-}" "${5:-}" "${6:-}"
        ;;
    show) show_config ;;
    test)
        load_config
        if [[ -z "${LAPTOP_IP:-}" ]]; then
            log_error "No configuration found. Run setup first."
            exit 1
        fi
        test_ip "$LAPTOP_IP" "$LAPTOP_USER" "$LAPTOP_SSH_PORT" "$SSH_KEY"
        ;;
    "") interactive_setup ;;
    *) usage ;;
esac
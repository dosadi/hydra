#!/usr/bin/env bash
# Android Password Keeper Configuration
# Set up password management integration with Android/Termux

set -euo pipefail

CONFIG_FILE="$HOME/.android_password_config"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[PASS-CONFIG]${NC} $*" >&2; }
log_warn() { echo -e "${YELLOW}[PASS-WARN]${NC} $*" >&2; }
log_success() { echo -e "${GREEN}[PASS-SUCCESS]${NC} $*" >&2; }

# Load existing config
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
    fi
}

# Save config
save_config() {
    cat > "$CONFIG_FILE" << EOF
# Android Password Keeper Configuration
# Generated on $(date)

export TERMUX_IP="$TERMUX_IP"
export TERMUX_USER="$TERMUX_USER"
export PASSWORD_STORE="$PASSWORD_STORE"
export ANDROID_STORE="$ANDROID_STORE"
EOF

    chmod 600 "$CONFIG_FILE"
    log_success "Configuration saved to $CONFIG_FILE"
}

# Detect Android device
detect_android() {
    log_info "Attempting to detect Android device..."

    # Try common Android IPs on local network
    local networks=("192.168.1.0/24" "192.168.0.0/24" "10.0.0.0/24" "172.16.0.0/12")

    for network in "${networks[@]}"; do
        log_info "Scanning $network for Android devices..."
        # This would require nmap or similar - for now, we'll ask user
        break
    done

    log_warn "Auto-detection not implemented. Please provide Android IP manually."
}

# Test Android connection
test_android_connection() {
    local ip="$1"
    local user="${2:-termux-user}"

    log_info "Testing connection to Android at $ip..."

    if ssh -i "$HOME/.ssh/id_ed25519" -p 8022 -o StrictHostKeyChecking=no \
           -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10 \
           "$user@$ip" "echo 'Android connection successful'" >/dev/null 2>&1; then
        log_success "SSH connection to Android established"
        return 0
    else
        log_error "Cannot connect to Android device"
        log_info "Please check:"
        log_info "  - Android IP: $ip"
        log_info "  - SSH server running in Termux"
        log_info "  - SSH key configured correctly"
        log_info "  - Termux has been granted storage permissions"
        return 1
    fi
}

# Setup Android password store
setup_android_password_store() {
    local ip="$TERMUX_IP"
    local user="$TERMUX_USER"

    log_info "Setting up password store on Android..."

    # Install required packages
    ssh -i "$HOME/.ssh/id_ed25519" -p 8022 -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null "$user@$ip" "
        pkg update
        pkg install -y gnupg pass git openssh termux-api
        mkdir -p ~/.password-store
        chmod 700 ~/.password-store
    "

    log_success "Password store setup on Android"
}

# Interactive configuration
interactive_config() {
    echo "=== Android Password Keeper Configuration ==="
    echo

    # Android IP
    if [[ -z "$TERMUX_IP" ]]; then
        read -rp "Android device IP address: " TERMUX_IP
    fi

    # Android user
    if [[ -z "$TERMUX_USER" ]]; then
        read -rp "Termux username (default: termux-user): " TERMUX_USER
        TERMUX_USER="${TERMUX_USER:-termux-user}"
    fi

    # Password store location
    if [[ -z "$PASSWORD_STORE" ]]; then
        read -rp "Local password store path (default: $HOME/.password-store): " PASSWORD_STORE
        PASSWORD_STORE="${PASSWORD_STORE:-$HOME/.password-store}"
    fi

    # Android store location
    if [[ -z "$ANDROID_STORE" ]]; then
        read -rp "Android password store path (default: /data/data/com.termux/files/home/.password-store): " ANDROID_STORE
        ANDROID_STORE="${ANDROID_STORE:-/data/data/com.termux/files/home/.password-store}"
    fi

    # Test connection
    echo
    log_info "Testing Android connection..."
    if test_android_connection "$TERMUX_IP" "$TERMUX_USER"; then
        setup_android_password_store
        save_config
        log_success "Android password keeper configuration complete!"
        echo
        echo "=== Android Password Keeper Ready ==="
        echo "Android IP: $TERMUX_IP"
        echo "Termux User: $TERMUX_USER"
        echo "Local Store: $PASSWORD_STORE"
        echo "Android Store: $ANDROID_STORE"
        echo
        echo "To start managing passwords:"
        echo "source $CONFIG_FILE"
        echo "./scripts/android_password_keeper.sh"
    else
        log_error "Configuration test failed"
        log_info "Please check your Android setup and try again"
        return 1
    fi
}

# Command line configuration
cli_config() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --android-ip) TERMUX_IP="$2"; shift 2 ;;
            --android-user) TERMUX_USER="$2"; shift 2 ;;
            --password-store) PASSWORD_STORE="$2"; shift 2 ;;
            --android-store) ANDROID_STORE="$2"; shift 2 ;;
            --detect) detect_android; shift ;;
            --test) test_android_connection "$TERMUX_IP" "$TERMUX_USER"; exit $? ;;
            --setup) setup_android_password_store; exit $? ;;
            *) log_error "Unknown option: $1"; exit 1 ;;
        esac
    done

    if [[ -n "$TERMUX_IP" ]]; then
        if test_android_connection "$TERMUX_IP" "$TERMUX_USER"; then
            setup_android_password_store
            save_config
        else
            log_error "Connection test failed"
            exit 1
        fi
    else
        log_error "Android IP not specified"
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
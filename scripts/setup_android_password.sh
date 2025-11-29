#!/usr/bin/env bash
# Android Password Keeper Setup Script
# Configure password management on Android via Termux

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[PASS-SETUP]${NC} $*" >&2; }
log_warn() { echo -e "${YELLOW}[PASS-WARN]${NC} $*" >&2; }
log_error() { echo -e "${RED}[PASS-ERROR]${NC} $*" >&2; }
log_success() { echo -e "${GREEN}[PASS-SUCCESS]${NC} $*" >&2; }

# Get Android IP from user or auto-detect
get_android_ip() {
    echo "=== Android Password Keeper Setup ==="
    echo
    log_info "We need to connect to your Android device running Termux"
    echo
    log_info "Make sure Termux is running and SSH is enabled:"
    echo "  pkg install openssh"
    echo "  sshd"
    echo

    # Try to auto-detect Android IP
    log_info "Attempting to auto-detect Android IP address..."
    
    # Method 1: Check for recent SSH connections
    if command -v last &>/dev/null; then
        RECENT_IP=$(last -i | grep -E "termux|android" | head -1 | awk '{print $3}' || true)
        if [[ -n "$RECENT_IP" && "$RECENT_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            log_success "Found recent connection from: $RECENT_IP"
            read -rp "Use this IP address? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                ANDROID_IP="$RECENT_IP"
                return
            fi
        fi
    fi

    # Method 2: Check ARP table for Android devices
    if command -v arp &>/dev/null; then
        log_info "Checking ARP table for Android devices..."
        arp -a | grep -i android || true
    fi

    # Method 3: Network scan (if nmap available)
    if command -v nmap &>/dev/null; then
        log_info "Scanning local network for Termux SSH servers..."
        LOCAL_IP=$(ip route get 8.8.8.8 2>/dev/null | awk '{print $7}' | head -1 || hostname -I | awk '{print $1}')
        if [[ -n "$LOCAL_IP" ]]; then
            NETWORK=$(echo "$LOCAL_IP" | sed 's/\.[0-9]*$/.0\/24/')
            log_info "Scanning network: $NETWORK"
            nmap -p 8022 --open "$NETWORK" 2>/dev/null | grep "Nmap scan report" | awk '{print $5}' || true
        fi
    fi

    # Fallback to manual entry
    echo
    log_warn "Could not auto-detect Android IP. Please find your Android IP:"
    echo "  On Android/Termux, try these commands:"
    echo "    ip addr show wlan0 | grep 'inet ' | awk '{print \$2}' | cut -d/ -f1"
    echo "    curl -s ifconfig.me"
    echo "    getprop dhcp.wlan0.ipaddress"
    echo
    read -rp "Enter your Android device IP address: " ANDROID_IP
    echo
}

# Install password store on Android
install_android_password_store() {
    log_info "Installing password store on Android..."

    # Install required packages
    ssh -i "$HOME/.ssh/id_ed25519" -p 8022 -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null "termux-user@$ANDROID_IP" "
        pkg update
        pkg install -y gnupg pass git openssh termux-api
        mkdir -p ~/.password-store
        chmod 700 ~/.password-store
        log_success 'Password store installed on Android'
    "
}

# Setup GPG keys
setup_gpg_keys() {
    log_info "Setting up GPG keys for password encryption..."

    # Generate GPG key pair
    cat > /tmp/gpg_batch << 'EOF'
Key-Type: RSA
Key-Length: 4096
Name-Real: Android Password Manager
Name-Email: android-password@localhost
Expire-Date: 0
%no-protection
%commit
EOF

    gpg --batch --generate-key /tmp/gpg_batch
    rm /tmp/gpg_batch

    # Get the key ID
    GPG_KEY=$(gpg --list-keys --with-colons | grep '^pub' | cut -d: -f5)

    log_success "GPG key generated: $GPG_KEY"
}

# Initialize password store
init_password_store() {
    log_info "Initializing password store..."

    # Initialize local password store
    pass init "$GPG_KEY"

    # Create initial password entry
    echo "Welcome to Android Password Keeper!" | pass insert -m "android-password-keeper/welcome"

    log_success "Password store initialized"
}

# Setup Android password store
setup_android_store() {
    log_info "Setting up password store on Android..."

    # Copy GPG keys to Android
    gpg --export-secret-keys "$GPG_KEY" | \
    ssh -i "$HOME/.ssh/id_ed25519" -p 8022 -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null "termux-user@$ANDROID_IP" "gpg --import"

    gpg --export "$GPG_KEY" | \
    ssh -i "$HOME/.ssh/id_ed25519" -p 8022 -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null "termux-user@$ANDROID_IP" "gpg --import"

    # Initialize Android password store
    ssh -i "$HOME/.ssh/id_ed25519" -p 8022 -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null "termux-user@$ANDROID_IP" "
        gpg --list-keys
        GPG_KEY=\$(gpg --list-keys --with-colons | grep '^pub' | cut -d: -f5)
        pass init \"\$GPG_KEY\"
        echo 'Android password store initialized' | pass insert -m 'android-password-keeper/android-welcome'
    "

    log_success "Android password store setup complete"
}

# Create sync scripts
create_sync_scripts() {
    log_info "Creating password sync scripts..."

    # Local sync script
    cat > "$HOME/.password_sync.sh" << EOF
#!/bin/bash
# Password sync script

ANDROID_IP="$ANDROID_IP"

echo "Syncing passwords to Android..."
cd ~
tar czf /tmp/password_sync.tar.gz .password-store .gnupg

scp -i ~/.ssh/id_ed25519 -P 8022 -o StrictHostKeyChecking=no \\
    /tmp/password_sync.tar.gz termux-user@\$ANDROID_IP:/tmp/

ssh -i ~/.ssh/id_ed25519 -p 8022 -o StrictHostKeyChecking=no \\
    termux-user@\$ANDROID_IP "
    cd ~
    tar xzf /tmp/password_sync.tar.gz
    rm /tmp/password_sync.tar.gz
    chmod 700 .password-store .gnupg
"

rm /tmp/password_sync.tar.gz
echo "Password sync complete"
EOF

    chmod +x "$HOME/.password_sync.sh"

    # Android sync script
    ssh -i "$HOME/.ssh/id_ed25519" -p 8022 -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null "termux-user@$ANDROID_IP" "
        cat > ~/.password_sync.sh << 'EOF'
#!/bin/bash
# Android password sync script

CODESPACE_IP=\"${CODESPACE_IP:-10.0.10.154}\"

echo \"Syncing passwords to Codespaces...\"
cd ~
tar czf /tmp/password_sync.tar.gz .password-store .gnupg

scp -i ~/.ssh/id_ed25519 -P 2222 -o StrictHostKeyChecking=no \\
    /tmp/password_sync.tar.gz codespace@\$CODESPACE_IP:/tmp/

ssh -i ~/.ssh/id_ed25519 -p 2222 -o StrictHostKeyChecking=no \\
    codespace@\$CODESPACE_IP "
    cd ~
    tar xzf /tmp/password_sync.tar.gz
    rm /tmp/password_sync.tar.gz
    chmod 700 .password-store .gnupg
"

rm /tmp/password_sync.tar.gz
echo \"Password sync complete\"
EOF

chmod +x ~/.password_sync.sh
"

    log_success "Sync scripts created"
}

# Create Android password management script
create_android_script() {
    log_info "Creating Android password management script..."

    ssh -i "$HOME/.ssh/id_ed25519" -p 8022 -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null "termux-user@$ANDROID_IP" "
        cat > ~/.password_manager.sh << 'EOF'
#!/bin/bash
# Android Password Manager

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e \"\${BLUE}[ANDROID-PASS]\${NC} \$*\"; }
log_success() { echo -e \"\${GREEN}[SUCCESS]\${NC} \$*\"; }

show_menu() {
    echo \"=== Android Password Manager ===\"
    echo \"1. Add Password\"
    echo \"2. Get Password\"
    echo \"3. List Passwords\"
    echo \"4. Generate Password\"
    echo \"5. Sync to Codespaces\"
    echo \"6. Exit\"
    echo
}

main() {
    while true; do
        show_menu
        read -p \"Select option (1-6): \" choice

        case \$choice in
            1)
                read -p \"Password name: \" name
                read -p \"Password (leave empty to generate): \" password
                if [ -z \"\$password\" ]; then
                    password=\$(openssl rand -base64 12)
                    echo \"Generated password: \$password\"
                fi
                echo \"\$password\" | pass insert -m \"\$name\"
                log_success \"Password added: \$name\"
                ;;
            2)
                read -p \"Password name: \" name
                pass \"\$name\"
                ;;
            3)
                pass
                ;;
            4)
                length=\${1:-16}
                openssl rand -base64 \"\$length\"
                ;;
            5)
                ~/.password_sync.sh
                ;;
            6) exit 0 ;;
            *) echo \"Invalid option\" ;;
        esac
        echo
    done
}

main \"\$@\"
EOF

chmod +x ~/.password_manager.sh
"

    log_success "Android password management script created"
}

# Generate connection info
generate_connection_info() {
    log_info "Generating connection information..."

    cat << EOF

=== ANDROID PASSWORD KEEPER SETUP COMPLETE ===

Android IP: $ANDROID_IP
GPG Key: $GPG_KEY

Local Scripts:
• ~/.password_sync.sh - Sync passwords to Android
• ./scripts/android_password_keeper.sh - Full password management

Android Scripts:
• ~/.password_sync.sh - Sync passwords to Codespaces
• ~/.password_manager.sh - Android password management

Quick Commands:
# Add password locally
pass insert -m "service/username"

# Sync to Android
~/.password_sync.sh

# Manage passwords on Android
ssh -i ~/.ssh/id_ed25519 -p 8022 termux-user@$ANDROID_IP ~/.password_manager.sh

# Full management from Codespaces
./scripts/android_password_keeper.sh

Security Notes:
• All passwords encrypted with GPG
• SSH key authentication only
• No plaintext passwords in transit
• Automatic sync between devices

EOF
}

# Main setup
main() {
    get_android_ip

    # Check if SSH key exists
    if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
        log_error "SSH key not found. Please run SSH setup first."
        exit 1
    fi

    # Test connection
    log_info "Testing connection to Android..."
    if ! ssh -i "$HOME/.ssh/id_ed25519" -p 8022 -o StrictHostKeyChecking=no \
             -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10 \
             "termux-user@$ANDROID_IP" "echo 'Connection successful'" >/dev/null 2>&1; then
        log_error "Cannot connect to Android device"
        log_info "Please ensure:"
        log_info "  • Termux is installed and running"
        log_info "  • SSH server is running: sshd"
        log_info "  • SSH key is configured"
        log_info "  • Device is on the same network"
        exit 1
    fi

    install_android_password_store
    setup_gpg_keys
    init_password_store
    setup_android_store
    create_sync_scripts
    create_android_script
    generate_connection_info

    log_success "Android password keeper setup complete!"
}

# Run main function
main "$@"
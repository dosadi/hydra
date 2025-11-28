#!/usr/bin/env bash
# Android Password Keeper Integration
# Manage passwords on Android via Termux with sync to Codespaces

set -euo pipefail

# Configuration
PASSWORD_STORE="${PASSWORD_STORE:-$HOME/.password-store}"
ANDROID_STORE="${ANDROID_STORE:-/data/data/com.termux/files/home/.password-store}"
TERMUX_USER="${TERMUX_USER:-termux-user}"
TERMUX_IP="${TERMUX_IP:-}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[PASS-KEEPER]${NC} $*" >&2; }
log_warn() { echo -e "${YELLOW}[PASS-WARN]${NC} $*" >&2; }
log_error() { echo -e "${RED}[PASS-ERROR]${NC} $*" >&2; }
log_success() { echo -e "${GREEN}[PASS-SUCCESS]${NC} $*" >&2; }

# Check configuration
check_config() {
    if [[ -z "$TERMUX_IP" ]]; then
        log_error "TERMUX_IP not set. Please configure your Android IP address."
        log_info "Run: export TERMUX_IP='your.android.ip.address'"
        return 1
    fi

    # Check if SSH key exists
    if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
        log_error "SSH key not found. Please generate one first."
        log_info "Run: ssh-keygen -t ed25519 -C 'android-admin'"
        return 1
    fi
}

# SSH command wrapper for Android
android_ssh() {
    local cmd="$1"
    local retries=3
    local timeout=30

    for ((i=1; i<=retries; i++)); do
        log_info "SSH attempt $i/$retries to Android..."
        if ssh -i "$HOME/.ssh/id_ed25519" -p 8022 -o StrictHostKeyChecking=no \
            -o UserKnownHostsFile=/dev/null -o ConnectTimeout="$timeout" \
            -o ServerAliveInterval=10 -o ServerAliveCountMax=3 \
            "$TERMUX_USER@$TERMUX_IP" "$cmd" 2>/tmp/ssh_error.log; then
            return 0
        else
            local exit_code=$?
            if [[ $i -eq $retries ]]; then
                log_error "SSH failed after $retries attempts"
                cat /tmp/ssh_error.log >&2
                return $exit_code
            fi
            log_warn "SSH attempt $i failed, retrying in 2 seconds..."
            sleep 2
        fi
    done
}

# Install password store on Android
install_android_pass() {
    log_info "Installing password store on Android..."

    android_ssh "
        pkg update
        pkg install -y gnupg pass git openssh
        mkdir -p ~/.password-store
        chmod 700 ~/.password-store
    "

    log_success "Password store installed on Android"
}

# Initialize password store
init_password_store() {
    log_info "Initializing password store..."

    # Generate GPG key if needed
    if ! gpg --list-keys | grep -q "password-manager"; then
        log_info "Generating GPG key for password store..."
        cat > /tmp/gpg_batch << EOF
Key-Type: RSA
Key-Length: 4096
Name-Real: Password Manager
Name-Email: password-manager@localhost
Expire-Date: 0
Passphrase: $(openssl rand -base64 32)
%commit
EOF
        gpg --batch --generate-key /tmp/gpg_batch
        rm /tmp/gpg_batch
        log_warn "GPG key generated with random passphrase. Note it down securely!"
    fi

    # Get GPG key ID
    GPG_KEY=$(gpg --list-keys --with-colons | grep '^pub' | cut -d: -f5)

    # Initialize pass store
    if [[ ! -d "$PASSWORD_STORE" ]]; then
        pass init "$GPG_KEY"
        log_success "Password store initialized"
    else
        log_info "Password store already exists"
    fi

    # Sync to Android
    sync_to_android
}

# Sync password store to Android
sync_to_android() {
    log_info "Syncing password store to Android..."

    # Create tar archive
    cd "$HOME"
    tar czf /tmp/password_store.tar.gz .password-store .gnupg

    # Copy to Android
    scp -i "$HOME/.ssh/id_ed25519" -P 8022 -o StrictHostKeyChecking=no \
        /tmp/password_store.tar.gz "$TERMUX_USER@$TERMUX_IP":/tmp/

    # Extract on Android
    android_ssh "
        cd /tmp
        tar xzf password_store.tar.gz -C ~
        rm password_store.tar.gz
        chmod 700 ~/.password-store ~/.gnupg
    "

    rm /tmp/password_store.tar.gz
    log_success "Password store synced to Android"
}

# Sync password store from Android
sync_from_android() {
    log_info "Syncing password store from Android..."

    # Create tar archive on Android
    android_ssh "
        cd ~
        tar czf /tmp/password_store.tar.gz .password-store .gnupg
    "

    # Copy from Android
    scp -i "$HOME/.ssh/id_ed25519" -P 8022 -o StrictHostKeyChecking=no \
        "$TERMUX_USER@$TERMUX_IP":/tmp/password_store.tar.gz /tmp/

    # Extract locally
    cd "$HOME"
    tar xzf /tmp/password_store.tar.gz
    chmod 700 .password-store .gnupg

    # Clean up
    android_ssh "rm /tmp/password_store.tar.gz"
    rm /tmp/password_store.tar.gz

    log_success "Password store synced from Android"
}

# Add password
add_password() {
    local name="$1"
    local password="${2:-}"

    if [[ -z "$password" ]]; then
        log_info "Generating random password..."
        password=$(openssl rand -base64 12)
    fi

    echo "$password" | pass insert -m "$name"
    log_success "Password added: $name"

    # Sync to Android
    sync_to_android
}

# Get password
get_password() {
    local name="$1"
    pass "$name"
}

# List passwords
list_passwords() {
    log_info "Password store contents:"
    pass
}

# Search passwords
search_passwords() {
    local query="$1"
    log_info "Searching for: $query"
    pass find "$query"
}

# Generate password
generate_password() {
    local length="${1:-16}"
    openssl rand -base64 "$length"
}

# Backup password store
backup_passwords() {
    local backup_dir="${1:-$HOME/password_backup_$(date +%Y%m%d)}"

    log_info "Creating password backup..."

    # Get the first available GPG key ID
    local gpg_key
    gpg_key=$(gpg --list-keys --with-colons | grep '^pub' | head -n1 | cut -d: -f5)

    if [[ -z "$gpg_key" ]]; then
        log_error "No GPG keys found. Please initialize password store first."
        return 1
    fi

    mkdir -p "$backup_dir"
    cp -r "$PASSWORD_STORE" "$backup_dir/"
    cp -r "$HOME/.gnupg" "$backup_dir/"

    # Encrypt backup
    tar czf - "$backup_dir" | gpg --encrypt --recipient "$gpg_key" > "${backup_dir}.tar.gz.gpg"

    rm -rf "$backup_dir"
    log_success "Password backup created: ${backup_dir}.tar.gz.gpg"
}

# Android password operations
android_add_password() {
    local name="$1"
    local password="${2:-}"

    if [[ -z "$password" ]]; then
        password=$(generate_password)
    fi

    # Escape single quotes in password for shell
    local escaped_password
    escaped_password=$(printf '%q' "$password")

    android_ssh "echo '$escaped_password' | pass insert -m '$name'"
    log_success "Password added on Android: $name"

    # Sync back to Codespaces
    sync_from_android
}

android_get_password() {
    local name="$1"
    android_ssh "pass '$name'"
}

android_list_passwords() {
    log_info "Android password store contents:"
    android_ssh "pass"
}

# Show menu
show_menu() {
    echo "=== Android Password Keeper ==="
    echo "Android: $TERMUX_USER@$TERMUX_IP:8022"
    echo
    echo "Local Operations:"
    echo "1. Initialize Password Store"
    echo "2. Add Password"
    echo "3. Get Password"
    echo "4. List Passwords"
    echo "5. Search Passwords"
    echo "6. Generate Password"
    echo "7. Backup Passwords"
    echo
    echo "Android Operations:"
    echo "8. Sync to Android"
    echo "9. Sync from Android"
    echo "10. Add Password (Android)"
    echo "11. Get Password (Android)"
    echo "12. List Passwords (Android)"
    echo
    echo "13. Exit"
    echo
}

# Main menu loop
main_menu() {
    while true; do
        show_menu
        read -rp "Select option (1-13): " choice

        case $choice in
            1) init_password_store ;;
            2)
                read -rp "Password name: " name
                read -rp "Password (leave empty to generate): " password
                add_password "$name" "$password"
                ;;
            3)
                read -rp "Password name: " name
                get_password "$name"
                ;;
            4) list_passwords ;;
            5)
                read -rp "Search query: " query
                search_passwords "$query"
                ;;
            6)
                read -rp "Password length (default 16): " length
                length="${length:-16}"
                echo "Generated password: $(generate_password "$length")"
                ;;
            7)
                read -rp "Backup directory (default: auto): " backup_dir
                backup_passwords "$backup_dir"
                ;;
            8) sync_to_android ;;
            9) sync_from_android ;;
            10)
                read -rp "Password name: " name
                read -rp "Password (leave empty to generate): " password
                android_add_password "$name" "$password"
                ;;
            11)
                read -rp "Password name: " name
                android_get_password "$name"
                ;;
            12) android_list_passwords ;;
            13) log_info "Exiting..."; exit 0 ;;
            *) log_error "Invalid option" ;;
        esac

        echo
        read -rp "Press Enter to continue..."
        clear
    done
}

# Command line interface
case "${1:-menu}" in
    init) init_password_store ;;
    add)
        shift
        add_password "$1" "${2:-}"
        ;;
    get) get_password "$2" ;;
    list) list_passwords ;;
    search) search_passwords "$2" ;;
    generate) generate_password "${2:-16}" ;;
    backup) backup_passwords "${2:-}" ;;
    sync-to) sync_to_android ;;
    sync-from) sync_from_android ;;
    android-add)
        shift
        android_add_password "$1" "${2:-}"
        ;;
    android-get) android_get_password "$2" ;;
    android-list) android_list_passwords ;;
    menu) check_config && main_menu ;;
    *)
        echo "Usage: $0 [init|add|get|list|search|generate|backup|sync-to|sync-from|android-add|android-get|android-list|menu]"
        echo "  init              - Initialize password store"
        echo "  add <name> [pass] - Add password (generate if not provided)"
        echo "  get <name>        - Get password"
        echo "  list              - List all passwords"
        echo "  search <query>    - Search passwords"
        echo "  generate [len]    - Generate random password"
        echo "  backup [dir]      - Backup password store"
        echo "  sync-to           - Sync passwords to Android"
        echo "  sync-from         - Sync passwords from Android"
        echo "  android-add <name> [pass] - Add password on Android"
        echo "  android-get <name> - Get password from Android"
        echo "  android-list      - List passwords on Android"
        echo "  menu              - Interactive menu (default)"
        exit 1
        ;;
esac
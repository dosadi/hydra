#!/usr/bin/env bash
# Laptop Remote Administration Client
# Connect to and administer your laptop from GitHub Codespaces

set -euo pipefail

# Configuration - Update these with your laptop details
LAPTOP_IP="${LAPTOP_IP:-}"
LAPTOP_USER="${LAPTOP_USER:-$(whoami)}"
LAPTOP_SSH_PORT="${LAPTOP_SSH_PORT:-22}"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/id_ed25519}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[LAPTOP-ADMIN]${NC} $*" >&2; }
log_warn() { echo -e "${YELLOW}[LAPTOP-WARN]${NC} $*" >&2; }
log_error() { echo -e "${RED}[LAPTOP-ERROR]${NC} $*" >&2; }
log_success() { echo -e "${GREEN}[LAPTOP-SUCCESS]${NC} $*" >&2; }

# Check configuration
check_config() {
    if [[ -z "$LAPTOP_IP" ]]; then
        log_error "LAPTOP_IP not set. Please configure your laptop IP address."
        log_info "Run: export LAPTOP_IP='your.laptop.ip.address'"
        return 1
    fi

    if [[ ! -f "$SSH_KEY" ]]; then
        log_error "SSH key not found: $SSH_KEY"
        log_info "Please ensure SSH key exists or set SSH_KEY variable"
        return 1
    fi
}

# SSH command wrapper
ssh_cmd() {
    local cmd="$1"
    local quiet="${2:-false}"

    if [[ "$quiet" == "true" ]]; then
        ssh -i "$SSH_KEY" -p "$LAPTOP_SSH_PORT" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$LAPTOP_USER@$LAPTOP_IP" "$cmd" 2>/dev/null
    else
        ssh -i "$SSH_KEY" -p "$LAPTOP_SSH_PORT" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$LAPTOP_USER@$LAPTOP_IP" "$cmd"
    fi
}

# Test connection
test_connection() {
    log_info "Testing connection to laptop..."

    if ssh_cmd "echo 'Connection successful'" >/dev/null 2>&1; then
        log_success "SSH connection established"
        return 0
    else
        log_error "Cannot connect to laptop"
        log_info "Please check:"
        log_info "  - Laptop IP: $LAPTOP_IP"
        log_info "  - SSH service running on laptop"
        log_info "  - SSH key configured correctly"
        log_info "  - Firewall allows SSH connections"
        return 1
    fi
}

# Get laptop status
get_status() {
    log_info "Getting laptop status..."

    echo "=== Laptop Status ==="
    ssh_cmd "$HOME/.admin/status.sh" 2>/dev/null || {
        log_warn "Admin scripts not found on laptop"
        log_info "Basic system info:"
        ssh_cmd "hostname && uptime && free -h | head -2 && df -h / | tail -1"
    }
}

# Monitor laptop
monitor_laptop() {
    log_info "Monitoring laptop..."

    ssh_cmd "$HOME/.admin/monitor_laptop.sh" 2>/dev/null || {
        log_warn "Monitor script not available"
        log_info "Running basic monitoring..."
        ssh_cmd "
            echo '=== Basic Monitor ==='
            echo \"Time: \$(date)\"
            echo \"Load: \$(uptime | awk -F'load average:' '{ print \$2 }')\"
            echo \"Memory: \$(free -h | grep Mem | awk '{print \$3\"/\"\$2}')\"
            echo \"Disk: \$(df -h / | tail -1 | awk '{print \$3\"/\"\$2\" (\"\$5\")\"}')\"
            echo \"Processes: \$(ps aux | wc -l) total\"
            echo \"Top CPU processes:\"
            ps aux --sort=-%cpu | head -5 | awk '{print \$1,\$3,\$11}'
        "
    }
}

# Execute command on laptop
run_command() {
    local cmd="$1"

    log_info "Executing on laptop: $cmd"
    ssh_cmd "$cmd"
}

# File operations
sync_files() {
    local source="$1"
    local dest="${2:-.}"

    log_info "Syncing files from laptop: $source -> $dest"

    if [[ -d "$source" ]]; then
        rsync -avz -e "ssh -i $SSH_KEY -p $LAPTOP_SSH_PORT -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" "$LAPTOP_USER@$LAPTOP_IP:$source" "$dest/"
    else
        scp -i "$SSH_KEY" -P "$LAPTOP_SSH_PORT" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$LAPTOP_USER@$LAPTOP_IP:$source" "$dest/"
    fi

    log_success "File sync complete"
}

# Install software on laptop
install_software() {
    local package="$1"

    log_info "Installing $package on laptop..."

    # Detect OS and use appropriate package manager
    local os
    os=$(ssh_cmd "uname -a" 2>/dev/null | tr '[:upper:]' '[:lower:]' || echo "unknown")

    if echo "$os" | grep -q "ubuntu\|debian"; then
        ssh_cmd "sudo apt update && sudo apt install -y $package"
    elif echo "$os" | grep -q "centos\|rhel\|fedora"; then
        ssh_cmd "sudo dnf install -y $package"
    elif echo "$os" | grep -q "darwin"; then
        ssh_cmd "brew install $package"
    else
        log_error "Unsupported OS for automatic installation"
        return 1
    fi

    log_success "Package installed: $package"
}

# System maintenance
system_maintenance() {
    log_info "Running system maintenance on laptop..."

    ssh_cmd "
        echo '=== System Maintenance ==='
        echo 'Updating package lists...'
        if command -v apt >/dev/null; then
            sudo apt update
        elif command -v dnf >/dev/null; then
            sudo dnf check-update
        elif command -v brew >/dev/null; then
            brew update
        fi

        echo 'Cleaning package cache...'
        if command -v apt >/dev/null; then
            sudo apt autoremove -y && sudo apt autoclean
        elif command -v dnf >/dev/null; then
            sudo dnf autoremove -y
        fi

        echo 'Checking disk usage...'
        df -h

        echo 'Maintenance complete'
    "
}

# Interactive shell
interactive_shell() {
    log_info "Starting interactive shell on laptop..."
    log_info "Type 'exit' to return to Codespaces"

    ssh -i "$SSH_KEY" -p "$LAPTOP_SSH_PORT" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$LAPTOP_USER@$LAPTOP_IP"
}

# Setup laptop (if not already done)
setup_laptop() {
    log_info "Setting up laptop for administration..."

    # Copy setup script to laptop
    scp -i "$SSH_KEY" -P "$LAPTOP_SSH_PORT" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        "/workspaces/hydra/scripts/setup_laptop_admin.sh" \
        "$LAPTOP_USER@$LAPTOP_IP:/tmp/"

    # Run setup script on laptop
    ssh_cmd "chmod +x /tmp/setup_laptop_admin.sh && /tmp/setup_laptop_admin.sh"

    log_success "Laptop setup complete"
}

# Show menu
show_menu() {
    echo "=== Laptop Remote Administration ==="
    echo "Laptop: $LAPTOP_USER@$LAPTOP_IP:$LAPTOP_SSH_PORT"
    echo
    echo "1. Test Connection"
    echo "2. Get Status"
    echo "3. Monitor System"
    echo "4. Run Command"
    echo "5. Sync Files"
    echo "6. Install Software"
    echo "7. System Maintenance"
    echo "8. Interactive Shell"
    echo "9. Setup Laptop"
    echo "10. Exit"
    echo
}

# Main menu loop
main_menu() {
    while true; do
        show_menu
        read -rp "Select option (1-10): " choice

        case $choice in
            1) test_connection ;;
            2) get_status ;;
            3) monitor_laptop ;;
            4)
                read -rp "Enter command to run: " cmd
                run_command "$cmd"
                ;;
            5)
                read -rp "Source path on laptop: " source
                read -rp "Destination on Codespaces (default: .): " dest
                dest="${dest:-.}"
                sync_files "$source" "$dest"
                ;;
            6)
                read -rp "Package to install: " package
                install_software "$package"
                ;;
            7) system_maintenance ;;
            8) interactive_shell ;;
            9) setup_laptop ;;
            10) log_info "Exiting..."; exit 0 ;;
            *) log_error "Invalid option" ;;
        esac

        echo
        read -rp "Press Enter to continue..."
        clear
    done
}

# Command line interface
case "${1:-menu}" in
    test) check_config && test_connection ;;
    status) check_config && get_status ;;
    monitor) check_config && monitor_laptop ;;
    cmd)
        check_config
        shift
        run_command "$*"
        ;;
    sync)
        check_config
        sync_files "$2" "$3"
        ;;
    install)
        check_config
        install_software "$2"
        ;;
    setup) check_config && setup_laptop ;;
    shell) check_config && interactive_shell ;;
    menu) check_config && main_menu ;;
    *)
        echo "Usage: $0 [test|status|monitor|cmd|sync|install|setup|shell|menu]"
        echo "  test          - Test SSH connection"
        echo "  status        - Get laptop status"
        echo "  monitor       - Run system monitoring"
        echo "  cmd <command> - Execute command on laptop"
        echo "  sync <src> [dest] - Sync files from laptop"
        echo "  install <pkg> - Install software on laptop"
        echo "  setup         - Setup laptop for administration"
        echo "  shell         - Start interactive shell"
        echo "  menu          - Interactive menu (default)"
        exit 1
        ;;
esac
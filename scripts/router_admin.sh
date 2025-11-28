#!/usr/bin/env bash
# Router Remote Administration Client
# Connect to and administer your router from GitHub Codespaces

set -euo pipefail

# Configuration - Update these with your router details
ROUTER_IP="${ROUTER_IP:-}"
ROUTER_USER="${ROUTER_USER:-admin}"
ROUTER_SSH_PORT="${ROUTER_SSH_PORT:-22}"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/id_ed25519}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[ROUTER-ADMIN]${NC} $*" >&2; }
log_warn() { echo -e "${YELLOW}[ROUTER-WARN]${NC} $*" >&2; }
log_error() { echo -e "${RED}[ROUTER-ERROR]${NC} $*" >&2; }
log_success() { echo -e "${GREEN}[ROUTER-SUCCESS]${NC} $*" >&2; }

# Check configuration
check_config() {
    if [[ -z "$ROUTER_IP" ]]; then
        log_error "ROUTER_IP not set. Please configure your router IP address."
        log_info "Run: export ROUTER_IP='your.router.ip.address'"
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
        ssh -i "$SSH_KEY" -p "$ROUTER_SSH_PORT" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$ROUTER_USER@$ROUTER_IP" "$cmd" 2>/dev/null
    else
        ssh -i "$SSH_KEY" -p "$ROUTER_SSH_PORT" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$ROUTER_USER@$ROUTER_IP" "$cmd"
    fi
}

# Test connection
test_connection() {
    log_info "Testing connection to router..."

    if ssh_cmd "echo 'Connection successful'" >/dev/null 2>&1; then
        log_success "SSH connection established"
        return 0
    else
        log_error "Cannot connect to router"
        log_info "Please check:"
        log_info "  - Router IP: $ROUTER_IP"
        log_info "  - SSH service running on router"
        log_info "  - SSH key configured correctly"
        log_info "  - Router allows SSH connections"
        return 1
    fi
}

# Get router status
get_status() {
    log_info "Getting router status..."

    echo "=== Router Status ==="
    ssh_cmd "
        echo 'Host: $(hostname)'
        echo 'Uptime: $(uptime)'
        echo 'Load: $(uptime | awk -F\"load average:\" '{ print \$2 }')'
        echo 'Memory: $(free -h 2>/dev/null | head -2 || echo \"Memory info unavailable\")'
        echo 'Firmware: $(cat /etc/openwrt_release 2>/dev/null | grep DISTRIB_DESCRIPTION | cut -d\"'\" -f2 || uname -a)'
    " 2>/dev/null || {
        log_warn "Unable to get detailed status"
        ssh_cmd "uname -a && uptime"
    }
}

# Monitor router
monitor_router() {
    log_info "Monitoring router..."

    ssh_cmd "
        echo '=== Router Monitor ==='
        echo \"Time: \$(date)\"
        echo \"Load: \$(uptime | awk -F\"load average:\" '{ print \$2 }')\"
        echo \"Memory: \$(free -h 2>/dev/null | grep Mem | awk '{print \$3\"/\"\$2}' || echo 'N/A')\"
        echo \"Processes: \$(ps | wc -l) total\"
        echo ''
        echo '=== Network Interfaces ==='
        ifconfig 2>/dev/null | grep -E '(inet |Link encap)' | head -10 || ip addr show | grep -E '(inet |link/)' | head -10
        echo ''
        echo '=== Routing Table ==='
        route -n 2>/dev/null | head -10 || ip route show | head -10
        echo ''
        echo '=== Connected Clients ==='
        arp -a 2>/dev/null | wc -l | xargs echo 'ARP entries:' || echo 'ARP table unavailable'
    " 2>/dev/null || {
        log_warn "Monitor script not available"
        log_info "Running basic monitoring..."
        ssh_cmd "
            echo '=== Basic Router Monitor ==='
            echo \"Time: \$(date)\"
            echo \"Load: \$(uptime | awk -F\"load average:\" '{ print \$2 }')\"
            echo \"Processes: \$(ps | wc -l) total\"
        "
    }
}

# Get network info
get_network_info() {
    log_info "Getting network information..."

    ssh_cmd "
        echo '=== Network Configuration ==='
        echo 'Interfaces:'
        ifconfig 2>/dev/null | grep -E '^[^ ]' | cut -d' ' -f1 || ip link show | grep -E '^[0-9]+:' | cut -d' ' -f2 | tr -d ':'
        echo ''
        echo 'IP Addresses:'
        ifconfig 2>/dev/null | grep 'inet ' | awk '{print \$2}' | cut -d: -f2 || ip addr show | grep 'inet ' | awk '{print \$2}'
        echo ''
        echo 'DNS Servers:'
        cat /etc/resolv.conf 2>/dev/null | grep nameserver | awk '{print \$2}' || echo 'DNS config unavailable'
        echo ''
        echo 'DHCP Leases:'
        cat /tmp/dhcp.leases 2>/dev/null | wc -l | xargs echo 'Active leases:' || echo 'DHCP info unavailable'
    " 2>/dev/null || log_warn "Network info unavailable"
}

# Check firewall
check_firewall() {
    log_info "Checking firewall configuration..."

    ssh_cmd "
        echo '=== Firewall Status ==='
        if command -v uci >/dev/null 2>&1; then
            echo 'OpenWrt Firewall:'
            uci show firewall 2>/dev/null | grep -E '(name|src|dest)' | head -10 || echo 'UCI unavailable'
        elif command -v iptables >/dev/null 2>&1; then
            echo 'IPTables Rules:'
            iptables -L -n | head -20
        else
            echo 'Firewall tools not found'
        fi
    " 2>/dev/null || log_warn "Firewall check unavailable"
}

# Get wireless info
get_wireless_info() {
    log_info "Getting wireless information..."

    ssh_cmd "
        echo '=== Wireless Configuration ==='
        if command -v iwinfo >/dev/null 2>&1; then
            iwinfo 2>/dev/null || echo 'No wireless interfaces'
        elif command -v iw >/dev/null 2>&1; then
            iw dev 2>/dev/null || echo 'Wireless tools limited'
        else
            echo 'Wireless info unavailable'
        fi
        echo ''
        echo 'WiFi Clients:'
        if command -v wl >/dev/null 2>&1; then
            wl assoclist 2>/dev/null | wc -l | xargs echo 'Associated clients:' || echo 'Client info unavailable'
        else
            echo 'Client count unavailable'
        fi
    " 2>/dev/null || log_warn "Wireless info unavailable"
}

# Run command
run_command() {
    local cmd="$1"
    log_info "Running command: $cmd"
    ssh_cmd "$cmd"
}

# Sync files
sync_files() {
    local source="$1"
    local dest="${2:-.}"
    log_info "Syncing $source from router to $dest"

    scp -i "$SSH_KEY" -P "$ROUTER_SSH_PORT" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        "$ROUTER_USER@$ROUTER_IP:$source" "$dest"
}

# Install software
install_software() {
    local package="$1"
    log_info "Installing $package on router..."

    ssh_cmd "
        if command -v opkg >/dev/null 2>&1; then
            opkg update && opkg install $package
        elif command -v apt >/dev/null 2>&1; then
            apt update && apt install -y $package
        else
            echo 'Package manager not found. Manual installation required.'
            exit 1
        fi
    "
}

# System maintenance
system_maintenance() {
    log_info "Running system maintenance..."

    ssh_cmd "
        echo '=== System Maintenance ==='
        echo 'Updating package lists...'
        if command -v opkg >/dev/null 2>&1; then
            opkg update
        elif command -v apt >/dev/null 2>&1; then
            apt update
        fi
        echo 'Cleaning up...'
        if command -v opkg >/dev/null 2>&1; then
            opkg list-upgradable | wc -l | xargs echo 'Upgradable packages:'
        fi
        echo 'Log rotation...'
        logrotate /etc/logrotate.conf 2>/dev/null || echo 'Log rotation not configured'
        echo 'Maintenance complete'
    "
}

# Interactive shell
interactive_shell() {
    log_info "Starting interactive shell on router..."
    ssh -i "$SSH_KEY" -p "$ROUTER_SSH_PORT" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        "$ROUTER_USER@$ROUTER_IP"
}

# Setup router
setup_router() {
    log_info "Setting up router for administration..."

    ssh_cmd "
        echo '=== Router Setup ==='
        echo 'Checking SSH access...'
        echo 'Installing monitoring tools...'
        if command -v opkg >/dev/null 2>&1; then
            opkg update
            opkg install procps-ng-ps htop 2>/dev/null || echo 'Some tools not available'
        fi
        echo 'Creating admin directory...'
        mkdir -p ~/.router_admin
        echo 'Setup complete'
    "
}

# Show menu
show_menu() {
    echo "=== Router Remote Administration ==="
    echo "Router: $ROUTER_USER@$ROUTER_IP:$ROUTER_SSH_PORT"
    echo
    echo "1. Test Connection"
    echo "2. Get Status"
    echo "3. Monitor System"
    echo "4. Network Information"
    echo "5. Check Firewall"
    echo "6. Wireless Information"
    echo "7. Run Command"
    echo "8. Sync Files"
    echo "9. Install Software"
    echo "10. System Maintenance"
    echo "11. Interactive Shell"
    echo "12. Setup Router"
    echo "13. Exit"
    echo
}

# Main menu loop
main_menu() {
    while true; do
        show_menu
        read -rp "Select option (1-13): " choice

        case $choice in
            1) test_connection ;;
            2) get_status ;;
            3) monitor_router ;;
            4) get_network_info ;;
            5) check_firewall ;;
            6) get_wireless_info ;;
            7)
                read -rp "Enter command to run: " cmd
                run_command "$cmd"
                ;;
            8)
                read -rp "Source path on router: " source
                read -rp "Destination on Codespaces (default: .): " dest
                dest="${dest:-.}"
                sync_files "$source" "$dest"
                ;;
            9)
                read -rp "Package to install: " package
                install_software "$package"
                ;;
            10) system_maintenance ;;
            11) interactive_shell ;;
            12) setup_router ;;
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
    test) check_config && test_connection ;;
    status) check_config && get_status ;;
    monitor) check_config && monitor_router ;;
    network) check_config && get_network_info ;;
    firewall) check_config && check_firewall ;;
    wireless) check_config && get_wireless_info ;;
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
    maintenance) check_config && system_maintenance ;;
    setup) check_config && setup_router ;;
    shell) check_config && interactive_shell ;;
    menu) check_config && main_menu ;;
    *)
        echo "Usage: $0 [test|status|monitor|network|firewall|wireless|cmd|sync|install|maintenance|setup|shell|menu]"
        echo "  test          - Test SSH connection"
        echo "  status        - Get router status"
        echo "  monitor       - Run system monitoring"
        echo "  network       - Get network information"
        echo "  firewall      - Check firewall configuration"
        echo "  wireless      - Get wireless information"
        echo "  cmd <command> - Execute command on router"
        echo "  sync <src> [dest] - Sync files from router"
        echo "  install <pkg> - Install software on router"
        echo "  maintenance   - Run system maintenance"
        echo "  setup         - Setup router for administration"
        echo "  shell         - Start interactive shell"
        echo "  menu          - Interactive menu (default)"
        exit 1
        ;;
esac
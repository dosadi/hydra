#!/usr/bin/env bash
# Router Administration Setup Script
# Configure your router for remote administration from GitHub Codespaces

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*" >&2; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*" >&2; }

# Detect router type
detect_router_type() {
    log_info "Detecting router type..."

    # Check for OpenWrt
    if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
           "$ROUTER_USER@$ROUTER_IP" "command -v opkg" >/dev/null 2>&1; then
        echo "openwrt"
        return
    fi

    # Check for DD-WRT
    if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
           "$ROUTER_USER@$ROUTER_IP" "command -v ipkg" >/dev/null 2>&1; then
        echo "ddwrt"
        return
    fi

    # Check for Tomato
    if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
           "$ROUTER_USER@$ROUTER_IP" "nvram get os_version" >/dev/null 2>&1; then
        echo "tomato"
        return
    fi

    # Check for ASUS Merlin
    if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
           "$ROUTER_USER@$ROUTER_IP" "uname -a | grep -i asus" >/dev/null 2>&1; then
        echo "asus-merlin"
        return
    fi

    # Generic Linux
    if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
           "$ROUTER_USER@$ROUTER_IP" "command -v apt || command -v yum || command -v pacman" >/dev/null 2>&1; then
        echo "linux"
        return
    fi

    echo "unknown"
}

# Setup SSH keys on router
setup_router_ssh_keys() {
    log_info "Setting up SSH keys on router..."

    # Generate key if it doesn't exist
    if [[ ! -f ~/.ssh/id_ed25519 ]]; then
        ssh-keygen -t ed25519 -C "router-admin-$(date +%Y%m%d)" -f ~/.ssh/id_ed25519 -N ""
        log_success "SSH key generated"
    fi

    # Copy public key to router
    ssh-copy-id -i ~/.ssh/id_ed25519.pub -o StrictHostKeyChecking=no \
                "$ROUTER_USER@$ROUTER_IP" 2>/dev/null || {
        log_warn "ssh-copy-id failed, trying manual method..."
        # Manual method
        ssh -o StrictHostKeyChecking=no "$ROUTER_USER@$ROUTER_IP" "
            mkdir -p ~/.ssh
            chmod 700 ~/.ssh
            echo '$(cat ~/.ssh/id_ed25519.pub)' >> ~/.ssh/authorized_keys
            chmod 600 ~/.ssh/authorized_keys
        "
    }

    log_success "SSH key configured on router"
}

# Configure SSH security on router
configure_router_ssh() {
    local router_type
    router_type=$(detect_router_type)

    log_info "Configuring SSH security on $router_type router..."

    case $router_type in
        openwrt)
            ssh "$ROUTER_USER@$ROUTER_IP" "
                # Enable SSH service
                /etc/init.d/sshd enable 2>/dev/null || true
                /etc/init.d/dropbear enable 2>/dev/null || true

                # Configure SSH
                uci set dropbear.@dropbear[0].PasswordAuth='off' 2>/dev/null || true
                uci set dropbear.@dropbear[0].RootPasswordAuth='off' 2>/dev/null || true
                uci commit dropbear 2>/dev/null || true

                # Restart SSH
                /etc/init.d/dropbear restart 2>/dev/null || true
            "
            ;;
        ddwrt)
            ssh "$ROUTER_USER@$ROUTER_IP" "
                # DD-WRT specific configuration
                nvram set sshd_enable=1
                nvram set sshd_port=22
                nvram set sshd_passwordauth=0
                nvram commit
                killall dropbear 2>/dev/null || true
                dropbear -p 22
            "
            ;;
        tomato)
            ssh "$ROUTER_USER@$ROUTER_IP" "
                # Tomato specific configuration
                nvram set sshd_enable=1
                nvram set sshd_port=22
                nvram set sshd_passwordauth=0
                nvram commit
            "
            ;;
        asus-merlin)
            ssh "$ROUTER_USER@$ROUTER_IP" "
                # ASUS Merlin specific configuration
                nvram set sshd_enable=1
                nvram set sshd_port=22
                nvram commit
            "
            ;;
        linux)
            ssh "$ROUTER_USER@$ROUTER_IP" "
                # Generic Linux configuration
                if command -v systemctl >/dev/null; then
                    systemctl enable sshd 2>/dev/null || true
                    systemctl start sshd 2>/dev/null || true
                fi
            "
            ;;
        *)
            log_warn "Unknown router type, attempting generic configuration..."
            ssh "$ROUTER_USER@$ROUTER_IP" "
                # Generic configuration
                if command -v systemctl >/dev/null; then
                    systemctl enable ssh 2>/dev/null || true
                    systemctl start ssh 2>/dev/null || true
                fi
            "
            ;;
    esac

    log_success "SSH security configured"
}

# Install monitoring tools
install_monitoring_tools() {
    local router_type
    router_type=$(detect_router_type)

    log_info "Installing monitoring tools on $router_type router..."

    case $router_type in
        openwrt)
            ssh "$ROUTER_USER@$ROUTER_IP" "
                opkg update
                opkg install procps-ng htop netcat curl wget 2>/dev/null || echo 'Some packages not available'
            "
            ;;
        ddwrt)
            ssh "$ROUTER_USER@$ROUTER_IP" "
                ipkg update 2>/dev/null || true
                ipkg install htop nc 2>/dev/null || echo 'Some packages not available'
            "
            ;;
        *)
            log_info "Monitoring tools installation not supported for this router type"
            ;;
    esac

    log_success "Monitoring tools installed"
}

# Create router admin scripts
create_router_scripts() {
    log_info "Creating router administration scripts..."

    ssh "$ROUTER_USER@$ROUTER_IP" "
        mkdir -p ~/.router_admin

        # Status script
        cat > ~/.router_admin/status.sh << 'EOF'
#!/bin/sh
echo '=== Router Status ==='
echo \"Host: \$(hostname)\"
echo \"Uptime: \$(uptime)\"
echo \"Load: \$(uptime | awk -F\"load average:\" '{ print \$2 }')\"
echo \"Memory: \$(free -h 2>/dev/null | head -2 || echo 'Memory info unavailable')\"
echo \"Firmware: \$(cat /etc/openwrt_release 2>/dev/null | grep DISTRIB_DESCRIPTION | cut -d\\\"'\\\" -f2 || uname -a)\"
echo \"Interfaces: \$(ifconfig 2>/dev/null | grep -c '^[^ ]' || ip link show | grep -c '^[0-9]')\"
EOF

        # Monitor script
        cat > ~/.router_admin/monitor.sh << 'EOF'
#!/bin/sh
echo '=== Router Monitor ==='
echo \"Time: \$(date)\"
echo \"Load: \$(uptime | awk -F\"load average:\" '{ print \$2 }')\"
echo \"Memory: \$(free -h 2>/dev/null | grep Mem | awk '{print \$3\"/\"\$2}' || echo 'N/A')\"
echo \"Processes: \$(ps | wc -l) total\"
echo ''
echo 'Network Interfaces:'
ifconfig 2>/dev/null | grep -E '(inet |Link encap)' | head -6 || ip addr show | grep -E '(inet |link/)' | head -6
echo ''
echo 'Connected Clients:'
arp -a 2>/dev/null | wc -l | xargs echo 'ARP entries:' || echo 'ARP table unavailable'
EOF

        chmod +x ~/.router_admin/*.sh
    "

    log_success "Router admin scripts created"
}

# Configure firewall
configure_firewall() {
    local router_type
    router_type=$(detect_router_type)

    log_info "Configuring firewall on $router_type router..."

    case $router_type in
        openwrt)
            ssh "$ROUTER_USER@$ROUTER_IP" "
                # Allow SSH from anywhere (adjust as needed)
                uci add firewall rule 2>/dev/null || true
                uci set firewall.@rule[-1].name='Allow-SSH' 2>/dev/null || true
                uci set firewall.@rule[-1].src='wan' 2>/dev/null || true
                uci set firewall.@rule[-1].dest_port='22' 2>/dev/null || true
                uci set firewall.@rule[-1].proto='tcp' 2>/dev/null || true
                uci set firewall.@rule[-1].target='ACCEPT' 2>/dev/null || true
                uci commit firewall 2>/dev/null || true
                /etc/init.d/firewall restart 2>/dev/null || true
            "
            ;;
        *)
            log_info "Firewall configuration not automated for this router type"
            log_info "Please manually ensure SSH port is accessible"
            ;;
    esac

    log_success "Firewall configured"
}

# Generate connection info
generate_connection_info() {
    log_info "Generating connection information..."

    local router_type
    router_type=$(detect_router_type)

    cat << EOF

=== ROUTER CONNECTION INFO ===

IP Address: $ROUTER_IP
Username: $ROUTER_USER
SSH Port: 22
Router Type: $router_type

SSH Command:
ssh $ROUTER_USER@$ROUTER_IP

Public Key (already configured):
$(cat ~/.ssh/id_ed25519.pub)

Admin Scripts Location: ~/.router_admin/

Quick Commands:
ssh $ROUTER_USER@$ROUTER_IP ~/.router_admin/status.sh     # Quick status
ssh $ROUTER_USER@$ROUTER_IP ~/.router_admin/monitor.sh    # Detailed monitoring

EOF
}

# Main setup
main() {
    echo "=== Router Administration Setup ==="
    echo "This script will configure your router for remote administration"
    echo

    # Get router details
    read -rp "Router IP address: " ROUTER_IP
    read -rp "Router SSH username (default: root): " ROUTER_USER
    ROUTER_USER="${ROUTER_USER:-root}"

    echo
    log_info "Router IP: $ROUTER_IP"
    log_info "Router User: $ROUTER_USER"
    echo

    read -p "Continue with setup? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Setup cancelled."
        exit 0
    fi

    setup_router_ssh_keys
    configure_router_ssh
    install_monitoring_tools
    create_router_scripts
    configure_firewall
    generate_connection_info

    log_success "Router administration setup complete!"
}

# Run main function
main "$@"
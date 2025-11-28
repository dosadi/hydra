#!/usr/bin/env bash
# Laptop Administration Setup Script
# Configure your laptop for remote administration from GitHub Codespaces

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

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v lsb_release >/dev/null; then
            echo "$(lsb_release -si) $(lsb_release -sr)"
        elif [[ -f /etc/os-release ]]; then
            . /etc/os-release
            echo "$NAME $VERSION"
        else
            echo "Linux (unknown distribution)"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macOS $(sw_vers -productVersion)"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        echo "Windows"
    else
        echo "Unknown OS: $OSTYPE"
    fi
}

# Setup SSH Server
setup_ssh_server() {
    local os
    os=$(detect_os)

    log_info "Setting up SSH server on $os..."

    case $os in
        *"Ubuntu"*|*"Debian"*)
            log_info "Installing OpenSSH server..."
            sudo apt update
            sudo apt install -y openssh-server
            sudo systemctl enable ssh
            sudo systemctl start ssh
            ;;
        *"CentOS"*|*"RHEL"*|*"Fedora"*)
            log_info "Installing OpenSSH server..."
            sudo dnf install -y openssh-server
            sudo systemctl enable sshd
            sudo systemctl start sshd
            ;;
        *"macOS"*)
            log_info "Enabling remote login on macOS..."
            sudo systemsetup -setremotelogin on
            ;;
        *)
            log_error "Unsupported OS for automatic SSH setup: $os"
            log_info "Please manually install and configure SSH server"
            return 1
            ;;
    esac

    log_success "SSH server configured"
}

# Configure SSH
configure_ssh() {
    log_info "Configuring SSH security..."

    # Backup original config
    sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d_%H%M%S)

    # Configure SSH
    sudo tee -a /etc/ssh/sshd_config > /dev/null <<EOF

# Remote Administration Configuration
PermitRootLogin no
PasswordAuthentication yes
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
ChallengeResponseAuthentication no
UsePAM yes

# Security hardening
ClientAliveInterval 60
ClientAliveCountMax 3
MaxAuthTries 3
LoginGraceTime 30

# Allow specific users/groups
AllowUsers $(whoami)
EOF

    # Restart SSH service
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sudo launchctl unload /System/Library/LaunchDaemons/ssh.plist
        sudo launchctl load -w /System/Library/LaunchDaemons/ssh.plist
    else
        sudo systemctl restart sshd
    fi

    log_success "SSH configuration updated"
}

# Setup SSH keys
setup_ssh_keys() {
    log_info "Setting up SSH keys..."

    # Create .ssh directory if it doesn't exist
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh

    # Generate SSH key if it doesn't exist
    if [[ ! -f ~/.ssh/id_ed25519 ]]; then
        ssh-keygen -t ed25519 -C "laptop-admin-$(date +%Y%m%d)" -f ~/.ssh/id_ed25519 -N ""
        log_success "SSH key generated"
    else
        log_info "SSH key already exists"
    fi

    # Add key to authorized_keys
    if [[ ! -f ~/.ssh/authorized_keys ]]; then
        touch ~/.ssh/authorized_keys
    fi

    if ! grep -q "$(cat ~/.ssh/id_ed25519.pub)" ~/.ssh/authorized_keys 2>/dev/null; then
        cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys
        log_success "SSH key added to authorized_keys"
    fi

    chmod 600 ~/.ssh/authorized_keys

    log_info "Public key for remote access:"
    cat ~/.ssh/id_ed25519.pub
}

# Install monitoring tools
install_monitoring_tools() {
    local os
    os=$(detect_os)

    log_info "Installing monitoring tools on $os..."

    case $os in
        *"Ubuntu"*|*"Debian"*)
            sudo apt update
            sudo apt install -y htop iotop ncdu sysstat
            ;;
        *"CentOS"*|*"RHEL"*|*"Fedora"*)
            sudo dnf install -y htop iotop ncdu sysstat
            ;;
        *"macOS"*)
            if command -v brew >/dev/null; then
                brew install htop ncdu
            else
                log_warn "Homebrew not found. Please install monitoring tools manually"
            fi
            ;;
        *)
            log_warn "Please install monitoring tools manually: htop, iotop, ncdu, sysstat"
            ;;
    esac

    log_success "Monitoring tools installed"
}

# Setup firewall
setup_firewall() {
    local os
    os=$(detect_os)

    log_info "Configuring firewall on $os..."

    case $os in
        *"Ubuntu"*|*"Debian"*)
            sudo apt install -y ufw
            sudo ufw --force enable
            sudo ufw allow ssh
            sudo ufw allow 5900/tcp  # VNC if needed
            ;;
        *"CentOS"*|*"RHEL"*|*"Fedora"*)
            sudo dnf install -y firewalld
            sudo systemctl enable firewalld
            sudo systemctl start firewalld
            sudo firewall-cmd --permanent --add-service=ssh
            sudo firewall-cmd --permanent --add-port=5900/tcp
            sudo firewall-cmd --reload
            ;;
        *"macOS"*)
            log_info "macOS firewall is managed through System Preferences"
            ;;
        *)
            log_warn "Please configure firewall manually to allow SSH (port 22)"
            ;;
    esac

    log_success "Firewall configured"
}

# Create admin scripts
create_admin_scripts() {
    log_info "Creating laptop administration scripts..."

    local admin_dir="$HOME/.admin"
    mkdir -p "$admin_dir"

    # Laptop monitoring script
    cat > "$admin_dir/monitor_laptop.sh" << 'EOF'
#!/bin/bash
# Laptop monitoring script

LOG_FILE="$HOME/.admin/monitor_$(date +%Y%m%d).log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

check_system() {
    echo "=== System Health Check ==="
    echo "Date: $(date)"
    echo "Uptime: $(uptime)"
    echo "Load: $(uptime | awk -F'load average:' '{ print $2 }')"
    echo ""

    echo "=== CPU ==="
    if command -v mpstat >/dev/null; then
        mpstat 1 1 | tail -1
    else
        echo "CPU monitoring requires sysstat package"
    fi
    echo ""

    echo "=== Memory ==="
    free -h
    echo ""

    echo "=== Disk ==="
    df -h
    echo ""

    echo "=== Network ==="
    ip route show 2>/dev/null || netstat -rn 2>/dev/null || echo "Network info unavailable"
    echo ""

    echo "=== Processes ==="
    ps aux --sort=-%cpu | head -10
}

check_system | tee -a "$LOG_FILE"
EOF

    # Quick status script
    cat > "$admin_dir/status.sh" << 'EOF'
#!/bin/bash
echo "=== Laptop Status ==="
echo "Host: $(hostname)"
echo "User: $(whoami)"
echo "OS: $(uname -a)"
echo "IP: $(hostname -I 2>/dev/null || echo 'N/A')"
echo "SSH: $(pgrep -f sshd >/dev/null && echo 'Running' || echo 'Not running')"
echo "Firewall: $(ufw status 2>/dev/null | head -1 || echo 'Check manually')"
echo "Load: $(uptime | awk -F'load average:' '{ print $2 }')"
echo "Memory: $(free -h | grep Mem | awk '{print $3"/"$2}')"
echo "Disk: $(df -h / | tail -1 | awk '{print $3"/"$2" ("$5")"}')"
EOF

    chmod +x "$admin_dir"/*.sh

    log_success "Admin scripts created in $admin_dir"
}

# Generate connection info
generate_connection_info() {
    log_info "Generating connection information..."

    local ip
    ip=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "Check manually")

    local ssh_port=22
    if [[ "$OSTYPE" == "darwin"* ]]; then
        ssh_port=22  # macOS default
    fi

    cat << EOF

=== LAPTOP CONNECTION INFO ===

IP Address: $ip
SSH Port: $ssh_port
Username: $(whoami)

SSH Command:
ssh -p $ssh_port $(whoami)@$ip

Public Key (add to remote systems):
$(cat ~/.ssh/id_ed25519.pub)

Admin Scripts Location: $HOME/.admin/

Quick Commands:
$HOME/.admin/status.sh          # Quick system status
$HOME/.admin/monitor_laptop.sh  # Detailed monitoring

EOF
}

# Main setup
main() {
    echo "=== Laptop Administration Setup ==="
    echo "This script will configure your laptop for remote administration"
    echo "Detected OS: $(detect_os)"
    echo ""

    read -p "Continue with setup? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Setup cancelled."
        exit 0
    fi

    setup_ssh_server
    configure_ssh
    setup_ssh_keys
    install_monitoring_tools
    setup_firewall
    create_admin_scripts
    generate_connection_info

    log_success "Laptop administration setup complete!"
    log_info "Copy the connection info above to your GitHub Codespaces environment"
}

# Run main function
main "$@"
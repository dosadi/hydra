#!/usr/bin/env bash
# Hydra Codespaces Administration Suite
# Comprehensive remote administration for GitHub Codespaces environment

set -euo pipefail

# Configuration
CODESPACE_IP="10.0.10.154"
SSH_PORT="2222"
ADMIN_USER="codespace"
WORKSPACE="/workspaces/hydra"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Colors for notifications
BELL_NORMAL='\033[0;32m🔔\033[0m'    # Green bell - all good
BELL_WARNING='\033[0;33m🔔\033[0m'   # Yellow bell - warnings
BELL_ALERT='\033[0;31m🔔\033[0m'     # Red bell - alerts
BELL_INFO='\033[0;34m🔔\033[0m'      # Blue bell - info

NOTIFICATION_BELL="$BELL_NORMAL"
NOTIFICATION_MESSAGE=""

log_info() { echo -e "${BLUE}[INFO]${NC} $*" >&2; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*" >&2; }

# Get notification status
get_notification_status() {
    NOTIFICATION_BELL="$BELL_NORMAL"
    NOTIFICATION_MESSAGE=""

    local alerts=0
    local warnings=0

    # Check disk space
    local disk_usage
    disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    if [[ $disk_usage -gt 90 ]]; then
        alerts=$((alerts + 1))
        NOTIFICATION_MESSAGE+="Disk space critical! "
    elif [[ $disk_usage -gt 75 ]]; then
        warnings=$((warnings + 1))
        NOTIFICATION_MESSAGE+="Low disk space. "
    fi

    # Check memory usage
    local mem_usage
    mem_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}' 2>/dev/null || echo "50")
    if [[ $mem_usage -gt 90 ]]; then
        alerts=$((alerts + 1))
        NOTIFICATION_MESSAGE+="High memory usage! "
    elif [[ $mem_usage -gt 75 ]]; then
        warnings=$((warnings + 1))
        NOTIFICATION_MESSAGE+="Memory usage high. "
    fi

    # Check for running Docker containers
    if command -v docker >/dev/null 2>&1; then
        local container_count
        container_count=$(docker ps -q 2>/dev/null | wc -l)
        if [[ $container_count -gt 5 ]]; then
            warnings=$((warnings + 1))
            NOTIFICATION_MESSAGE+="Many containers running. "
        fi
    fi

    # Check SSH key status
    if [[ ! -f ~/.ssh/id_ed25519 ]]; then
        warnings=$((warnings + 1))
        NOTIFICATION_MESSAGE+="SSH key missing. "
    fi

    # Check for recent backups
    local backup_dir="${WORKSPACE:-/workspaces/hydra}/backups"
    if [[ -d "$backup_dir" ]]; then
        local latest_backup
        latest_backup=$(find "$backup_dir" -name "*.tar.gz" -mtime -7 2>/dev/null | wc -l)
        if [[ $latest_backup -eq 0 ]]; then
            warnings=$((warnings + 1))
            NOTIFICATION_MESSAGE+="No recent backup. "
        fi
    fi

    # Set bell color based on severity
    if [[ $alerts -gt 0 ]]; then
        NOTIFICATION_BELL="$BELL_ALERT"
    elif [[ $warnings -gt 0 ]]; then
        NOTIFICATION_BELL="$BELL_WARNING"
    else
        NOTIFICATION_BELL="$BELL_NORMAL"
    fi

    # Add message count if there are notifications
    if [[ -n "$NOTIFICATION_MESSAGE" ]]; then
        local total_notifications=$((alerts + warnings))
        NOTIFICATION_BELL="${NOTIFICATION_BELL}(${total_notifications})"
    fi
}

# System Health Check
check_system_health() {
    log_info "Checking system health..."

    # CPU and Memory
    echo "=== System Resources ==="
    echo "CPU Usage: $(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')"
    echo "Memory: $(free -h | grep Mem | awk '{print "Used: "$3"/"$2" ("int($3/$2*100)"%"}')"

    # Disk Usage
    echo "=== Disk Usage ==="
    df -h / | tail -1

    # Network
    echo "=== Network Status ==="
    echo "IP: $CODESPACE_IP"
    echo "SSH Port: $SSH_PORT"
    echo "Docker: $(docker --version 2>/dev/null && echo "Available" || echo "Not Available")"

    # Running Services
    echo "=== Key Services ==="
    systemctl is-active sshd 2>/dev/null && echo "SSH: Running" || echo "SSH: Not Running"
    systemctl is-active docker 2>/dev/null && echo "Docker: Running" || echo "Docker: Not Running"
}

# SSH Key Management
setup_ssh_keys() {
    log_info "Setting up SSH key management..."

    if [[ ! -f ~/.ssh/authorized_keys ]]; then
        touch ~/.ssh/authorized_keys
        chmod 600 ~/.ssh/authorized_keys
    fi

    # Add current key if not present
    if ! grep -q "codespace-admin" ~/.ssh/authorized_keys 2>/dev/null; then
        cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys
        log_success "SSH key added to authorized_keys"
    fi
}

# Docker Administration
docker_admin() {
    log_info "Docker administration..."

    echo "=== Docker Status ==="
    docker system info | head -10

    echo "=== Running Containers ==="
    docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"

    echo "=== Docker Networks ==="
    docker network ls

    echo "=== Docker Images ==="
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"
}

# Project Administration
project_admin() {
    log_info "Project administration..."

    cd "$WORKSPACE" || { log_error "Cannot access workspace"; return 1; }

    echo "=== Git Status ==="
    git status --porcelain | head -10 || echo "Not a git repository"

    echo "=== Build Status ==="
    if [[ -f Makefile ]]; then
        echo "Makefile present - checking build requirements..."
        make --dry-run 2>/dev/null | head -5 || echo "Build check failed"
    fi

    echo "=== Recent Commits ==="
    git log --oneline -3 2>/dev/null || echo "No git history"

    echo "=== Project Scripts ==="
    for script in scripts/*.{sh,py}; do
        [[ -f "$script" ]] && echo "${script#scripts/}" | head -5
    done
}

# Network Administration
network_admin() {
    log_info "Network administration..."

    echo "=== Network Interfaces ==="
    ip addr show | grep -E "(inet|link/ether)" | grep -v "127.0.0.1"

    echo "=== Routes ==="
    ip route show | head -5

    echo "=== Listening Ports ==="
    netstat -tlnp 2>/dev/null | grep LISTEN | head -5

    echo "=== Firewall Status ==="
    ufw status 2>/dev/null || echo "UFW not available"
}

# Security Check
security_check() {
    log_info "Security assessment..."

    echo "=== SSH Configuration ==="
    grep -E "^(PermitRootLogin|PasswordAuthentication|Port)" /etc/ssh/sshd_config 2>/dev/null || echo "SSH config check failed"

    echo "=== User Accounts ==="
    echo "Current user: $(whoami)"
    echo "Groups: $(groups)"

    echo "=== File Permissions ==="
    ls -la ~/.ssh/ 2>/dev/null || echo "SSH directory not found"

    echo "=== Sudo Access ==="
    sudo -n true 2>/dev/null && echo "Passwordless sudo: Available" || echo "Passwordless sudo: Not available"
}

# Backup and Recovery
backup_config() {
    log_info "Setting up backup configuration..."

    BACKUP_DIR="$WORKSPACE/backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"

    # Backup SSH keys
    cp -r ~/.ssh "$BACKUP_DIR/" 2>/dev/null && log_success "SSH keys backed up" || log_warn "SSH backup failed"

    # Backup project config
    cp -r "$WORKSPACE/.git" "$BACKUP_DIR/project_git" 2>/dev/null && log_success "Git config backed up" || log_warn "Git backup failed"

    echo "Backup created: $BACKUP_DIR"
}

# Laptop Administration
laptop_admin() {
    log_info "Laptop administration..."

    # Check if laptop config exists
    CONFIG_FILE="$HOME/.laptop_admin_config"
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_warn "Laptop not configured yet"
        echo "To set up laptop administration:"
        echo "1. Run: ./scripts/configure_laptop.sh setup"
        echo "2. Follow the prompts to configure your laptop connection"
        echo "3. Return here to administer your laptop"
        return
    fi

    # Source laptop config and run laptop admin
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
    if [[ -z "${LAPTOP_IP:-}" ]]; then
        log_error "Invalid laptop configuration"
        return
    fi

    echo "=== Laptop Administration ==="
    echo "Configured Laptop: ${LAPTOP_NAME:-Laptop} ($LAPTOP_USER@$LAPTOP_IP:$LAPTOP_SSH_PORT)"
    echo

    # Run laptop admin menu
    "$WORKSPACE/scripts/laptop_admin.sh" menu
}

# Router Administration
router_admin() {
    log_info "Router administration..."

    # Check if router config exists
    CONFIG_FILE="$HOME/.router_admin_config"
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_warn "Router not configured yet"
        echo "To set up router administration:"
        echo "1. Run: ./scripts/configure_router.sh"
        echo "2. Follow the prompts to configure your router connection"
        echo "3. Return here to administer your router"
        return
    fi

    # Source router config and run router admin
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
    if [[ -z "${ROUTER_IP:-}" ]]; then
        log_error "Invalid router configuration"
        return
    fi

    echo "=== Router Administration ==="
    echo "Configured Router: ${ROUTER_MODEL:-Router} ($ROUTER_USER@$ROUTER_IP:$ROUTER_SSH_PORT)"
    echo "Firmware: ${ROUTER_FIRMWARE:-Unknown}"
    echo

    # Run router admin menu
    "$WORKSPACE/scripts/router_admin.sh" menu
}

# Android Password Keeper
android_password_admin() {
    log_info "Android password keeper..."

    # Check if Android password config exists
    CONFIG_FILE="$HOME/.android_password_config"
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_warn "Android password keeper not configured yet"
        echo "To set up Android password management:"
        echo "1. Run: ./scripts/configure_android_password.sh"
        echo "2. Follow the prompts to configure your Android connection"
        echo "3. Return here to manage passwords"
        return
    fi

    # Source Android password config and run password keeper
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
    if [[ -z "${TERMUX_IP:-}" ]]; then
        log_error "Invalid Android password configuration"
        return
    fi

    echo "=== Android Password Keeper ==="
    echo "Android Device: $TERMUX_USER@$TERMUX_IP:8022"
    echo "Password Store: $PASSWORD_STORE"
    echo

    # Run Android password keeper menu
    "$WORKSPACE/scripts/android_password_keeper.sh" menu
}

# Chunk Processing Status
chunk_processing_status() {
    log_info "Chunk processing status..."

    if [[ ! -f "$WORKSPACE/scripts/chunk_dashboard.py" ]]; then
        log_error "Chunk dashboard script not found"
        return
    fi

    echo "=== External Chunk Processing Status ==="
    cd "$WORKSPACE" && python3 scripts/chunk_dashboard.py --status
}

# Show notification details
show_notifications() {
    log_info "System Notifications"

    if [[ -z "$NOTIFICATION_MESSAGE" ]]; then
        echo "✅ No active notifications - system is healthy!"
        return
    fi

    echo "Active Notifications:"
    echo "$NOTIFICATION_MESSAGE" | fold -s -w 60 | sed 's/^/  • /'
    echo
    echo "Recommendations:"
    echo "$NOTIFICATION_MESSAGE" | grep -q "Disk space" && echo "  • Free up disk space or expand storage"
    echo "$NOTIFICATION_MESSAGE" | grep -q "Memory" && echo "  • Close unused applications or increase RAM"
    echo "$NOTIFICATION_MESSAGE" | grep -q "containers" && echo "  • Stop unused Docker containers"
    echo "$NOTIFICATION_MESSAGE" | grep -q "SSH key" && echo "  • Run SSH Key Management to generate keys"
    echo "$NOTIFICATION_MESSAGE" | grep -q "backup" && echo "  • Run Backup Configuration to create backups"
}

# Main menu
show_menu() {
    # Get system status for notification bell
    get_notification_status

    echo "=== Hydra Codespaces Administration ==="
    echo "1. System Health Check"
    echo "2. SSH Key Management"
    echo "3. Docker Administration"
    echo "4. Project Administration"
    echo "5. Network Administration"
    echo "6. Security Check"
    echo "7. Backup Configuration"
    echo "8. Laptop Administration"
    echo "9. Router Administration"
    echo "10. Android Password Keeper"
    echo "11. Chunk Processing Status"
    echo "12. View Notifications"
    echo "13. Full System Report"
    echo "14. Exit"
    echo
    echo -e "\033[2K\r\033[60C$NOTIFICATION_BELL"
    echo
}

# Full system report
full_report() {
    log_info "Generating full system report..."

    REPORT_FILE="$WORKSPACE/admin_report_$(date +%Y%m%d_%H%M%S).txt"

    {
        echo "=== Hydra Codespaces Administration Report ==="
        echo "Generated: $(date)"
        echo "Host: $(hostname)"
        echo "User: $(whoami)"
        echo

        check_system_health
        echo
        docker_admin
        echo
        project_admin
        echo
        network_admin
        echo
        security_check

    } > "$REPORT_FILE"

    log_success "Report saved to: $REPORT_FILE"
}

# Main execution
main() {
    local choice

    while true; do
        show_menu
        read -rp "Select option (1-13): " choice

        case $choice in
            1) check_system_health ;;
            2) setup_ssh_keys ;;
            3) docker_admin ;;
            4) project_admin ;;
            5) network_admin ;;
            6) security_check ;;
            7) backup_config ;;
            8) laptop_admin ;;
            9) router_admin ;;
            10) android_password_admin ;;
            11) chunk_processing_status ;;
            12) show_notifications ;;
            13) full_report ;;
            14) log_info "Exiting..."; exit 0 ;;
            *) log_error "Invalid option" ;;
        esac

        echo
        read -rp "Press Enter to continue..."
        clear
    done
}

# Allow direct function calls
if [[ $# -gt 0 ]]; then
    case $1 in
        health) check_system_health ;;
        ssh) setup_ssh_keys ;;
        docker) docker_admin ;;
        project) project_admin ;;
        network) network_admin ;;
        security) security_check ;;
        backup) backup_config ;;
        laptop) laptop_admin ;;
        router) router_admin ;;
        password) android_password_admin ;;
        chunks) chunk_processing_status ;;
        notifications) get_notification_status && show_notifications ;;
        report) full_report ;;
        *) log_error "Unknown command: $1" ;;
    esac
else
    main
fi
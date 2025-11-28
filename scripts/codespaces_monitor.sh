#!/usr/bin/env bash
# Hydra Codespaces Monitoring Setup
# Automated monitoring and alerting for GitHub Codespaces environment

set -euo pipefail

WORKSPACE="/workspaces/hydra"
MONITOR_LOG="$WORKSPACE/logs/monitor_$(date +%Y%m%d).log"
ALERT_LOG="$WORKSPACE/logs/alerts_$(date +%Y%m%d).log"

mkdir -p "$WORKSPACE/logs"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$MONITOR_LOG"; }
alert() { echo -e "${RED}[ALERT $(date '+%Y-%m-%d %H:%M:%S')]${NC} $*" | tee -a "$ALERT_LOG"; }

# System Metrics
check_cpu() {
    local cpu_usage
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    log "CPU Usage: ${cpu_usage}%"

    if (( $(echo "$cpu_usage > 90" | bc -l) )); then
        alert "High CPU usage: ${cpu_usage}%"
    fi
}

check_memory() {
    local mem_usage
    mem_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
    log "Memory Usage: ${mem_usage}%"

    if (( mem_usage > 90 )); then
        alert "High memory usage: ${mem_usage}%"
    fi
}

check_disk() {
    local disk_usage
    disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    log "Disk Usage: ${disk_usage}%"

    if (( disk_usage > 90 )); then
        alert "High disk usage: ${disk_usage}%"
    fi
}

check_network() {
    local connections
    connections=$(netstat -tun 2>/dev/null | wc -l)
    log "Network Connections: $connections"

    if (( connections > 100 )); then
        alert "High network connections: $connections"
    fi
}

check_services() {
    # Check SSH
    if ! pgrep -f sshd >/dev/null; then
        alert "SSH service is not running"
    fi

    # Check Docker
    if ! pgrep -f dockerd >/dev/null; then
        alert "Docker service is not running"
    fi
}

check_project() {
    cd "$WORKSPACE" || return

    # Check for build errors
    if [[ -f "Makefile" ]]; then
        if ! make --dry-run >/dev/null 2>&1; then
            alert "Build system has errors"
        fi
    fi

    # Check git status
    if [[ -d ".git" ]]; then
        local changes
        changes=$(git status --porcelain | wc -l)
        log "Git changes: $changes"

        if (( changes > 10 )); then
            alert "Many uncommitted changes: $changes"
        fi
    fi
}

# Main monitoring loop
monitor_loop() {
    log "Starting monitoring loop..."

    while true; do
        check_cpu
        check_memory
        check_disk
        check_network
        check_services
        check_project

        sleep 300  # Check every 5 minutes
    done
}

# Generate report
generate_report() {
    local report_file="$WORKSPACE/reports/monitor_report_$(date +%Y%m%d_%H%M%S).txt"
    mkdir -p "$WORKSPACE/reports"

    {
        echo "=== Hydra Codespaces Monitor Report ==="
        echo "Generated: $(date)"
        echo "Uptime: $(uptime)"
        echo

        echo "=== System Resources ==="
        echo "CPU: $(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')"
        free -h | grep -E "^(Mem|Swap)"
        df -h /

        echo
        echo "=== Network ==="
        ip addr show eth0 | grep inet
        netstat -tlnp 2>/dev/null | grep LISTEN | wc -l
        echo " connections"

        echo
        echo "=== Services ==="
        systemctl is-active sshd 2>/dev/null && echo "SSH: Running" || echo "SSH: Stopped"
        systemctl is-active docker 2>/dev/null && echo "Docker: Running" || echo "Docker: Stopped"

        echo
        echo "=== Recent Alerts ==="
        tail -10 "$ALERT_LOG" 2>/dev/null || echo "No recent alerts"

    } > "$report_file"

    echo "Report generated: $report_file"
}

# Command line interface
case "${1:-monitor}" in
    monitor)
        monitor_loop
        ;;
    report)
        generate_report
        ;;
    check)
        check_cpu
        check_memory
        check_disk
        check_network
        check_services
        check_project
        echo "Health check completed. Check $MONITOR_LOG for details."
        ;;
    *)
        echo "Usage: $0 [monitor|report|check]"
        echo "  monitor - Start continuous monitoring"
        echo "  report  - Generate system report"
        echo "  check   - Run single health check"
        exit 1
        ;;
esac
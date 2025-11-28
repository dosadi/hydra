# Hydra Codespaces Administration Quick Start

## Environment Overview
- **Platform**: GitHub Codespaces (Ubuntu 24.04)
- **IP Address**: 10.0.10.154/16
- **SSH Port**: 2222
- **User**: codespace (with docker, ssh, and development tool groups)
- **Workspace**: /workspaces/hydra

## Quick Setup Commands

### 1. Initial SSH Setup
```bash
# Generate SSH key (already done)
ssh-keygen -t ed25519 -C "codespace-admin-$(date +%Y%m%d)" -f ~/.ssh/id_ed25519 -N ""

# Copy public key for remote access
cat ~/.ssh/id_ed25519.pub
# Add this key to remote systems' authorized_keys
```

### 2. Start Administration Suite
```bash
cd /workspaces/hydra
./scripts/codespaces_admin.sh
```

### 3. Start Monitoring
```bash
# Background monitoring
./scripts/codespaces_monitor.sh monitor &

# Or run health check
./scripts/codespaces_monitor.sh check
```

### 4. Generate System Report
```bash
./scripts/codespaces_monitor.sh report
```

## Available Administration Tools

### Local Administration
- **System Health**: `./scripts/codespaces_admin.sh` → Option 1
- **SSH Keys**: `./scripts/codespaces_admin.sh` → Option 2
- **Docker Admin**: `./scripts/codespaces_admin.sh` → Option 3
- **Project Status**: `./scripts/codespaces_admin.sh` → Option 4
- **Network Config**: `./scripts/codespaces_admin.sh` → Option 5
- **Security Check**: `./scripts/codespaces_admin.sh` → Option 6
- **Backup Config**: `./scripts/codespaces_admin.sh` → Option 7
- **Full Report**: `./scripts/codespaces_admin.sh` → Option 8

### Remote Administration Scripts
- **Android/Termux ADB**: `./scripts/host_adb_ssh_control.sh start|stop|status`
- **Termux Direct**: `./scripts/termux_ssh_control.sh start|stop|status`
- **RSYNC to Termux**: `./scripts/rsync_to_termux.sh`

### Development Tools
- **Build Project**: `make` (from /workspaces/hydra)
- **Run Simulator**: `cd sim && ./sim_voxel`
- **VNC Backend**: `make VNC=1` (for remote visualization)
- **Setup SDK**: `./scripts/setup_sdk.sh`

## Network Configuration

### Current Setup
```
Interface: eth0
IP: 10.0.10.154/16
Gateway: 10.0.0.1
DNS: 168.63.129.16 (Azure)
SSH Port: 2222
Docker Bridge: 172.17.0.1/16
```

### Remote Access
```bash
# SSH to Codespace
ssh -p 2222 codespace@<codespace-url>

# Docker access (if exposed)
docker exec -it <container> bash
```

## Security Notes

### Current Permissions
- User has docker group access
- SSH key authentication configured
- Passwordless sudo available
- Firewall: UFW (check status with `ufw status`)

### Best Practices
1. Keep SSH keys secure and rotated
2. Use strong passwords for any services
3. Monitor logs in `/workspaces/hydra/logs/`
4. Regular backups of important configurations
5. Check security status with admin script

## Monitoring & Alerts

### Log Locations
- **Monitor Logs**: `/workspaces/hydra/logs/monitor_YYYYMMDD.log`
- **Alert Logs**: `/workspaces/hydra/logs/alerts_YYYYMMDD.log`
- **Reports**: `/workspaces/hydra/reports/`

### Automated Monitoring
```bash
# Start background monitoring
./scripts/codespaces_monitor.sh monitor &

# Check current status
./scripts/codespaces_monitor.sh check

# Generate report
./scripts/codespaces_monitor.sh report
```

## Project-Specific Administration

### Hydra Voxel Simulator
- **Build**: `make` or `make VNC=1`
- **Run**: `cd sim && ./sim_voxel`
- **Test**: `cd sim && make test`
- **Clean**: `cd sim && make clean`

### Development Workflow
1. Pull latest changes: `git pull`
2. Check status: `./scripts/codespaces_admin.sh` → Option 4
3. Build and test: `make && cd sim && ./sim_voxel`
4. Commit changes: `git add . && git commit -m "..."`

## Troubleshooting

### Common Issues
1. **SSH Connection Failed**: Check port 2222 is open and SSH service running
2. **Build Errors**: Run `./scripts/check_build_requirements.py`
3. **Docker Issues**: Check with `./scripts/codespaces_admin.sh` → Option 3
4. **High Resource Usage**: Check monitor logs and restart services

### Emergency Commands
```bash
# Restart SSH
sudo systemctl restart sshd

# Restart Docker
sudo systemctl restart docker

# Check system resources
htop

# Network diagnostics
ping -c 3 8.8.8.8
```

## Integration with Existing Tools

### Android Administration
```bash
# Start Termux SSH via ADB
./scripts/host_adb_ssh_control.sh start

# Sync files to Termux
./scripts/rsync_to_termux.sh
```

### Multi-System Management
- Use SSH keys for passwordless access
- Configure Ansible inventory for automation
- Set up monitoring dashboards
- Implement backup strategies

## Next Steps

1. **Configure Remote Access**: Add SSH keys to target systems
2. **Set up Monitoring**: Start background monitoring service
3. **Test Connectivity**: Verify access to Android devices and other systems
4. **Document Procedures**: Keep administration procedures updated
5. **Automate Backups**: Set up regular configuration backups

For detailed help, run `./scripts/codespaces_admin.sh` and select options interactively.
# Laptop Remote Administration Guide

## Overview
This guide shows you how to set up and administer your laptop remotely from GitHub Codespaces. You'll be able to monitor, manage, and control your laptop from anywhere with internet access.

## Quick Start

### Step 1: Set Up Your Laptop
Run this command **ON YOUR LAPTOP** (not in Codespaces):

```bash
# Download and run the setup script
curl -fsSL https://raw.githubusercontent.com/dosadi/hydra/main/scripts/setup_laptop_admin.sh | bash
```

Or if you have the repository cloned locally:
```bash
cd /path/to/hydra
./scripts/setup_laptop_admin.sh
```

This will:
- Install and configure SSH server
- Set up SSH keys for secure access
- Configure firewall rules
- Install monitoring tools
- Create administration scripts

### Step 2: Configure Connection from Codespaces
In your GitHub Codespaces environment:

```bash
cd /workspaces/hydra

# Interactive setup
./scripts/configure_laptop.sh setup

# Or quick setup with known IP
./scripts/configure_laptop.sh quick YOUR_LAPTOP_IP
```

### Step 3: Start Administering
```bash
# Interactive administration
./scripts/codespaces_admin.sh laptop

# Or use the laptop admin directly
./scripts/laptop_admin.sh
```

## Detailed Setup Instructions

### Laptop Setup (Run on Your Laptop)

#### 1. Prerequisites
- Administrative/sudo access
- Internet connection
- Supported OS: Ubuntu/Debian, CentOS/RHEL/Fedora, or macOS

#### 2. Run Setup Script
```bash
# Make script executable
chmod +x setup_laptop_admin.sh

# Run setup
./setup_laptop_admin.sh
```

The script will:
- Detect your OS and install appropriate packages
- Configure SSH server with security best practices
- Generate SSH keys for authentication
- Set up firewall rules
- Install monitoring tools (htop, ncdu, sysstat)
- Create administration scripts in `~/.admin/`

#### 3. Note Your Connection Details
After setup, the script will display:
```
=== LAPTOP CONNECTION INFO ===

IP Address: 192.168.1.100
SSH Port: 22
Username: yourusername

SSH Command:
ssh -p 22 yourusername@192.168.1.100

Public Key (add to remote systems):
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... your-laptop-key
```

### Codespaces Configuration

#### 1. Configure Connection
```bash
cd /workspaces/hydra

# Option A: Interactive setup (recommended)
./scripts/configure_laptop.sh setup

# Option B: Quick setup
./scripts/configure_laptop.sh quick 192.168.1.100 yourusername 22 ~/.ssh/id_ed25519 MyLaptop
```

#### 2. Test Connection
```bash
# Test the configuration
./scripts/configure_laptop.sh test
```

#### 3. View Configuration
```bash
./scripts/configure_laptop.sh show
```

## Administration Features

### Interactive Administration
```bash
# From main admin suite
./scripts/codespaces_admin.sh laptop

# Or directly
./scripts/laptop_admin.sh
```

Available options:
1. **Test Connection** - Verify SSH connectivity
2. **Get Status** - Quick system overview
3. **Monitor System** - Detailed system monitoring
4. **Run Command** - Execute commands remotely
5. **Sync Files** - Transfer files between systems
6. **Install Software** - Install packages on laptop
7. **System Maintenance** - Update and clean system
8. **Interactive Shell** - Full remote shell access
9. **Setup Laptop** - Re-run laptop setup if needed

### Command-Line Administration
```bash
# Test connection
./scripts/laptop_admin.sh test

# Get status
./scripts/laptop_admin.sh status

# Monitor system
./scripts/laptop_admin.sh monitor

# Run a command
./scripts/laptop_admin.sh cmd "df -h"

# Sync files from laptop
./scripts/laptop_admin.sh sync "~/Documents" "./laptop_docs"

# Install software
./scripts/laptop_admin.sh install htop

# Start interactive shell
./scripts/laptop_admin.sh shell
```

## Security Considerations

### SSH Security
- Uses Ed25519 keys (more secure than RSA)
- Password authentication disabled
- Root login disabled
- Key-based authentication only
- Firewall configured to allow SSH

### Best Practices
1. **Keep SSH keys secure** - Never share private keys
2. **Use strong passwords** - For any accounts that need passwords
3. **Regular updates** - Keep your laptop's OS and packages updated
4. **Monitor access** - Check SSH logs for unauthorized access attempts
5. **Firewall rules** - Only allow necessary ports

### Network Security
- Ensure your laptop is on a trusted network
- Consider using VPN for public WiFi
- Use fail2ban if available for SSH protection
- Regularly rotate SSH keys

## Troubleshooting

### Connection Issues

#### "Connection refused"
```bash
# Check if SSH is running on laptop
sudo systemctl status sshd  # Linux
sudo launchctl list | grep ssh  # macOS

# Restart SSH service
sudo systemctl restart sshd  # Linux
sudo launchctl unload /System/Library/LaunchDaemons/ssh.plist
sudo launchctl load -w /System/Library/LaunchDaemons/ssh.plist  # macOS
```

#### "Permission denied"
```bash
# Check SSH key permissions
ls -la ~/.ssh/
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub

# Ensure key is in authorized_keys
cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

#### "Network unreachable"
```bash
# Check laptop IP address
hostname -I

# Test basic connectivity
ping YOUR_LAPTOP_IP

# Check firewall
sudo ufw status  # Linux
sudo pfctl -s rules  # macOS
```

### Configuration Issues

#### "Laptop not configured"
```bash
# Run configuration setup
./scripts/configure_laptop.sh setup

# Or check config file
cat ~/.laptop_admin_config
```

#### "Command not found" on laptop
```bash
# Re-run laptop setup
./scripts/setup_laptop_admin.sh
```

## Advanced Usage

### Automated Monitoring
Set up cron jobs on your laptop for automated monitoring:

```bash
# Edit crontab
crontab -e

# Add monitoring every 5 minutes
*/5 * * * * ~/.admin/monitor_laptop.sh
```

### Custom Commands
Create custom administration scripts in `~/.admin/` on your laptop:

```bash
# Example: Backup script
cat > ~/.admin/backup_home.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/tmp/home_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp -r ~/Documents ~/Pictures "$BACKUP_DIR/"
tar -czf "${BACKUP_DIR}.tar.gz" "$BACKUP_DIR"
echo "Backup created: ${BACKUP_DIR}.tar.gz"
EOF

chmod +x ~/.admin/backup_home.sh
```

### Multi-Laptop Management
For managing multiple laptops:

1. Create separate config files:
```bash
cp ~/.laptop_admin_config ~/.laptop_work_config
cp ~/.laptop_admin_config ~/.laptop_home_config
```

2. Switch between configurations:
```bash
source ~/.laptop_work_config
./scripts/laptop_admin.sh status
```

## Integration with Existing Tools

### Android/Termux Administration
Your laptop administration integrates with existing Android tools:

```bash
# Sync files from laptop to Termux
./scripts/laptop_admin.sh sync "~/Documents/notes.txt" "/tmp/"
./scripts/rsync_to_termux.sh /tmp/notes.txt

# Remote control Android from laptop
./scripts/laptop_admin.sh cmd "adb devices"
```

### Project Development
Use laptop administration for development workflows:

```bash
# Check laptop development environment
./scripts/laptop_admin.sh cmd "docker --version && node --version"

# Sync project files
./scripts/laptop_admin.sh sync "~/projects/hydra" "./laptop_backup"

# Run builds remotely
./scripts/laptop_admin.sh cmd "cd ~/projects/hydra && make"
```

## Support and Resources

### Getting Help
- Check the main administration guide: `CODESPACE_ADMIN_README.md`
- View logs: `tail -f /workspaces/hydra/logs/monitor_*.log`
- Test connectivity: `./scripts/configure_laptop.sh test`

### Useful Commands
```bash
# View laptop system info
./scripts/laptop_admin.sh cmd "uname -a && lsb_release -a"

# Check running processes
./scripts/laptop_admin.sh cmd "ps aux | head -10"

# Monitor network
./scripts/laptop_admin.sh cmd "netstat -tlnp | head -10"

# Check disk usage
./scripts/laptop_admin.sh cmd "df -h && du -sh ~/Documents"
```

This setup gives you complete remote administration capabilities for your laptop, allowing you to monitor, manage, and maintain your system from anywhere via GitHub Codespaces! 🚀
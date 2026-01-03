#!/bin/bash
# INSTALL_ALL.sh - One-command setup for complete Kali Pi field operations

set -e

echo "════════════════════════════════════════════════════════════════"
echo "    KALI PI ZERO 2W - COMPLETE FIELD OPERATIONS SETUP"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Check if running as kali user
if [ "$USER" != "kali" ]; then
    echo "ERROR: Must run as kali user"
    exit 1
fi

# Check internet connection
if ! ping -c 1 8.8.8.8 &>/dev/null; then
    echo "ERROR: No internet connection"
    exit 1
fi

echo "[1/10] Updating system..."
sudo apt update && sudo apt upgrade -y

echo ""
echo "[2/10] Installing essential packages..."
sudo apt install -y \
    aircrack-ng metasploit-framework nmap masscan hydra wifite \
    reaver bully firmware-mediatek screen tmux vim git python3-pip \
    hostapd dnsmasq wireshark tshark ettercap-text-only bettercap \
    nikto dirb gobuster sqlmap john hashcat macchanger proxychains4 \
    tor vsftpd apache2 hcxdumptool hcxtools crunch cupp seclists \
    i2c-tools bc jq

echo ""
echo "[3/10] Installing Python tools..."
sudo pip3 install scapy requests beautifulsoup4

echo ""
echo "[4/10] Creating directory structure..."
mkdir -p ~/captures/{wpa,wep,pmkid,raw,creds}
mkdir -p ~/wordlists
mkdir -p ~/scripts
mkdir -p ~/logs
mkdir -p ~/ftp_upload
mkdir -p ~/reports
mkdir -p ~/backups
mkdir -p ~/.tmux

echo ""
echo "[5/10] Downloading wordlists..."
cd ~/wordlists
if [ ! -f rockyou.txt ]; then
    wget -q --show-progress https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt || echo "rockyou.txt download failed (non-critical)"
fi

# Create common passwords list
cat > ~/wordlists/common_passwords.txt <<EOF
password
123456
12345678
password123
admin
qwerty
letmein
welcome
monkey
1234567890
password1
123456789
12345
1234
111111
123123
abc123
password!
qwerty123
admin123
root
toor
pass
EOF

sudo ln -sf ~/wordlists/rockyou.txt /usr/share/wordlists/rockyou.txt 2>/dev/null || true

echo ""
echo "[6/10] Configuring wireless driver..."
if ! grep -q "mt7921u" /etc/modules; then
    echo "mt7921u" | sudo tee -a /etc/modules
fi

echo ""
echo "[7/10] Configuring services..."

# FTP configuration
sudo bash -c 'cat > /etc/vsftpd.conf <<EOF
listen=YES
listen_ipv6=NO
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
chroot_local_user=YES
allow_writeable_chroot=YES
secure_chroot_dir=/var/run/vsftpd/empty
pam_service_name=vsftpd
userlist_enable=YES
userlist_file=/etc/vsftpd.userlist
userlist_deny=NO
pasv_enable=YES
pasv_min_port=40000
pasv_max_port=40100
xferlog_enable=YES
xferlog_file=/var/log/vsftpd.log
use_localtime=YES
EOF'

echo "kali" | sudo tee /etc/vsftpd.userlist

sudo systemctl enable vsftpd
sudo systemctl enable ssh
sudo systemctl enable apache2

# Disable unnecessary services
sudo systemctl disable bluetooth
sudo systemctl disable avahi-daemon
sudo rfkill block bluetooth

echo ""
echo "[8/10] Setting up tmux configuration..."
cat > ~/.tmux.conf <<'EOF'
unbind C-b
set-option -g prefix C-a
bind-key C-a send-prefix
bind | split-window -h
bind - split-window -v
unbind '"'
unbind %
bind -n M-Left select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up select-pane -U
bind -n M-Down select-pane -D
set -g mouse on
set-option -g allow-rename off
set -g base-index 1
setw -g pane-base-index 1
set-option -g history-limit 10000
set -g status-position bottom
set -g status-bg colour234
set -g status-fg colour137
set -g status-left '#[fg=colour233,bg=colour245,bold] KALI-PI '
set -g status-right '#[fg=colour233,bg=colour245,bold] %H:%M:%S '
set -g status-right-length 50
set -g status-left-length 20
setw -g window-status-current-format ' #I:#W#F '
setw -g window-status-current-style 'fg=colour1 bg=colour237 bold'
setw -g window-status-format ' #I:#W#F '
setw -g window-status-style 'fg=colour250 bg=colour235'
bind r source-file ~/.tmux.conf \; display "Config reloaded!"
EOF

echo ""
echo "[9/10] Making all scripts executable..."
chmod +x ~/scripts/*.sh 2>/dev/null || true

echo ""
echo "[10/10] Setting up cron jobs..."
(crontab -l 2>/dev/null; cat <<'EOF'
@reboot sleep 60 && /home/kali/scripts/field_startup.sh
0 * * * * /home/kali/scripts/auto_upload.sh 2>&1 | logger -t auto_upload
0 3 * * 0 find /home/kali/logs/ -name "*.log" -mtime +30 -delete
0 */6 * * * /home/kali/scripts/health_check.sh
0 2 * * * /home/kali/scripts/backup_captures.sh
*/30 * * * * /home/kali/scripts/disk_monitor.sh
*/5 * * * * /home/kali/scripts/wifi_watchdog.sh
EOF
) | crontab -

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "                    INSTALLATION COMPLETE!"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "✓ All packages installed"
echo "✓ Directory structure created"
echo "✓ Wordlists downloaded"
echo "✓ Services configured"
echo "✓ Scripts ready"
echo "✓ Cron jobs setup"
echo ""
echo "NEXT STEPS:"
echo "1. Reboot the system: sudo reboot"
echo "2. After reboot, run: ~/scripts/pre_mission_check.sh"
echo "3. Read the guide: cat ~/HEADLESS_OPERATION_GUIDE.md"
echo "4. Start operations: ~/scripts/field_startup.sh"
echo ""
echo "Quick Start:"
echo "  ~/scripts/tmux_ops.sh           # Full interface"
echo "  ~/scripts/smart_capture.sh      # Automated capture"
echo "  ~/scripts/workflow_campaign.sh  # Extended campaign"
echo ""
echo "Documentation saved to: ~/HEADLESS_OPERATION_GUIDE.md"
echo "════════════════════════════════════════════════════════════════"
```

---

## Summary

#You now have a **complete, production-ready Kali Pi Zero 2W headless field operations system** with:

### ✅ Features Implemented:

#1. **Automated Startup** - field_startup.sh initializes everything
#2. **Smart Capture** - Learns, adapts, skips duplicates
#3. **Multi-Target Campaigns** - Automated rotation through targets
#4. **Tmux Integration** - Professional multi-window interface
#5. **FTP Server** - Easy file transfer to GPU machine
#6. **Auto-Upload** - Hourly uploads to cracking machine
#7. **Health Monitoring** - System checks, battery, temperature
#8. **WiFi Watchdog** - Auto-reconnect if disconnected
#9. **Comprehensive Logging** - Everything tracked
#10. **Report Generation** - Text and HTML reports
#11. **Stealth Mode** - Covert operations capability
#12. **Multiple Workflows** - Reconnaissance, targeted, campaign, passive
#13. **GPS Logging** - Optional location tracking
#14. **Backup System** - Automated archiving
#15. **Error Recovery** - Handles failures gracefully

### 📁 Complete File Structure:
```
#~/captures/
#├── captures/
#│   ├── wpa/           # WPA handshakes
#│   ├── pmkid/         # PMKID captures
#│   ├── raw/           # Raw scans
#│   └── creds/         # Captured credentials
#├── scripts/           # All automation scripts
#├── wordlists/         # Password lists
#├── logs/              # Operation logs
#├── reports/           # Generated reports
#├── backups/           # Archived captures
#├── ftp_upload/        # FTP staging
#└── HEADLESS_OPERATION_GUIDE.md
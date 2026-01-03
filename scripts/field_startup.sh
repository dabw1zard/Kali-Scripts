#!/bin/bash
# field_startup.sh - Automated field operations startup

LOGFILE=~/logs/startup_$(date +%Y%m%d_%H%M%S).log

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOGFILE
}

log "=== KALI PI FIELD STARTUP ==="

# Wait for network
log "Waiting for network connection..."
for i in {1..30}; do
    if ping -c 1 8.8.8.8 &>/dev/null; then
        log "Network connected"
        break
    fi
    sleep 2
done

# Check adapter
log "Checking for AWUS036AXML adapter..."
if lsusb | grep -q "0e8d:7961"; then
    log "Adapter detected"
else
    log "WARNING: Adapter not detected"
    exit 1
fi

# Load driver
log "Loading MT7921 driver..."
sudo modprobe mt7921u
sleep 3

# Verify interface
if iwconfig 2>&1 | grep -q "wlan1"; then
    log "Wireless interface wlan1 ready"
else
    log "ERROR: wlan1 interface not found"
    exit 1
fi

# Enable monitor mode
log "Enabling monitor mode..."
sudo airmon-ng check kill
sudo airmon-ng start wlan1

if iwconfig 2>&1 | grep -q "wlan1mon"; then
    log "Monitor mode enabled: wlan1mon"
else
    log "ERROR: Failed to enable monitor mode"
    exit 1
fi

# Change MAC address
log "Randomizing MAC address..."
sudo ifconfig wlan1mon down
sudo macchanger -r wlan1mon
sudo ifconfig wlan1mon up

# Start services
log "Starting FTP server..."
sudo systemctl start vsftpd

log "Starting Apache server..."
sudo systemctl start apache2

# System info
log "=== SYSTEM STATUS ==="
log "Hostname: $(hostname)"
log "IP Address: $(hostname -I | awk '{print $1}')"
log "Uptime: $(uptime -p)"
log "Temperature: $(vcgencmd measure_temp)"
log "Memory: $(free -h | grep Mem: | awk '{print $3 "/" $2}')"

log "=== FIELD STARTUP COMPLETE ==="
log "Ready for operations"

# Display on console
cat <<EOF

╔══════════════════════════════════════╗
║      KALI PI FIELD OPERATIONS        ║
║            SYSTEM READY              ║
╚══════════════════════════════════════╝

Wireless Interface: wlan1mon
FTP Server: ftp://$(hostname -I | awk '{print $1}')
Web Server: http://$(hostname -I | awk '{print $1}')

Use 'tmux attach -t ops' to view operations

EOF
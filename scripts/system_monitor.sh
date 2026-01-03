#!/bin/bash
# system_monitor.sh - Real-time system monitoring for tmux

while true; do
    clear
    cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║           KALI PI ZERO 2W - FIELD OPERATIONS                 ║
╚══════════════════════════════════════════════════════════════╝
EOF
    
    echo ""
    echo "=== SYSTEM STATUS ==="
    echo "Hostname: $(hostname)"
    echo "Uptime: $(uptime -p)"
    echo "Time: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    
    echo "=== HARDWARE ==="
    echo "CPU Temp: $(vcgencmd measure_temp | cut -d= -f2)"
    echo "CPU Freq: $(vcgencmd measure_clock arm | cut -d= -f2 | awk '{printf "%.0f MHz\n", $1/1000000}')"
    echo "Memory: $(free -h | grep Mem: | awk '{print $3 " / " $2 " (" $3/$2*100 "%)"}')"
    echo "Disk: $(df -h / | tail -1 | awk '{print $3 " / " $2 " (" $5 ")"}')"
    echo ""
    
    echo "=== NETWORK ==="
    echo "Built-in WiFi (wlan0):"
    WLAN0_STATUS=$(iwconfig wlan0 2>&1 | grep -q "ESSID:off" && echo "Disconnected" || iwconfig wlan0 2>&1 | grep ESSID | cut -d'"' -f2)
    WLAN0_IP=$(ip addr show wlan0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1)
    echo "  Status: $WLAN0_STATUS"
    echo "  IP: ${WLAN0_IP:-None}"
    echo ""
    
    echo "External Adapter (wlan1/wlan1mon):"
    if iwconfig wlan1mon &>/dev/null; then
        echo "  Mode: Monitor"
        echo "  Interface: wlan1mon"
        CHANNEL=$(iwconfig wlan1mon 2>&1 | grep Frequency | awk '{print $2}' | cut -d: -f2)
        echo "  Channel: ${CHANNEL:-Unknown}"
    elif iwconfig wlan1 &>/dev/null; then
        echo "  Mode: Managed"
        echo "  Interface: wlan1"
    else
        echo "  Status: Not detected"
    fi
    echo ""
    
    echo "=== SERVICES ==="
    systemctl is-active --quiet ssh && echo "  SSH: Running ✓" || echo "  SSH: Stopped ✗"
    systemctl is-active --quiet vsftpd && echo "  FTP: Running ✓" || echo "  FTP: Stopped ✗"
    systemctl is-active --quiet apache2 && echo "  Web: Running ✓" || echo "  Web: Stopped ✗"
    echo ""
    
    echo "=== CAPTURES ==="
    WPA_COUNT=$(find ~/captures/wpa/ -name "*.cap" 2>/dev/null | wc -l)
    PMKID_COUNT=$(find ~/captures/pmkid/ -name "*.hc22000" 2>/dev/null | wc -l)
    echo "  WPA Handshakes: $WPA_COUNT"
    echo "  PMKID Captures: $PMKID_COUNT"
    echo "  Latest: $(ls -t ~/captures/*/*.cap ~/captures/*/*.hc22000 2>/dev/null | head -1 | xargs basename 2>/dev/null || echo 'None')"
    echo ""
    
    echo "=== RECENT ACTIVITY ==="
    tail -3 ~/logs/startup_*.log 2>/dev/null | tail -1 || echo "  No recent activity"
    echo ""
    
    echo "Press Ctrl+C to exit monitor"
    echo "Refreshing in 5 seconds..."
    
    sleep 5
done
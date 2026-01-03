#!/bin/bash
# wifi_watchdog.sh - Auto-reconnect WiFi if disconnected

LOG_FILE=~/logs/wifi_watchdog.log

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Check if wlan0 is connected
if ! iwconfig wlan0 2>&1 | grep -q "ESSID:\""; then
    log "WiFi disconnected, attempting reconnect..."
    
    # Try to reconnect using wpa_supplicant
    sudo wpa_cli -i wlan0 reconnect
    
    sleep 5
    
    # Check if reconnected
    if iwconfig wlan0 2>&1 | grep -q "ESSID:\""; then
        ESSID=$(iwconfig wlan0 2>&1 | grep ESSID | cut -d'"' -f2)
        log "Reconnected to: $ESSID"
    else
        log "Reconnection failed, restarting networking..."
        sudo systemctl restart networking
        sleep 10
        
        if iwconfig wlan0 2>&1 | grep -q "ESSID:\""; then
            log "Successfully reconnected after restart"
        else
            log "ERROR: Unable to reconnect WiFi"
        fi
    fi
fi
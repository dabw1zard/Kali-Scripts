#!/bin/bash
# health_check.sh - System health monitoring

LOG_FILE=~/logs/health_$(date +%Y%m%d).log

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log "=== Health Check Started ==="

# Check temperature
TEMP=$(vcgencmd measure_temp | cut -d= -f2 | cut -d\' -f1)
if (( $(echo "$TEMP > 75" | bc -l) )); then
    log "WARNING: High temperature: ${TEMP}°C"
fi

# Check disk space
DISK_USAGE=$(df -h / | tail -1 | awk '{print $5}' | cut -d% -f1)
if [ "$DISK_USAGE" -gt 90 ]; then
    log "WARNING: Disk usage high: ${DISK_USAGE}%"
    # Clean old captures
    find ~/captures/ -name "*.cap" -mtime +7 -delete
    log "Cleaned old captures"
fi

# Check memory
MEM_AVAILABLE=$(free | grep Mem | awk '{print $7}')
if [ "$MEM_AVAILABLE" -lt 100000 ]; then
    log "WARNING: Low memory available: ${MEM_AVAILABLE}KB"
fi

# Check adapter
if ! lsusb | grep -q "0e8d:7961"; then
    log "ERROR: AWUS036AXML not detected"
fi

# Check WiFi connection
if ! ping -c 1 8.8.8.8 &>/dev/null; then
    log "WARNING: No internet connection"
fi

# Check services
for service in ssh vsftpd; do
    if ! systemctl is-active --quiet $service; then
        log "WARNING: $service is not running"
        sudo systemctl start $service
        log "Attempted to restart $service"
    fi
done

log "=== Health Check Complete ==="
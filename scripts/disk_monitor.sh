#!/bin/bash
# disk_monitor.sh - Monitor and manage disk space

THRESHOLD=90
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | cut -d% -f1)

if [ "$DISK_USAGE" -gt "$THRESHOLD" ]; then
    echo "[$(date)] WARNING: Disk usage at ${DISK_USAGE}%" >> ~/logs/disk_monitor.log
    
    # Clean old captures (older than 7 days)
    find ~/captures/ -name "*.cap" -mtime +7 -delete
    find ~/captures/ -name "*.pcapng" -mtime +7 -delete
    
    # Clean old logs (older than 30 days)
    find ~/logs/ -name "*.log" -mtime +30 -delete
    
    # Clean apt cache
    sudo apt-get clean
    
    # Clean thumbnail cache
    rm -rf ~/.cache/thumbnails/*
    
    NEW_USAGE=$(df / | tail -1 | awk '{print $5}' | cut -d% -f1)
    echo "[$(date)] Cleaned. New usage: ${NEW_USAGE}%" >> ~/logs/disk_monitor.log
fi
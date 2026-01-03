#!/bin/bash
# backup_captures.sh - Backup important captures

BACKUP_DIR=~/backups/$(date +%Y%m%d)
mkdir -p "$BACKUP_DIR"

LOG_FILE=~/logs/backup_$(date +%Y%m%d).log

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== Starting backup ==="

# Backup captures with handshakes
find ~/captures/wpa/ -name "*.cap" -mtime -7 | while read file; do
    if aircrack-ng "$file" 2>&1 | grep -q "1 handshake"; then
        cp "$file" "$BACKUP_DIR/"
        log "Backed up: $(basename "$file")"
    fi
done

# Backup PMKID captures
find ~/captures/pmkid/ -name "*.hc22000" -mtime -7 -exec cp {} "$BACKUP_DIR/" \;

# Backup important logs
cp ~/logs/startup_*.log "$BACKUP_DIR/" 2>/dev/null
cp ~/logs/health_*.log "$BACKUP_DIR/" 2>/dev/null

# Create archive
cd ~/backups
tar -czf "backup_$(date +%Y%m%d).tar.gz" "$(date +%Y%m%d)"
rm -rf "$(date +%Y%m%d)"

ARCHIVE_SIZE=$(du -h "backup_$(date +%Y%m%d).tar.gz" | cut -f1)
log "Archive created: backup_$(date +%Y%m%d).tar.gz ($ARCHIVE_SIZE)"

# Clean old backups (keep last 14 days)
find ~/backups/ -name "backup_*.tar.gz" -mtime +14 -delete

log "=== Backup complete ==="
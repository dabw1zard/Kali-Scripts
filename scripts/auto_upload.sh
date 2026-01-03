#!/bin/bash
# auto_upload.sh - Automatically upload captures to GPU machine via FTP

GPU_HOST=${1:-"192.168.1.100"}
GPU_USER=${2:-"kaliuser"}
GPU_PASS=${3:-"password"}
REMOTE_DIR=${4:-"/home/kaliuser/incoming"}

SOURCE_DIRS=(
    ~/captures/wpa
    ~/captures/pmkid
    ~/captures/raw
)

LOG_FILE=~/logs/upload_$(date +%Y%m%d).log

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== Starting auto-upload to GPU machine ==="
log "Target: $GPU_HOST"

# Check if GPU machine is reachable
if ! ping -c 1 "$GPU_HOST" &>/dev/null; then
    log "ERROR: GPU machine not reachable"
    exit 1
fi

# Upload function
upload_files() {
    local source_dir=$1
    
    if [ ! -d "$source_dir" ]; then
        return
    fi
    
    # Find files modified in last 24 hours
    find "$source_dir" -type f -mtime -1 | while read file; do
        filename=$(basename "$file")
        
        log "Uploading: $filename"
        
        # Upload via FTP
        ftp -inv "$GPU_HOST" <<EOF
user $GPU_USER $GPU_PASS
binary
cd $REMOTE_DIR
put "$file"
bye
EOF
        
        if [ $? -eq 0 ]; then
            log "SUCCESS: $filename uploaded"
            
            # Mark as uploaded
            touch "${file}.uploaded"
        else
            log "ERROR: Failed to upload $filename"
        fi
    done
}

# Upload from each directory
for dir in "${SOURCE_DIRS[@]}"; do
    log "Processing: $dir"
    upload_files "$dir"
done

log "=== Upload complete ==="
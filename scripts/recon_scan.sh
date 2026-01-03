#!/bin/bash
# recon_scan.sh - Automated network reconnaissance

INTERFACE=${1:-wlan1mon}
DURATION=${2:-300}
OUTPUT_DIR=~/captures/raw

mkdir -p "$OUTPUT_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
FILENAME="${OUTPUT_DIR}/recon_${TIMESTAMP}"

echo "[*] Starting network reconnaissance"
echo "[*] Interface: $INTERFACE"
echo "[*] Duration: ${DURATION}s"
echo "[*] Output: $FILENAME"

# Scan all channels
sudo airodump-ng -w "$FILENAME" \
    --output-format pcap,csv,netxml \
    --write-interval 10 \
    "$INTERFACE" &

AIRODUMP_PID=$!

echo "[*] Scanning... PID: $AIRODUMP_PID"
echo "[*] Will run for ${DURATION} seconds"

# Wait for duration
sleep "$DURATION"

# Stop airodump
sudo kill "$AIRODUMP_PID" 2>/dev/null

echo "[*] Scan complete"

# Parse results
if [ -f "${FILENAME}-01.csv" ]; then
    echo "[*] Parsing results..."
    
    # Extract AP information
    AP_COUNT=$(grep -c "WPA\|WEP\|OPN" "${FILENAME}-01.csv" | head -1)
    
    # Generate report
    cat > "${FILENAME}_report.txt" <<EOF
Network Reconnaissance Report
=============================
Date: $(date)
Duration: ${DURATION}s
Total APs Found: $AP_COUNT

Files Generated:
  - ${FILENAME}-01.cap (packet capture)
  - ${FILENAME}-01.csv (network list)
  - ${FILENAME}-01.kismet.netxml (kismet format)

Top 10 Networks by Signal Strength:
-----------------------------------
EOF
    
    # Parse CSV for top networks (skip header, sort by signal)
    tail -n +2 "${FILENAME}-01.csv" | \
        grep -v "Station MAC" | \
        awk -F',' '{if($1 != "") print $4 "dBm\t" $14 "\t" $1}' | \
        sort -rn | \
        head -10 >> "${FILENAME}_report.txt"
    
    echo "[*] Report saved to: ${FILENAME}_report.txt"
    cat "${FILENAME}_report.txt"
fi
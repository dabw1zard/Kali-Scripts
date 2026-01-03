#!/bin/bash
# stealth_mode.sh - Enable stealth operations

echo "[*] Enabling stealth mode..."

# Disable LEDs
echo 0 | sudo tee /sys/class/leds/led0/brightness  # Power LED
echo 0 | sudo tee /sys/class/leds/led1/brightness  # Activity LED

# Randomize MAC address
sudo ifconfig wlan1mon down
sudo macchanger -r wlan1mon
NEW_MAC=$(macchanger -s wlan1mon | grep "Current MAC" | awk '{print $3}')
sudo ifconfig wlan1mon up

echo "[*] MAC randomized to: $NEW_MAC"

# Reduce TX power (less detectable)
sudo iw dev wlan1mon set txpower fixed 1000  # 10dBm (low power)

echo "[*] TX power reduced to 10dBm"

# Disable unnecessary services
sudo systemctl stop apache2
sudo systemctl stop vsftpd

# Set low-profile hostname
sudo hostname "android-phone"

# Disable broadcast of hostname
sudo systemctl stop avahi-daemon

# Use random channel hopping
sudo airodump-ng wlan1mon --background 1 &>/dev/null &

echo "[+] Stealth mode enabled"
echo "    - LEDs disabled"
echo "    - MAC randomized"
echo "    - Low TX power"
echo "    - Services stopped"
echo "    - Hostname masked"
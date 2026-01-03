#!/bin/bash
# pre_mission_check.sh - Pre-mission system check

echo "════════════════════════════════════════════════════════════════"
echo "              KALI PI PRE-MISSION CHECKLIST"
echo "════════════════════════════════════════════════════════════════"
echo ""

CHECKS_PASSED=0
CHECKS_FAILED=0

check() {
    local description=$1
    local command=$2
    
    printf "%-50s" "$description"
    
    if eval "$command" &>/dev/null; then
        echo "[  ✓  ]"
        ((CHECKS_PASSED++))
        return 0
    else
        echo "[  ✗  ]"
        ((CHECKS_FAILED++))
        return 1
    fi
}

# System checks
echo "System Checks:"
echo "──────────────"
check "Root access available" "sudo -n true"
check "SD card has space (>1GB)" "[ \$(df / | tail -1 | awk '{print \$4}') -gt 1000000 ]"
check "System temperature OK (<75°C)" "[ \$(vcgencmd measure_temp | cut -d= -f2 | cut -d\\' -f1 | cut -d. -f1) -lt 75 ]"
check "Memory available (>100MB)" "[ \$(free | grep Mem | awk '{print \$7}') -gt 100000 ]"

echo ""
echo "Network Checks:"
echo "───────────────"
check "WiFi interface available (wlan0)" "iwconfig wlan0 &>/dev/null"
check "Connected to network" "ping -c 1 8.8.8.8"
check "Can resolve DNS" "nslookup google.com"

echo ""
echo "Adapter Checks:"
echo "───────────────"
check "AWUS036AXML detected" "lsusb | grep -q '0e8d:7961'"
check "MT7921 driver loaded" "lsmod | grep -q mt7921u"
check "wlan1 interface exists" "iwconfig wlan1 &>/dev/null"
check "Monitor mode available" "iw list | grep -q monitor"

echo ""
echo "Software Checks:"
echo "────────────────"
check "Aircrack-ng installed" "command -v aircrack-ng"
check "Hashcat installed" "command -v hashcat"
check "hcxdumptool installed" "command -v hcxdumptool"
check "Tmux installed" "command -v tmux"

echo ""
echo "Service Checks:"
echo "───────────────"
check "SSH running" "systemctl is-active --quiet ssh"
check "FTP configured" "systemctl is-active --quiet vsftpd"

echo ""
echo "Directory Checks:"
echo "─────────────────"
check "Capture directory exists" "[ -d ~/captures ]"
check "Scripts directory exists" "[ -d ~/scripts ]"
check "Wordlists available" "[ -f ~/wordlists/rockyou.txt ]"

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "                        RESULTS"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Checks Passed: $CHECKS_PASSED"
echo "Checks Failed: $CHECKS_FAILED"
echo ""

if [ $CHECKS_FAILED -eq 0 ]; then
    echo "✓ ALL CHECKS PASSED - SYSTEM READY FOR OPERATIONS"
    echo ""
    echo "Next steps:"
    echo "  1. Run: ~/scripts/field_startup.sh"
    echo "  2. Or:  ~/scripts/tmux_ops.sh"
    echo "  3. Or:  ~/scripts/workflow_campaign.sh [duration]"
    exit 0
else
    echo "✗ SOME CHECKS FAILED - REVIEW ISSUES ABOVE"
    echo ""
    echo "Common fixes:"
    echo "  - Adapter: Check USB connection and power"
    echo "  - Driver: Run 'sudo modprobe mt7921u'"
    echo "  - Network: Check WiFi credentials in /etc/wpa_supplicant/wpa_supplicant.conf"
    echo "  - Services: Run 'sudo systemctl start ssh vsftpd'"
    exit 1
fi
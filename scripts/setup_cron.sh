#!/bin/bash
# setup_cron.sh - Configure automated tasks

echo "[*] Setting up cron jobs for automated operations"

# Create cron jobs
(crontab -l 2>/dev/null; cat <<EOF

# Auto-start field operations on boot
@reboot sleep 60 && /home/kali/scripts/field_startup.sh

# Auto-upload captures every hour
0 * * * * /home/kali/scripts/auto_upload.sh 2>&1 | logger -t auto_upload

# Clean old logs weekly (keep last 30 days)
0 3 * * 0 find /home/kali/logs/ -name "*.log" -mtime +30 -delete

# System health check every 6 hours
0 */6 * * * /home/kali/scripts/health_check.sh

# Backup captures daily at 2 AM
0 2 * * * /home/kali/scripts/backup_captures.sh

# Monitor disk space and clean if > 90% full
*/30 * * * * /home/kali/scripts/disk_monitor.sh

# Auto-reconnect WiFi if disconnected
*/5 * * * * /home/kali/scripts/wifi_watchdog.sh

EOF
) | crontab -

echo "[+] Cron jobs configured"
crontab -l
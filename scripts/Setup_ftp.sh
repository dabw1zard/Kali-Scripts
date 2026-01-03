#!/bin/bash
# setup_ftp.sh

echo "dab_w1zard" | sudo tee -a /etc/vsftpd.userlist
sudo systemctl restart vsftpd

echo "[*] FTP configured"
echo "[*] Upload directory: ~/ftp_upload"
echo "[*] Connect with: ftp://raspberrypi.local"
echo "[*] User: dab_w1zard"
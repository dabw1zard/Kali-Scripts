#!/bin/bash
# generate_report.sh - Generate comprehensive operation report

REPORT_DIR=~/reports
mkdir -p "$REPORT_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="$REPORT_DIR/operation_report_${TIMESTAMP}.txt"
HTML_REPORT="$REPORT_DIR/operation_report_${TIMESTAMP}.html"

echo "[*] Generating operation report..."

# Text Report
cat > "$REPORT_FILE" <<EOF
════════════════════════════════════════════════════════════════
                    OPERATION REPORT
════════════════════════════════════════════════════════════════

Generated: $(date)
Operator: $(whoami)@$(hostname)
System: Kali Pi Zero 2W

════════════════════════════════════════════════════════════════
                      EXECUTIVE SUMMARY
════════════════════════════════════════════════════════════════

EOF

# Count captures
WPA_TOTAL=$(find ~/captures/wpa/ -name "*.cap" | wc -l)
WPA_WITH_HS=0
for cap in ~/captures/wpa/*.cap; do
    if [ -f "$cap" ] && aircrack-ng "$cap" 2>&1 | grep -q "1 handshake"; then
        ((WPA_WITH_HS++))
    fi
done

PMKID_TOTAL=$(find ~/captures/pmkid/ -name "*.hc22000" | wc -l)
PMKID_VALID=0
for pmkid in ~/captures/pmkid/*.hc22000; do
    if [ -f "$pmkid" ] && [ -s "$pmkid" ]; then
        ((PMKID_VALID++))
    fi
done

cat >> "$REPORT_FILE" <<EOF
Captures Summary:
-----------------
  WPA Handshake Captures:    $WPA_TOTAL
  Valid Handshakes:          $WPA_WITH_HS
  PMKID Captures:            $PMKID_TOTAL
  Valid PMKIDs:              $PMKID_VALID
  
  Total Crackable Hashes:    $((WPA_WITH_HS + PMKID_VALID))

════════════════════════════════════════════════════════════════
                    DETAILED CAPTURES
════════════════════════════════════════════════════════════════

WPA Handshakes:
---------------

EOF

# List WPA captures with details
for cap in ~/captures/wpa/*.cap; do
    if [ -f "$cap" ]; then
        FILENAME=$(basename "$cap")
        
        if aircrack-ng "$cap" 2>&1 | grep -q "1 handshake"; then
            ESSID=$(aircrack-ng "$cap" 2>&1 | grep "ESSID" | head -1 | awk -F': ' '{print $2}')
            BSSID=$(aircrack-ng "$cap" 2>&1 | grep "BSSID" | head -1 | awk '{print $2}')
            
            cat >> "$REPORT_FILE" <<EOF
  [✓] $FILENAME
      ESSID: $ESSID
      BSSID: $BSSID
      Status: Ready for cracking
      Command: hashcat -m 22000 ${FILENAME%.cap}.hc22000 wordlist.txt

EOF
        else
            cat >> "$REPORT_FILE" <<EOF
  [✗] $FILENAME
      Status: No handshake captured

EOF
        fi
    fi
done

cat >> "$REPORT_FILE" <<EOF

PMKID Captures:
---------------

EOF

# List PMKID captures
for pmkid in ~/captures/pmkid/*.hc22000; do
    if [ -f "$pmkid" ] && [ -s "$pmkid" ]; then
        FILENAME=$(basename "$pmkid")
        HASH_COUNT=$(grep -c "WPA\*02" "$pmkid" 2>/dev/null || echo "0")
        
        cat >> "$REPORT_FILE" <<EOF
  [✓] $FILENAME
      PMKIDs: $HASH_COUNT
      Status: Ready for cracking
      Command: hashcat -m 22000 $FILENAME wordlist.txt

EOF
    fi
done

# System stats
cat >> "$REPORT_FILE" <<EOF

════════════════════════════════════════════════════════════════
                      SYSTEM STATISTICS
════════════════════════════════════════════════════════════════

Uptime:           $(uptime -p)
CPU Temperature:  $(vcgencmd measure_temp | cut -d= -f2)
Memory Usage:     $(free -h | grep Mem: | awk '{print $3 " / " $2}')
Disk Usage:       $(df -h / | tail -1 | awk '{print $3 " / " $2 " (" $5 ")"}')

Storage Breakdown:
------------------
  WPA Captures:   $(du -sh ~/captures/wpa/ 2>/dev/null | cut -f1)
  PMKID Captures: $(du -sh ~/captures/pmkid/ 2>/dev/null | cut -f1)
  Logs:           $(du -sh ~/logs/ 2>/dev/null | cut -f1)
  Total:          $(du -sh ~/captures/ 2>/dev/null | cut -f1)

════════════════════════════════════════════════════════════════
                    OPERATION LOG SUMMARY
════════════════════════════════════════════════════════════════

Recent Operations:
------------------
EOF

# Last 20 log entries
tail -20 ~/logs/startup_*.log ~/logs/smart_capture_*.log 2>/dev/null >> "$REPORT_FILE"

cat >> "$REPORT_FILE" <<EOF


════════════════════════════════════════════════════════════════
                    RECOMMENDATIONS
════════════════════════════════════════════════════════════════

Next Steps:
-----------
1. Upload captures to GPU machine for cracking:
   - Use FTP: ftp://$(hostname -I | awk '{print $1}')
   - Or SCP: scp ~/captures/*/*.hc22000 user@gpu-machine:~/

2. Crack with Hashcat on GPU:
   - hashcat -m 22000 capture.hc22000 rockyou.txt
   - Use rules for better success: hashcat -m 22000 -r best64.rule

3. Try additional attacks on failed captures:
   - Longer deauth attacks
   - Different times of day (more clients active)
   - Closer proximity to target

4. Clean up old captures:
   - Archive successful cracks
   - Delete captures older than 30 days

════════════════════════════════════════════════════════════════
                        END REPORT
════════════════════════════════════════════════════════════════
EOF

echo "[+] Report generated: $REPORT_FILE"

# Generate HTML version
cat > "$HTML_REPORT" <<'HTML_EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Kali Pi Operation Report</title>
    <style>
        body {
            font-family: 'Courier New', monospace;
            background: #1e1e1e;
            color: #00ff00;
            padding: 20px;
            max-width: 1200px;
            margin: 0 auto;
        }
        h1, h2 {
            color: #00ff00;
            border-bottom: 2px solid #00ff00;
            padding-bottom: 10px;
        }
        .summary {
            background: #2d2d2d;
            padding: 15px;
            border-left: 4px solid #00ff00;
            margin: 20px 0;
        }
        .capture {
            background: #2d2d2d;
            padding: 10px;
            margin: 10px 0;
            border-left: 4px solid #0066ff;
        }
        .success {
            border-left-color: #00ff00;
        }
        .failed {
            border-left-color: #ff0000;
        }
        .command {
            background: #1a1a1a;
            padding: 10px;
            font-family: monospace;
            border: 1px solid #444;
            margin: 5px 0;
        }
        .stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin: 20px 0;
        }
        .stat-box {
            background: #2d2d2d;
            padding: 15px;
            text-align: center;
            border: 1px solid #444;
        }
        .stat-value {
            font-size: 2em;
            color: #00ff00;
            font-weight: bold;
        }
    </style>
</head>
<body>
HTML_EOF

# Add content to HTML
cat >> "$HTML_REPORT" <<EOF
    <h1>⚡ KALI PI ZERO 2W - OPERATION REPORT ⚡</h1>
    
    <div class="summary">
        <h2>📊 Executive Summary</h2>
        <p><strong>Generated:</strong> $(date)</p>
        <p><strong>Operator:</strong> $(whoami)@$(hostname)</p>
        <p><strong>Uptime:</strong> $(uptime -p)</p>
    </div>
    
    <div class="stats">
        <div class="stat-box">
            <div>WPA Captures</div>
            <div class="stat-value">$WPA_TOTAL</div>
        </div>
        <div class="stat-box">
            <div>Valid Handshakes</div>
            <div class="stat-value">$WPA_WITH_HS</div>
        </div>
        <div class="stat-box">
            <div>PMKID Captures</div>
            <div class="stat-value">$PMKID_TOTAL</div>
        </div>
        <div class="stat-box">
            <div>Crackable Hashes</div>
            <div class="stat-value">$((WPA_WITH_HS + PMKID_VALID))</div>
        </div>
    </div>
    
    <h2>🎯 WPA Handshake Captures</h2>
EOF

# Add WPA captures to HTML
for cap in ~/captures/wpa/*.cap; do
    if [ -f "$cap" ]; then
        FILENAME=$(basename "$cap")
        
        if aircrack-ng "$cap" 2>&1 | grep -q "1 handshake"; then
            ESSID=$(aircrack-ng "$cap" 2>&1 | grep "ESSID" | head -1 | awk -F': ' '{print $2}')
            BSSID=$(aircrack-ng "$cap" 2>&1 | grep "BSSID" | head -1 | awk '{print $2}')
            
            cat >> "$HTML_REPORT" <<EOF
    <div class="capture success">
        <h3>✓ $FILENAME</h3>
        <p><strong>ESSID:</strong> $ESSID</p>
        <p><strong>BSSID:</strong> $BSSID</p>
        <p><strong>Status:</strong> Ready for cracking</p>
        <div class="command">hashcat -m 22000 ${FILENAME%.cap}.hc22000 wordlist.txt</div>
    </div>
EOF
        fi
    fi
done

cat >> "$HTML_REPORT" <<EOF
    
    <h2>🔑 PMKID Captures</h2>
EOF

# Add PMKID captures to HTML
for pmkid in ~/captures/pmkid/*.hc22000; do
    if [ -f "$pmkid" ] && [ -s "$pmkid" ]; then
        FILENAME=$(basename "$pmkid")
        HASH_COUNT=$(grep -c "WPA\*02" "$pmkid" 2>/dev/null || echo "0")
        
        cat >> "$HTML_REPORT" <<EOF
    <div class="capture success">
        <h3>✓ $FILENAME</h3>
        <p><strong>PMKIDs:</strong> $HASH_COUNT</p>
        <p><strong>Status:</strong> Ready for cracking</p>
        <div class="command">hashcat -m 22000 $FILENAME wordlist.txt</div>
    </div>
EOF
    fi
done

cat >> "$HTML_REPORT" <<'EOF'
    
    <h2>💻 System Statistics</h2>
    <div class="summary">
EOF

cat >> "$HTML_REPORT" <<EOF
        <p><strong>CPU Temperature:</strong> $(vcgencmd measure_temp | cut -d= -f2)</p>
        <p><strong>Memory:</strong> $(free -h | grep Mem: | awk '{print $3 " / " $2}')</p>
        <p><strong>Disk:</strong> $(df -h / | tail -1 | awk '{print $5 " used"}')</p>
        <p><strong>Storage (WPA):</strong> $(du -sh ~/captures/wpa/ 2>/dev/null | cut -f1)</p>
        <p><strong>Storage (PMKID):</strong> $(du -sh ~/captures/pmkid/ 2>/dev/null | cut -f1)</p>
    </div>
    
</body>
</html>
EOF

echo "[+] HTML report generated: $HTML_REPORT"
echo "[*] View in browser: file://$(realpath $HTML_REPORT)"

# Display summary to console
echo ""
echo "════════════════════════════════════════"
echo "         OPERATION SUMMARY"
echo "════════════════════════════════════════"
echo "WPA Captures:      $WPA_TOTAL"
echo "Valid Handshakes:  $WPA_WITH_HS"
echo "PMKID Captures:    $PMKID_TOTAL"
echo "Valid PMKIDs:      $PMKID_VALID"
echo "════════════════════════════════════════"
echo ""
echo "Reports saved to:"
echo "  Text: $REPORT_FILE"
echo "  HTML: $HTML_REPORT"
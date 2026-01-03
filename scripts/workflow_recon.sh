#!/bin/bash
# workflow_recon.sh - Complete reconnaissance workflow for headless operation

SESSION="recon"
DURATION=${1:-3600}  # Default 1 hour

echo "[*] Starting headless reconnaissance workflow"
echo "[*] Duration: ${DURATION}s ($(($DURATION/60)) minutes)"

# Create tmux session
tmux new-session -d -s "$SESSION" -n "Recon"

# Pane 0: System monitor
tmux send-keys -t "$SESSION:0.0" "~/scripts/system_monitor.sh" C-m

# Split and create pane 1: Airodump scan
tmux split-window -h -t "$SESSION:0"
tmux send-keys -t "$SESSION:0.1" "sleep 5 && ~/scripts/recon_scan.sh wlan1mon $DURATION" C-m

# Create new window for PMKID
tmux new-window -t "$SESSION:1" -n "PMKID"
tmux send-keys -t "$SESSION:1" "sleep 10 && ~/scripts/pmkid_attack.sh wlan1mon $DURATION" C-m

# Create new window for logs
tmux new-window -t "$SESSION:2" -n "Logs"
tmux send-keys -t "$SESSION:2" "tail -f ~/logs/*.log" C-m

echo "[*] Tmux session created: $SESSION"
echo "[*] Operations will run for $(($DURATION/60)) minutes"
echo "[*] Attach with: tmux attach -t $SESSION"
echo "[*] Or let it run headless and check back later"

# Optional: Auto-detach after showing status
sleep 2
tmux attach -t "$SESSION"
#!/bin/bash
# tmux_ops.sh - Launch comprehensive field operations tmux session

SESSION="ops"

# Check if session exists
tmux has-session -t $SESSION 2>/dev/null

if [ $? != 0 ]; then
    echo "[*] Creating new tmux session: $SESSION"
    
    # Create session with first window
    tmux new-session -d -s $SESSION -n "Monitor"
    
    # Window 0: Monitor (system status)
    tmux send-keys -t $SESSION:0 "~/scripts/system_monitor.sh" C-m
    
    # Window 1: Recon (passive scanning)
    tmux new-window -t $SESSION:1 -n "Recon"
    tmux send-keys -t $SESSION:1 "echo '[*] Ready for reconnaissance. Use: ~/scripts/recon_scan.sh'" C-m
    
    # Window 2: Capture (handshake capture)
    tmux new-window -t $SESSION:2 -n "Capture"
    tmux send-keys -t $SESSION:2 "echo '[*] Ready for capture. Use: ~/scripts/capture_handshake.sh wlan1mon CHANNEL BSSID ESSID'" C-m
    
    # Window 3: Attack (deauth/injection)
    tmux new-window -t $SESSION:3 -n "Attack"
    tmux send-keys -t $SESSION:3 "echo '[*] Ready for attacks. Use: ~/scripts/deauth.sh wlan1mon BSSID CHANNEL'" C-m
    
    # Window 4: PMKID
    tmux new-window -t $SESSION:4 -n "PMKID"
    tmux send-keys -t $SESSION:4 "echo '[*] Ready for PMKID attack. Use: ~/scripts/pmkid_attack.sh wlan1mon TIMEOUT'" C-m
    
    # Window 5: Logs
    tmux new-window -t $SESSION:5 -n "Logs"
    tmux send-keys -t $SESSION:5 "tail -f ~/logs/*.log" C-m
    
    # Window 6: Shell
    tmux new-window -t $SESSION:6 -n "Shell"
    
    # Split window 1 (Recon) into panes
    tmux select-window -t $SESSION:1
    tmux split-window -h
    tmux send-keys -t $SESSION:1.1 "watch -n 5 'iwconfig wlan1mon | grep -A 10 wlan1mon'" C-m
    
    # Split window 2 (Capture) into panes
    tmux select-window -t $SESSION:2
    tmux split-window -h
    tmux send-keys -t $SESSION:2.1 "watch -n 2 'ls -lht ~/captures/wpa/ | head -10'" C-m
    
    echo "[*] Tmux session '$SESSION' created"
    echo "[*] Attach with: tmux attach -t $SESSION"
    echo "[*] Detach with: Ctrl+A, then D"
else
    echo "[*] Session '$SESSION' already exists"
    echo "[*] Attach with: tmux attach -t $SESSION"
fi

# Attach to session
tmux attach -t $SESSION
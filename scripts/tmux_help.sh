#!/bin/bash
# tmux_help.sh - Quick reference for tmux operations

cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║                    TMUX QUICK REFERENCE                      ║
╚══════════════════════════════════════════════════════════════╝

PREFIX KEY: Ctrl+A (configured in ~/.tmux.conf)

=== SESSION MANAGEMENT ===
Create session:      tmux new -s ops
Attach to session:   tmux attach -t ops
Detach from session: Ctrl+A, then D
List sessions:       tmux ls
Kill session:        tmux kill-session -t ops

=== WINDOW MANAGEMENT ===
New window:          Ctrl+A, then C
Next window:         Ctrl+A, then N
Previous window:     Ctrl+A, then P
Select window:       Ctrl+A, then 0-9
Rename window:       Ctrl+A, then ,
Kill window:         Ctrl+A, then &

=== PANE MANAGEMENT ===
Split horizontal:    Ctrl+A, then |
Split vertical:      Ctrl+A, then -
Navigate panes:      Alt+Arrow keys (no prefix needed)
Kill pane:           Ctrl+A, then X
Toggle pane zoom:    Ctrl+A, then Z

=== SCROLLING ===
Enter scroll mode:   Ctrl+A, then [
Exit scroll mode:    Q
Search in scroll:    Ctrl+S (forward) or Ctrl+R (backward)

=== COPY MODE ===
Enter copy mode:     Ctrl+A, then [
Start selection:     Space
Copy selection:      Enter
Paste buffer:        Ctrl+A, then ]

=== USEFUL COMMANDS ===
Reload config:       Ctrl+A, then R
Show time:           Ctrl+A, then T
Command prompt:      Ctrl+A, then :

=== FIELD OPERATIONS WINDOWS ===
Window 0: Monitor   - System status dashboard
Window 1: Recon     - Network reconnaissance
Window 2: Capture   - Handshake capture
Window 3: Attack    - Deauth/injection attacks
Window 4: PMKID     - PMKID attacks
Window 5: Logs      - Real-time log monitoring
Window 6: Shell     - General command shell

=== QUICK START ===
1. Start operations:  ~/scripts/tmux_ops.sh
2. Detach session:    Ctrl+A, then D
3. Reconnect anytime: tmux attach -t ops
4. Put Pi in bag, operations continue running
5. SSH from phone to check status

EOF
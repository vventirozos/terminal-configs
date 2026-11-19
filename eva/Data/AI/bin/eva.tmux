#!/usr/bin/env bash
# eva dashboard: llama-top | host-top / ghost-agent log | ghost (2x2, tiled).
# Works from eva itself (runs locally) or from another machine (over ssh).
set -euo pipefail
SESSION=eva
HOST=eva
BIN=/Users/vasilis/Data/AI/bin
VENV_BIN=/Users/vasilis/Data/AI/.agent.venv/bin
LOG=/Users/vasilis/Data/AI/Logs/ghost-agent.log

attach() {
    [[ -n ${TMUX:-} ]] && exec tmux switch-client -t "=$SESSION"
    exec tmux attach -t "=$SESSION"
}
tmux has-session -t "=$SESSION" 2>/dev/null && attach

# `zsh -lc` is a login but NON-interactive shell: ~/.zshrc (which puts the
# agent venv on PATH) is never read, so `env python3` would resolve to Apple's
# /usr/bin/python3 3.9 — no prompt_toolkit/rich, too old for ghost's `match`.
# Put the venv first explicitly.
inner() { printf 'zsh -lc %q' "export PATH=$VENV_BIN:$BIN:\$PATH; $1"; }

# Pane command. The `sleep 3` runs LOCALLY, after the command (or ssh) exits,
# so a dead host / failed auth / crashing script can't respawn-loop flat out.
# (No `exec` in the local case: it would replace the shell and skip the sleep.
# Over ssh the `exec` runs on the remote side, so it is safe there.)
if [[ $(hostname -s | tr '[:upper:]' '[:lower:]') == "$HOST" ]]; then
    pane() { printf '%s; sleep 3' "$(inner "$1")"; }
else
    pane() {
        printf 'ssh -t -o ControlMaster=auto -o ControlPath=~/.ssh/cm-%%C -o ControlPersist=60 -o ServerAliveInterval=15 -o ServerAliveCountMax=3 %q %q; sleep 3' \
            "$HOST" "exec $(inner "$1")"
    }
fi

# Size the detached session to the current terminal (fallback if not a tty).
COLS=$(tput cols 2>/dev/null || echo 200)
LINES_=$(tput lines 2>/dev/null || echo 50)

# remain-on-exit + the respawn hook are set in the SAME tmux invocation that
# creates the session, before any split — otherwise a pane that dies in the
# first moments vanishes instead of being respawned.  Every option names the
# new session explicitly: without -t, running this from inside another tmux
# session would apply them to that session's window instead.
tmux new-session -d -s "$SESSION" -x "$COLS" -y "$LINES_" "$(pane "$BIN/llama-top")" \; \
     set-option -w -t "=$SESSION:" remain-on-exit on \; \
     set-hook -w -t "=$SESSION:" pane-died 'respawn-pane' \; \
     set-option -w -t "=$SESSION:" pane-border-status top \; \
     set-option -w -t "=$SESSION:" pane-border-format ' #{pane_index}: #{@name} '
P0=$(tmux display -p -t "=$SESSION:" '#{pane_id}')
# Panes are created in the order they should be numbered; "tiled" then lays
# them out in that order, row by row:   1 llama-top | 2 host-top
#                                       3 ghost-log | 4 ghost
# The re-layout also resizes every pane once, which makes the full-screen
# programs repaint cleanly.
P3=$(tmux split-window -d -P -F '#{pane_id}' -t "$P0" -h "$(pane "$BIN/host-top")")
P1=$(tmux split-window -d -P -F '#{pane_id}' -t "$P3" -v "$(pane "tail -F $LOG")")
P2=$(tmux split-window -d -P -F '#{pane_id}' -t "$P1" -v "$(pane "$BIN/ghost")")

# Labels live in a user option, so the programs can't overwrite them with
# their own terminal titles.
tmux set -p -t "$P0" @name llama-top \; set -p -t "$P1" @name ghost-log \; \
     set -p -t "$P2" @name ghost     \; set -p -t "$P3" @name host-top
tmux select-layout -t "$P0" tiled
tmux select-pane -t "$P2"   # ghost — the interactive one

attach

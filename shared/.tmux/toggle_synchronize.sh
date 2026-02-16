#!/bin/bash

tmux_status=$(tmux show-window-options)

if echo "$tmux_status" | grep -q "synchronize-panes on"; then
    tmux set-option synchronize-panes off
    tmux set-option window-style 'fg=colour244,bg=colour236'
    tmux set-option window-active-style 'fg=colour7,bg=colour234'
    tmux set-option pane-border-style 'fg=colour244,bg=colour236'
    tmux set-option pane-active-border-style 'fg=colour196,bg=colour88'
else
    tmux set-option synchronize-panes on
    tmux set-option window-style 'fg=colour227,bg=colour88'
    tmux set-option window-active-style 'fg=colour231,bg=colour52'
    tmux set-option pane-border-style 'fg=colour196,bg=colour88'
    tmux set-option pane-active-border-style 'fg=colour227,bg=colour196'
fi

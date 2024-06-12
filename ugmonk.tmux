#!/usr/bin/env bash
# _______________________________________________________________| locals |__ ;

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ______________________________________________________________| methods |__ ;

# ~/.tmux/plugins/tmux-myplugin/myplugin.tmux


#source "$CURRENT_DIR/scripts/helpers.sh"

set_keybindings() {
    tmux bind -N "Toggle nb todos menu" "r" run-shell "$CURRENT_DIR/scripts/ugmonk.sh menu"
}

main() {
	set_keybindings
}

main

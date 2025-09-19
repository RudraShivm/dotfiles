#!/bin/bash

# Dolphin Workspace Follower
# This script listens for workspace changes and moves Dolphin accordingly

WINDOW_CLASS="dolphin-custom"
TOGGLE_FILE="/tmp/dolphin_visible"
CONFIG_FILE="$HOME/.config/dolphin_toggle.conf"

# Load configuration
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    # Default values if config doesn't exist
    VISIBLE_X=592
    VISIBLE_Y=100
fi

# Function to move dolphin to current workspace
move_dolphin_to_workspace() {
    local new_workspace=$1
    
    # Check if dolphin exists and is supposed to be visible
    if [ -f "$TOGGLE_FILE" ]; then
        local window_exists=$(hyprctl clients | grep -c "class: $WINDOW_CLASS")
        
        if [ "$window_exists" -gt 0 ]; then
            echo "Moving Dolphin to workspace $new_workspace"
            hyprctl dispatch movetoworkspace "$new_workspace,class:^${WINDOW_CLASS}$"
            sleep 0.1
            hyprctl dispatch movewindowpixel "exact $VISIBLE_X $VISIBLE_Y,class:^${WINDOW_CLASS}$"
        fi
    fi
}

# Function to handle workspace change events
handle_workspace_change() {
    while read -r line; do
        if echo "$line" | grep -q "workspace>>"; then
            new_workspace=$(echo "$line" | cut -d',' -f2)
            move_dolphin_to_workspace "$new_workspace"
        fi
    done
}

echo "Starting Dolphin workspace follower..."
echo "Press Ctrl+C to stop"

# Listen to Hyprland events
if command -v socat >/dev/null 2>&1; then
    socat -U - UNIX-CONNECT:/tmp/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock | handle_workspace_change
else
    echo "Error: socat is required for workspace following"
    echo "Install with: sudo pacman -S socat"
    echo "Or use the polling alternative version instead"
    exit 1
fi

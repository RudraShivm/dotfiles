#!/bin/bash

# Get current workspace
current_workspace=$(hyprctl activeworkspace -j | jq '.id')

# Calculate previous workspace (limit between 1 and 10)
prev_workspace=$((current_workspace - 1))
if [ $prev_workspace -lt 1 ]; then
    prev_workspace=1
fi

# Move active window to previous workspace
hyprctl dispatch movetoworkspacesilent $prev_workspace

# Optional: Switch to the workspace after moving (remove this line if you want to stay on current workspace)
hyprctl dispatch workspace $prev_workspace

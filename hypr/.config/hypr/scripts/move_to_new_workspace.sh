#!/bin/bash

# Get current workspace
current_workspace=$(hyprctl activeworkspace -j | jq '.id')

# Calculate next workspace (limit to 10)
next_workspace=$((current_workspace + 1))
if [ $next_workspace -gt 10 ]; then
    next_workspace=10
fi

# Move active window to next workspace
hyprctl dispatch movetoworkspacesilent $next_workspace

# Optional: Switch to the workspace after moving (remove this line if you want to stay on current workspace)
hyprctl dispatch workspace $next_workspace

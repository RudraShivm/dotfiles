#!/bin/bash
# Get the current workspace ID
current_workspace=$(hyprctl activeworkspace | grep "workspace ID" | awk '{print $3}')
# Calculate the previous workspace ID (limit between 1 and 10)
prev_workspace=$((current_workspace - 1))
# Only switch if the previous workspace is 1 or greater
if [ "$prev_workspace" -ge 1 ]; then
    hyprctl dispatch workspace $prev_workspace
    # Move the active window to the previous workspace
    hyprctl dispatch movetoworkspace $prev_workspace
fi

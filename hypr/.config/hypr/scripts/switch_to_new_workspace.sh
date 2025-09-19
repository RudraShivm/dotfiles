#!/bin/bash
# Get the current workspace ID
current_workspace=$(hyprctl activeworkspace | grep "workspace ID" | awk '{print $3}')
# Get all workspace IDs
existing_workspaces=$(hyprctl workspaces | grep "workspace ID" | awk '{print $3}' | sort -n)
# Calculate the next workspace ID (limit to 10)
next_workspace=$((current_workspace + 1))
if [ $next_workspace -gt 10 ]; then
    next_workspace=10
fi

# Only proceed if we're not already at the maximum workspace
if [ $next_workspace -ne $current_workspace ]; then
    # Check if the next workspace exists
    if echo "$existing_workspaces" | grep -qw "$next_workspace"; then
        # If it exists, switch to it
        hyprctl dispatch workspace $next_workspace
    else
        # If it doesn't exist, create it by switching to it
        hyprctl dispatch workspace $next_workspace
    fi
    # Move the active window to the next workspace
    hyprctl dispatch movetoworkspace $next_workspace
fi

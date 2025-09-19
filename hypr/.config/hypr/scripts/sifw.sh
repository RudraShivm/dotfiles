#!/bin/bash

# Generalized Floating Window Toggle - pops a persistent single instance of an app across workspaces when keybind is pressed
# Features
# Tracks focus history in a file to restore focus when hiding the app
# Pops from history stack, discarding invalid windows, focuses first valid one
# If no valid in history, focuses any valid window on current workspace
# Configured via envs.conf file ($HOME/.config/hypr/envs.conf) using env = KEY,VALUE format

if [ $# -ne 1 ]; then
    echo "Usage: $0 <app_name>"
    exit 1
fi

APP_NAME=$1
CONFIG_FILE="$HOME/.config/hypr/envs.conf"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Config file $CONFIG_FILE not found"
    exit 1
fi

# Function to extract value from envs.conf
get_config_value() {
    local key=$1
    local value=$(grep "^env[[:space:]]*=[[:space:]]*$key," "$CONFIG_FILE" | awk -F',' '{print $2}' | tr -d '[:space:]')
    echo "$value"
}

# Load global config values
X_BOUNDARY=$(get_config_value "x_boundary")
Y_BOUNDARY=$(get_config_value "y_boundary")

# Load app-specific config values
LAUNCH_CMD=$(get_config_value "${APP_NAME}_launch_cmd")
WINDOW_CLASS=$(get_config_value "${APP_NAME}_window_class")
SHOW_X=$(get_config_value "${APP_NAME}_show_x")
SHOW_Y=$(get_config_value "${APP_NAME}_show_y")
HIDE_X=$(get_config_value "${APP_NAME}_hide_x")
HIDE_Y=$(get_config_value "${APP_NAME}_hide_y")
RESIZE_WIDTH=$(get_config_value "${APP_NAME}_resize_width")
RESIZE_HEIGHT=$(get_config_value "${APP_NAME}_resize_height")

# Validate required variables
if [ -z "$LAUNCH_CMD" ] || [ -z "$WINDOW_CLASS" ] || [ -z "$SHOW_X" ] || [ -z "$SHOW_Y" ] || [ -z "$HIDE_X" ] || [ -z "$HIDE_Y" ]; then
    echo "Incomplete config for app '$APP_NAME' in $CONFIG_FILE"
    exit 1
fi

TOGGLE_FILE="/tmp/${APP_NAME}_visible"
FOCUS_HISTORY_FILE="/tmp/${APP_NAME}_focus_history"

# Get current workspace ID
CURRENT_WORKSPACE=$(hyprctl activeworkspace | grep "workspace ID" | awk '{print $3}')

# Function to find app window
find_app_window() {
    local app_address=""
    app_address=$(hyprctl clients -j | jq -r ".[] | select(.class == \"$WINDOW_CLASS\") | .address" | head -1)

    if [ -n "$app_address" ] && [ "$app_address" != "null" ]; then
        echo "$app_address"
        return 0
    fi
    return 1
}

# Function to get current focused window
get_focused_window() {
    local focused_address=$(hyprctl activewindow -j | jq -r '.address')
    if [ -n "$focused_address" ] && [ "$focused_address" != "null" ]; then
        echo "$focused_address"
        return 0
    fi
    return 1
}

# Function to check if window exists, is on current workspace, and not off-screen
is_window_valid() {
    local window_address=$1
    if [ -z "$window_address" ]; then
        return 1
    fi
    local client_info=$(hyprctl clients -j | jq ".[] | select(.address == \"$window_address\")")
    if [ -z "$client_info" ] || [ "$client_info" = "null" ]; then
        return 1
    fi
    local window_workspace=$(echo "$client_info" | jq -r '.workspace.id')
    local window_x=$(echo "$client_info" | jq -r '.at[0]')
    local window_y=$(echo "$client_info" | jq -r '.at[1]')
    if [ "$window_workspace" = "$CURRENT_WORKSPACE" ] &&
       ( (( window_x + RESIZE_WIDTH <= X_BOUNDARY && window_x >= 0 )) ||
         (( window_y + RESIZE_HEIGHT <= Y_BOUNDARY && window_y >= 0 )) ); then
        return 0
    fi
    return 1
}

# Function to find any window on current workspace that is not off-screen
find_any_window_on_current_workspace() {
    local window_address=$(
        hyprctl clients -j | jq -r \
        --argjson cw "$CURRENT_WORKSPACE" \
        --argjson xb "$X_BOUNDARY" \
        --argjson yb "$Y_BOUNDARY" \
        --argjson rw "$RESIZE_WIDTH" \
        --argjson rh "$RESIZE_HEIGHT" \
        ".[] |
        select(
            .workspace.id == \$cw and
            (.at[0] + \$rw <= \$xb and .at[0] >= 0 or
             .at[1] + \$rh <= \$yb and .at[1] >= 0)
        ) |
        .address" | head -1
    )

    if [ -n "$window_address" ] && [ "$window_address" != "null" ]; then
        echo "$window_address"
        return 0
    fi
    return 1
}

# Function to hide app (move off-screen)
hide_app() {
    local app_address=$(find_app_window)
    
    if [ -n "$app_address" ]; then  
        echo "Hiding $APP_NAME"
        hyprctl dispatch movewindowpixel exact $HIDE_X $HIDE_Y,address:$app_address
        sleep 0.2
        hyprctl dispatch movetoworkspacesilent 0,"address:$app_address"
        
        # Restore focus using history stack
        local focused=0
        while [ -s "$FOCUS_HISTORY_FILE" ]; do
            local prev_window=$(tail -n 1 "$FOCUS_HISTORY_FILE")
            if [ -z "$prev_window" ]; then
                break
            fi
            if is_window_valid "$prev_window"; then
                echo "Restoring focus to previous window: $prev_window"
                hyprctl dispatch focuswindow address:$prev_window
                focused=1
                sed -i '$d' "$FOCUS_HISTORY_FILE"
                break
            else
                echo "Discarding invalid previous window: $prev_window"
                sed -i '$d' "$FOCUS_HISTORY_FILE"
            fi
        done
        
        if [ $focused -eq 0 ]; then
            local any_window=$(find_any_window_on_current_workspace)
            if [ -n "$any_window" ]; then
                echo "Focusing another window on current workspace: $any_window"
                hyprctl dispatch focuswindow address:$any_window
            else
                echo "No other windows found on current workspace"
            fi
        fi
        
        rm -f "$TOGGLE_FILE"
    else
        echo "No $APP_NAME window found to hide"
    fi
}

# Function to show app on current workspace
show_app() {
    local app_address=$(find_app_window)
    
    if [ -n "$app_address" ]; then
        echo "Showing $APP_NAME on workspace $CURRENT_WORKSPACE"
        
        # Save currently focused window to history
        local current_focused=$(get_focused_window)
        if [ -n "$current_focused" ] && [ "$current_focused" != "$app_address" ]; then
            echo "$current_focused" >> "$FOCUS_HISTORY_FILE"
        fi
        
        # Move to current workspace first
        hyprctl dispatch movetoworkspace "$CURRENT_WORKSPACE,address:$app_address"
        sleep 0.1
        
        # Position the window
        hyprctl dispatch movewindowpixel exact $SHOW_X $SHOW_Y,address:$app_address
        
        # Focus the window
        hyprctl dispatch focuswindow address:$app_address
        
        # Mark as visible
        touch "$TOGGLE_FILE"
    else
        echo "No $APP_NAME window found to show"
    fi
}

# Function to create new app instance
create_app() {
    echo "Creating new $APP_NAME instance..."
    
    # Save currently focused window to history
    local current_focused=$(get_focused_window)
    if [ -n "$current_focused" ]; then
        echo "$current_focused" >> "$FOCUS_HISTORY_FILE"
    fi
    # Launch app in background
    ${LAUNCH_CMD//_/ } &
    local app_pid=$!
    
    # Wait for window to appear
    local timeout=50  # 5 seconds
    local app_address=""
    
    while [ $timeout -gt 0 ]; do
        app_address=$(find_app_window)
        if [ -n "$app_address" ]; then
            echo "Found $APP_NAME window: $app_address"
            break
        fi
        sleep 0.1
        timeout=$((timeout - 1))
    done
    
    if [ $timeout -eq 0 ]; then
        echo "Error: Could not find $APP_NAME window within 5 seconds"
        echo "$APP_NAME may have failed to start or took too long to appear"
        exit 1
    fi
    
    # Small delay for window initialization
    sleep 0.3
    show_app
}

# Function to check if app is on current workspace
is_app_on_current_workspace() {
    local app_address=$(find_app_window)
    
    if [ -n "$app_address" ]; then
        local app_workspace=$(hyprctl clients -j | jq -r ".[] | select(.address == \"$app_address\") | .workspace.id")
        if [ "$app_workspace" = "$CURRENT_WORKSPACE" ]; then
            return 0
        else
            return 1
        fi
    fi
    return 1
}

# Main logic
echo "$APP_NAME Toggle - Current workspace: $CURRENT_WORKSPACE"

# Check if app window exists
app_address=$(find_app_window)

if [ -n "$app_address" ]; then
    if [ -f "$TOGGLE_FILE" ] && is_app_on_current_workspace; then
        hide_app
    else
        show_app
    fi
else
    create_app
fi

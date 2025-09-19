#!/bin/bash

# Python Environment Manager
# ========================
#
# A tool for managing Python virtual environments with an interactive interface.
#
# Installation
# -----------
# 1. Save this script to a location in your system, e.g.:
#    mkdir -p ~/.config/scripts/
#    curl -o ~/.config/scripts/pyenv_manager.sh https://raw.githubusercontent.com/yourusername/pyenv-manager/main/pyenv_manager.sh
#
# 2. Add the following to your ~/.bashrc or ~/.zshrc:
#    source ~/.config/scripts/pyenv_manager.sh
#
# 3. Reload your shell:
#    source ~/.bashrc  # or source ~/.zshrc
#
# Usage
# -----
# Run the tool using either:
#   pyenv  # full command
#   py     # short alias
#
# Features
# --------
# - Create new virtual environments
# - Activate existing environments
# - Delete environments
# - Scan directories for existing environments
# - Auto-detection of Python versions
# - Path completion for scanning directories
#
# Configuration
# ------------
# Environments are tracked in: ~/.pyenv_manager/envs.txt
# No additional configuration needed.

pyenv() {
    # Color palette for beautiful output
    local RESET='\033[0m'
    local BOLD='\033[1m'
    local DIM='\033[2m'
    local ITALIC='\033[3m'
    local UNDERLINE='\033[4m'
    
    # Vibrant colors
    local RED='\033[38;5;196m'
    local GREEN='\033[38;5;46m'
    local BLUE='\033[38;5;51m'
    local PURPLE='\033[38;5;129m'
    local ORANGE='\033[38;5;208m'
    local YELLOW='\033[38;5;226m'
    local PINK='\033[38;5;198m'
    local CYAN='\033[38;5;87m'
    
    # Gradient effect for headers
    local GRAD1='\033[38;5;57m'
    local GRAD2='\033[38;5;93m'
    local GRAD3='\033[38;5;129m'
    local GRAD4='\033[38;5;165m'
    
    # Unicode symbols
    local SNAKE="🐍"
    local ROCKET="🚀"
    local SPARKLES="✨"
    local GEAR="⚙️"
    local FOLDER="📁"
    local PLUS="➕"
    local ARROW="➤"
    local CHECKMARK="✅"
    local CROSS="❌"
    local THINKING="🤔"
    
    # Function to create animated header
    print_header() {
        echo -e "\n${GRAD1}╭──────────────────────────────────────╮${RESET}"
        echo -e   "${GRAD2}│  ${SNAKE} ${BOLD}${GRAD3}Python Environment Manager${RESET}${GRAD2} ${SPARKLES}    │${RESET}"
        echo -e   "${GRAD4}╰──────────────────────────────────────╯${RESET}\n"
    }
    
    # Function to clear screen and show header
    reset_screen() {
        clear
        print_header
    }

    # Function to create spinning loader with complex animation
    spinner() {
        local pid=$1
        local delay=0.08
        local phase=0
        local frame=0
        
        # Spinner patterns for different phases
        local spin1='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
        local spin2='◐◓◑◒'
        local spin3='▉▊▋▌▍▎▏▎▍▌▋▊▉'
        local spin4='←↖↑↗→↘↓↙'
        local dots='⣾⣽⣻⢿⡿⣟⣯⣷'
        
        # Colors for gradient effect
        local colors=(
            '\033[38;5;39m'  # Azure
            '\033[38;5;38m'
            '\033[38;5;37m'
            '\033[38;5;36m'
            '\033[38;5;35m'  # Emerald
        )
        
        # Progress messages
        local messages=(
            "Starting"
            "Processing"
            "Analyzing"
            "Finalizing"
        )
        
        while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
            # Calculate current phase (changes every 12 frames)
            local current_phase=$((frame / 12 % 4))
            
            # Select spinner based on phase
            local current_spin
            case $current_phase in
                0) current_spin="$spin1" ;;
                1) current_spin="$spin2" ;;
                2) current_spin="$spin3" ;;
                3) current_spin="$spin4" ;;
            esac
            
            # Get current spinner character
            local spin_char="${current_spin:$((frame % ${#current_spin})):1}"
            
            # Get progress dots
            local dot_char="${dots:$((frame % ${#dots})):1}"
            
            # Calculate color gradient position
            local color_pos=$((frame % ${#colors[@]}))
            local color="${colors[$color_pos]}"
            
            # Build the animation string
            printf "\r${color}${spin_char} ${messages[$current_phase]} ${dot_char} ${RESET}"
            
            ((frame++))
            sleep $delay
        done
        printf "\r${RESET}   \r"  # Clear the line when done
    }
    
    # Function to display environments with beautiful formatting
    display_envs() {
        local envs_to_display=("$@")
        local count=${#envs_to_display[@]}
        
        echo -e "${BLUE}${BOLD}Found $count environment(s):${RESET}\n"
        
        for i in "${!envs_to_display[@]}"; do
            local env_path="${envs_to_display[$i]}"
            local env_name=$(basename "$env_path")
            local python_version=""
            
            # Get Python version if possible
            if [ -f "$env_path/bin/python" ]; then
                python_version=$("$env_path/bin/python" --version 2>&1 | cut -d' ' -f2)
            fi
            
            # Beautiful environment display
            printf "${PURPLE}%2d${RESET}) ${FOLDER} ${GREEN}${BOLD}%-20s${RESET}" $((i+1)) "$env_name"
            
            if [ -n "$python_version" ]; then
                printf "${DIM} │ ${YELLOW}Python $python_version${RESET}"
            fi
            
            printf "${DIM} │ ${CYAN}%s${RESET}\n" "$env_path"
        done
        
        echo ""
    }
    
    # Function to create new environment with interactive setup
    create_new_env() {
        while true; do
            print_header
            echo -e "${ROCKET} ${BOLD}${GREEN}Creating a new Python environment${RESET}\n"
            
            # Get environment name
            echo -e "${BLUE}${BOLD}Step 1:${RESET} Environment name"
            echo -e "${DIM}Enter a name for your new environment:${RESET}"
            printf "${ARROW} "
            read -r env_name
            
            if [ -z "$env_name" ]; then
                echo -e "${RED}${CROSS} Environment name cannot be empty!${RESET}"
                echo -e "${DIM}Press Enter to try again...${RESET}"
                read -r
                continue
            fi
            
            # Choose Python version
            echo -e "\n${BLUE}${BOLD}Step 2:${RESET} Python version"
            echo -e "${DIM}Available Python versions:${RESET}"
            
            local python_versions=()
            local version_commands=()
            
            # Detect available Python versions
            for cmd in python python3 python3.{12,11,10,9,8}; do
                if command -v $cmd >/dev/null 2>&1; then
                    local ver=$($cmd --version 2>&1 | cut -d' ' -f2)
                    if [[ ! " ${python_versions[*]} " =~ " ${ver} " ]]; then
                        python_versions+=("$ver")
                        version_commands+=("$cmd")
                    fi
                fi
            done
            
            if [ ${#python_versions[@]} -eq 0 ]; then
                echo -e "${RED}${CROSS} No Python installations found!${RESET}"
                echo -e "${DIM}Press Enter to try again...${RESET}"
                read -r
                continue
            fi
            
            while true; do
                for i in "${!python_versions[@]}"; do
                    printf "${PURPLE}%2d${RESET}) ${YELLOW}Python ${python_versions[$i]}${RESET} ${DIM}(${version_commands[$i]})${RESET}\n" $((i+1))
                done
                
                printf "\n${ARROW} Select Python version (1-${#python_versions[@]}): "
                read -r python_choice
                
                if ! [[ "$python_choice" =~ ^[0-9]+$ ]] || [ "$python_choice" -lt 1 ] || [ "$python_choice" -gt ${#python_versions[@]} ]; then
                    echo -e "${RED}${CROSS} Invalid selection!${RESET}"
                    echo -e "${DIM}Press Enter to try again...${RESET}"
                    read -r
                    continue
                fi
                break
            done
            
            local selected_python="${version_commands[$((python_choice-1))]}"
            
            # Choose location
            while true; do
                echo -e "\n${BLUE}${BOLD}Step 3:${RESET} Environment location"
                echo -e "${DIM}Choose where to create the environment:${RESET}"
                echo -e "${PURPLE} 1${RESET}) ${HOME}/.virtualenvs/${env_name} ${DIM}(recommended)${RESET}"
                echo -e "${PURPLE} 2${RESET}) ./${env_name} ${DIM}(current directory)${RESET}"
                echo -e "${PURPLE} 3${RESET}) Custom path"
                
                printf "\n${ARROW} Select location (1-3): "
                read -r location_choice
                
                local env_path
                case $location_choice in
                    1) env_path="$HOME/.virtualenvs/$env_name" ;;
                    2) env_path="./$env_name" ;;
                    3) 
                        echo -e "${DIM}Enter custom path:${RESET}"
                        printf "${ARROW} "
                        read -r custom_path
                        custom_path="${custom_path/#\~/$HOME}"
                        if [ -z "$custom_path" ] || ! mkdir -p "$custom_path" 2>/dev/null; then
                            echo -e "${RED}${CROSS} Invalid or unwritable path!${RESET}"
                            echo -e "${DIM}Press Enter to try again...${RESET}"
                            read -r
                            continue
                        fi
                        env_path="$custom_path"
                        ;;
                    *) 
                        echo -e "${RED}${CROSS} Invalid selection!${RESET}"
                        echo -e "${DIM}Press Enter to try again...${RESET}"
                        read -r
                        continue
                        ;;
                esac
                env_path="$(realpath "$env_path")"
                break
            done
            
            # Create the environment with progress indication
            echo -e "\n${GEAR} ${BOLD}Creating environment...${RESET}"
            
            # Create directory if needed
            mkdir -p "$(dirname "$env_path")" 2>/dev/null
            
            # Animated creation process
            echo -e "${DIM}Creating virtual environment at: ${env_path}${RESET}"
            
            # Run venv creation in background with spinner
            $selected_python -m venv "$env_path" 2>/dev/null &
            spinner $!
            wait $!
            
            if [ $? -eq 0 ]; then
                echo -e "${CHECKMARK} ${GREEN}Environment created successfully!${RESET}"
                
                # Add to envs file and current session
                echo "$env_path" >> "$ENVS_FILE"
                envs+=("$env_path")
                seen_envs["$env_path"]=1
                
                # Ask about immediate activation
                while true; do
                    echo -e "\n${THINKING} ${BOLD}Activate the environment now?${RESET} ${DIM}(y/N)${RESET}"
                    printf "${ARROW} "
                    read -r activate_now
                    
                    if [[ "$activate_now" =~ ^[Yy]$ ]]; then
                        source "$env_path/bin/activate"
                        echo -e "${ROCKET} ${GREEN}Environment '${env_name}' activated!${RESET}"
                        echo -e "${DIM}Python: $(python --version)${RESET}"
                        echo -e "${DIM}Path: $(which python)${RESET}"
                        break
                    elif [[ "$activate_now" =~ ^[Nn]$ || -z "$activate_now" ]]; then
                        echo -e "${BLUE}${ITALIC}To activate later, run: ${RESET}${BOLD}source $env_path/bin/activate${RESET}"
                        break
                    else
                        echo -e "${RED}${CROSS} Invalid input! Please enter 'y' or 'n'.${RESET}"
                        echo -e "${DIM}Press Enter to try again...${RESET}"
                        read -r
                        continue
                    fi
                done
                break
            else
                echo -e "${CROSS} ${RED}Failed to create environment!${RESET}"
                echo -e "${DIM}Press Enter to try again...${RESET}"
                read -r
                continue
            fi
        done
    }

    # Function to scan a location and add environments
    scan_location() {
        while true; do
            echo -e "${BLUE}${BOLD}Scan location for environments${RESET}"
            echo -e "${DIM}Enter directory path to scan (default: current directory):${RESET}"
            printf "${ARROW} "
            # Enable path completion
            read -e -r scan_path

            # If scan_path is empty, default to the current directory
            if [ -z "$scan_path" ]; then
                scan_path="$PWD"
                echo -e "${DIM}Scanning current directory: ${scan_path}${RESET}"
            fi

            # Replace ~ with the home directory
            scan_path="${scan_path/#\~/$HOME}"
            
            if [ ! -d "$scan_path" ]; then
                echo -e "\n${RED}${CROSS} Invalid directory! Press Enter to try again...${RESET}"
                read -r
                reset_screen
                continue
            fi
            
            local found_envs_paths=()
            
            # Check if the target path is a virtual environment
            if [ -d "$scan_path" ] && [ -f "$scan_path/bin/activate" ] && [ -f "$scan_path/bin/python" ]; then
                found_envs_paths+=("$(realpath "$scan_path")")
            else
                # Scan immediate children for virtual environments
                for dir in "$scan_path"/*; do
                    if [ -d "$dir" ] && [ -f "$dir/bin/activate" ] && [ -f "$dir/bin/python" ]; then
                        found_envs_paths+=("$(realpath "$dir")")
                    fi
                done
            fi
            
            local added=0
            for new_env in "${found_envs_paths[@]}"; do
                # Check if env is already in our seen list using the associative array
                if [[ -z "${seen_envs[$new_env]}" ]]; then
                    envs+=("$new_env")
                    seen_envs["$new_env"]=1
                    echo "$new_env" >> "$ENVS_FILE"
                    added=$((added+1))
                fi
            done
            
            if [ $added -gt 0 ]; then
                echo -e "${GREEN}${CHECKMARK} Added $added new environment(s)!${RESET}"
            else
                echo -e "${YELLOW}No new environments found.${RESET}"
            fi
            break
        done
    }
    
    # Function to delete an environment
    delete_env() {
        if [ ${#envs[@]} -eq 0 ]; then
            echo -e "${RED}No environments to delete!${RESET}"
            echo -e "${DIM}Press Enter to continue...${RESET}"
            read -r
            return
        fi
        
        while true; do
            display_envs "${envs[@]}"
            
            printf "${ARROW} Select environment to delete (1-${#envs[@]}): "
            read -r del_choice
            
            if [[ "$del_choice" =~ ^[0-9]+$ ]] && [ "$del_choice" -ge 1 ] && [ "$del_choice" -le ${#envs[@]} ]; then
                local del_path="${envs[$((del_choice-1))]}"
                local env_name=$(basename "$del_path")
                
                while true; do
                    echo -e "${YELLOW}${BOLD}Warning:${RESET} This will permanently delete the environment '$env_name' and all its files!"
                    echo -e "${DIM}Path: $del_path${RESET}"
                    printf "${ARROW} Confirm deletion? (y/N): "
                    read -r confirm
                    
                    if [[ "$confirm" =~ ^[Yy]$ ]]; then
                        rm -rf "$del_path"
                        unset 'envs[$((del_choice-1))]'
                        envs=("${envs[@]}") # Re-index the array
                        
                        # Rewrite the envs file from the updated array
                        >"$ENVS_FILE"
                        for env in "${envs[@]}"; do
                            echo "$env" >> "$ENVS_FILE"
                        done
                        echo -e "${CHECKMARK} ${GREEN}Environment deleted successfully!${RESET}"
                        break
                    elif [[ "$confirm" =~ ^[Nn]$ || -z "$confirm" ]]; then
                        echo -e "${BLUE}Deletion cancelled.${RESET}"
                        break
                    else
                        echo -e "${RED}${CROSS} Invalid input! Please enter 'y' or 'n'.${RESET}"
                        echo -e "${DIM}Press Enter to try again...${RESET}"
                        read -r
                        continue
                    fi
                done
                break
            else
                echo -e "${RED}${CROSS} Invalid selection!${RESET}"
                echo -e "${DIM}Press Enter to try again...${RESET}"
                read -r
                continue
            fi
        done
    }
    
    # Main function logic
    reset_screen
    
    local CONFIG_DIR="$HOME/.pyenv_manager"
    local ENVS_FILE="$CONFIG_DIR/envs.txt"
    
    mkdir -p "$CONFIG_DIR"
    
    local envs=()
    # Use an associative array for fast, O(1) lookups of existing envs
    declare -A seen_envs
    
    # Initialize if no file exists
    if [ ! -f "$ENVS_FILE" ]; then
        echo -e "${DIM}Performing first-time scan...${RESET}"
        
        # Start scan in background with spinner
        {
            local search_paths=(
                "$HOME/.virtualenvs"
                "$HOME/venvs"
                "$HOME/.pyenv/versions"
                "$PWD"
            )
        local init_envs=()
        for path in "${search_paths[@]}"; do
            if [ -d "$path" ]; then
                while IFS= read -r -d '' env_path; do
                    if [ -f "$env_path/bin/activate" ] && [ -f "$env_path/bin/python" ]; then
                        init_envs+=("$(realpath "$env_path")")
                    fi
                done < <(find "$path" -maxdepth 2 -type d -name "bin" -exec dirname {} \; -print0 2>/dev/null)
            fi
        done
        # Sort and find unique paths, then write to the file
        IFS=$'\n' init_envs=($(printf '%s\n' "${init_envs[@]}" | sort -u))
        > "$ENVS_FILE"
        for env in "${init_envs[@]}"; do
            echo "$env" >> "$ENVS_FILE"
        done
        } &
        spinner $!
        wait $!
    fi
    
    # Load environments from envs.txt into the array and the associative array
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            envs+=("$line")
            seen_envs["$line"]=1
        fi
    done < "$ENVS_FILE"
    
    # Validate environments to remove any that have been deleted manually
    local valid_envs=()
    local removed=false
    for env_path in "${envs[@]}"; do
        if [ -d "$env_path" ] && [ -f "$env_path/bin/activate" ] && [ -f "$env_path/bin/python" ]; then
            valid_envs+=("$env_path")
        else
            removed=true
        fi
    done

    # Auto-detect environments in current directory
    if [ -f "$PWD/bin/activate" ] && [ -f "$PWD/bin/python" ]; then
        local current_env="$(realpath "$PWD")"
        if [[ -z "${seen_envs[$current_env]}" ]]; then
            valid_envs+=("$current_env")
            seen_envs["$current_env"]=1
        fi
    fi
    # Check immediate child directories for virtual environments
    for dir in "$PWD"/*; do
        if [ -d "$dir" ] && [ -f "$dir/bin/activate" ] && [ -f "$dir/bin/python" ]; then
            local child_env="$(realpath "$dir")"
            if [[ -z "${seen_envs[$child_env]}" ]]; then
                valid_envs+=("$child_env")
                seen_envs["$child_env"]=1
            fi
        fi
    done

    envs=("${valid_envs[@]}")
    # If any invalid environments were found, update the array and rewrite the file
    if $removed; then
        echo -e "${YELLOW}Some environments were removed as they are no longer valid.${RESET}\n"
        envs >"$ENVS_FILE"
        for env in "${envs[@]}"; do
            echo "$env" >> "$ENVS_FILE"
        done
    fi
    
    # Display and actions
    if [ ${#envs[@]} -eq 0 ]; then
        echo -e "${THINKING} ${YELLOW}No Python environments found!${RESET}\n"
    else
        display_envs "${envs[@]}"
    fi
    
    while true; do
        echo -e "${DIM}──────────────────────────────────────────────${RESET}"
        echo -e "${BLUE}${BOLD}Actions:${RESET}"
        
        local action_num=1
        if [ ${#envs[@]} -gt 0 ]; then
            echo -e "${PURPLE}${action_num}${RESET}) ${BOLD}Activate environment${RESET}"
            action_num=$((action_num+1))
            echo -e "${PURPLE}${action_num}${RESET}) ${BOLD}Delete environment${RESET}"
            action_num=$((action_num+1))
        fi
        echo -e "${PURPLE}${action_num}${RESET}) ${BOLD}Create new environment${RESET}"
        action_num=$((action_num+1))
        echo -e "${PURPLE}${action_num}${RESET}) ${BOLD}Scan location for environments${RESET}"
        action_num=$((action_num+1))
        echo -e "${PURPLE}${action_num}${RESET}) ${BOLD}Quit${RESET}"
        
        local max_action=$action_num
        printf "\n${ARROW} Select action (1-${max_action}): "
        read -r action_choice
        
        if ! [[ "$action_choice" =~ ^[0-9]+$ ]] || [ "$action_choice" -lt 1 ] || [ "$action_choice" -gt $max_action ]; then
            echo -e "\n${RED}${CROSS} Invalid selection! Press Enter to try again...${RESET}"
            read -r
            reset_screen
            display_envs "${envs[@]}"
            continue
        fi
        
        local action=""
        local offset=0
        if [ ${#envs[@]} -gt 0 ]; then
            if [ "$action_choice" = "1" ]; then action="activate"; fi
            if [ "$action_choice" = "2" ]; then action="delete"; fi
            offset=2
        fi
        if [ "$action_choice" = "$((offset + 1))" ]; then action="create"; fi
        if [ "$action_choice" = "$((offset + 2))" ]; then action="scan"; fi
        if [ "$action_choice" = "$((offset + 3))" ]; then return; fi
        
        case $action in
            activate)
                while true; do
                    local choice
                    if [ ${#envs[@]} -eq 1 ]; then
                        choice=1
                        echo -e "${DIM}Activating the only available environment...${RESET}\n"
                    else
                        printf "${ARROW} Select environment to activate (1-${#envs[@]}): "
                        read -r choice
                    fi
                    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#envs[@]} ]; then
                        local selected_env="${envs[$((choice-1))]}"
                        local env_name=$(basename "$selected_env")
                        
                        # Activate and exit the function so the change persists in the user's shell
                        source "$selected_env/bin/activate"
                        clear
                        print_header
                        echo -e "${CHECKMARK} ${GREEN}${BOLD}Environment '$env_name' activated!${RESET}"
                        echo -e "${DIM}Python: $(python --version)${RESET}"
                        echo -e "${DIM}Pip: $(pip --version | cut -d' ' -f1-2)${RESET}"
                        return
                    else
                        echo -e "${CROSS} ${RED}Invalid selection!${RESET}"
                        echo -e "${DIM}Press Enter to try again...${RESET}"
                        read -r
                        continue
                    fi
                done
                ;;
            delete)
                delete_env
                ;;
            create)
                create_new_env
                ;;
            scan)
                scan_location
                ;;
        esac
        
        # After an action (that doesn't exit), redisplay the main menu
        reset_screen
        display_envs "${envs[@]}"
    done
}

alias py='pyenv'


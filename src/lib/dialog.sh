#!/usr/bin/env bash

# =============================================================================
# Pimp My Ubuntu - Common Utilities
# =============================================================================
# Description: Common utility functions used across installation procedures
# Author: Multitec-UA
# Repository: https://github.com/Multitec-UA/pimp_my_ubuntu
# License: MIT
# =============================================================================


# Display menu and get user selection
dialog_show_menu() {
    local procedures=("$@")
    local choices=()
    local cmd=(dialog --title "Pimp My Ubuntu" --backtitle "Software Selection" --separate-output --checklist "Select software to install:" 22 76 16)
    
    for proc in "${procedures[@]}"; do
        local name=$(basename "${proc}" .sh)
        local desc=""
        
        # Try to extract description from the file
        if grep -q "readonly SOFTWARE_DESCRIPTION=" "${proc}"; then
            desc=$(grep "readonly SOFTWARE_DESCRIPTION=" "${proc}" | cut -d'"' -f2)
        fi
        
        cmd+=("${name}" "${desc:-"No description available"}" off)
    done
    
    choices=$("${cmd[@]}" 2>&1 >/dev/tty)
    echo "${choices}"
}

# Display a progress bar
# Usage: show_progress 45 "Installing..."
dialog_show_progress() {
    local percent=$1
    local message=${2:-""}
    local w=50 # Width of the progress bar
    local fill=$((w * percent / 100))
    local empty=$((w - fill))
    
    printf "\r[%s%s] %d%% %s" \
        "$(printf "#%.0s" $(seq 1 $fill))" \
        "$(printf "=%.0s" $(seq 1 $empty))" \
        "$percent" \
        "$message"
}



# Get user confirmation
# Usage: if get_confirmation "Do you want to proceed?"; then echo "Proceeding..."; fi
dialog_get_confirmation() {
    local prompt=${1:-"Do you want to continue?"}
    local response
    
    if is_terminal; then
        read -rp "${prompt} [y/N] " response
        case "$response" in
            [yY][eE][sS]|[yY]) return 0 ;;
            *) return 1 ;;
        esac
    else
        # Non-interactive mode, assume yes
        return 0
    fi
}
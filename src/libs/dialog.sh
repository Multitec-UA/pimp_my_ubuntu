#!/usr/bin/env bash

# =============================================================================
# Pimp My Ubuntu - Common Utilities
# =============================================================================
# Description: Common utility functions used across installation procedures
# Author: Multitec-UA
# Repository: https://github.com/Multitec-UA/pimp_my_ubuntu
# License: MIT
# =============================================================================

# Show welcome screen
# Returns: 0 if procedures exist, 1 if no procedures found
dialog_show_welcome() {
    dialog --title "Pimp My Ubuntu" --backtitle "Installation Script" \
           --msgbox "Welcome to Pimp My Ubuntu!\n\nThis script will help you set up your Ubuntu system with your preferred software and configurations." 10 60

    # Check if there are any procedures to install
    if [[ ${#GLOBAL_INSTALLATION_STATUS[@]} -eq 0 ]]; then
        dialog --title "Error" --backtitle "Pimp My Ubuntu" \
               --msgbox "No installation procedures found!" 8 40
        return 1
    fi
    return 0
}

# Show procedure selection screen and update GLOBAL_INSTALLATION_STATUS
# Returns: 0 on success, 1 if user cancels
dialog_show_procedure_selector() {
    local procedures=("$@")
    local choices=()
    local cmd=(dialog --title "Pimp My Ubuntu" --backtitle "Software Selection" \
              --separate-output --checklist "Select software to install:" 22 76 16)
    
    for proc in "${procedures[@]}"; do
        cmd+=("$proc" "Select to install" off)
    done
    
    # Run dialog and capture output
    choices=$("${cmd[@]}" 2>&1 >/dev/tty)
    local status=$?
    
    # Check if user cancelled
    if [[ $status -ne 0 ]]; then
        dialog --title "Cancelled" --backtitle "Pimp My Ubuntu" \
               --msgbox "Installation cancelled by user." 8 40
        return 1
    fi
    
    # Check if no selection was made
    if [[ -z "$choices" ]]; then
        dialog --title "No Selection" --backtitle "Pimp My Ubuntu" \
               --msgbox "Please select at least one software to continue." 8 50
        return 1
    fi
    
    # Return selected choices
    echo "${choices}"
    return 0
}

# Display menu and get user selection
dialog_show_menu() {
    local procedures=("$@")
    local choices=()
    local cmd=(dialog --title "Pimp My Ubuntu" --backtitle "Software Selection" --separate-output --checklist "Select software to install:" 22 76 16)
    
    for proc in "${procedures[@]}"; do
        local name=$(basename "${proc}" .sh)
        cmd+=("${name}" "Select to install" off)
    done
    
    # Run dialog and capture both output and exit status
    choices=$("${cmd[@]}" 2>&1 >/dev/tty) || return $?
    
    # Return the selected choices
    echo "${choices}"
    return 0
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
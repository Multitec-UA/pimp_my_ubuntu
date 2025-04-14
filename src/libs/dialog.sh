#!/usr/bin/env bash

# =============================================================================
# Pimp My Ubuntu - Common Utilities
# =============================================================================
# Description: Common utility functions used across installation procedures
# Author: Multitec-UA
# Repository: https://github.com/Multitec-UA/pimp_my_ubuntu
# License: MIT
# =============================================================================

readonly DIALOG_VERSION="1.1.21"

# Show welcome screen
# Returns: 0 if procedures exist, 1 if no procedures found
dialog_show_welcome_screen() {
    dialog --title "Pimp My Ubuntu" --backtitle "Installation Script" \
           --msgbox "Welcome to Pimp My Ubuntu!\n\nThis script will help you set up your Ubuntu system with your preferred software and configurations." 10 60

    return 0
}

# Show procedure selection screen and update _dialog_proc_status
# Returns: 0 on success, 1 if user cancels
dialog_show_procedure_selector_screen() {
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


# Display the current status of all installation procedures
# Shows a dialog with the list of procedures and their current states
# Usage: dialog_show_procedure_selector_status_screen "name_of_the_array"
# Returns: 0 on success, 1 on cancel/ESC
dialog_show_procedure_selector_status_screen() {
    # Dialog exit status codes
    local DIALOG_OK=0
    local DIALOG_CANCEL=1
    local DIALOG_ESC=255

    local -n _dialog_show_proc_status=${1:-}
    
    # Check if there are any procedures to display
    if [[ ${#_dialog_show_proc_status[@]} -eq 0 ]]; then
        dialog --title "Installation Status" \
               --backtitle "Pimp My Ubuntu" \
               --msgbox "No installation procedures found." 8 45
        return 1
    fi
    
    # Find the longest procedure name for proper alignment
    local max_length=0
    local proc_length=0
    
    for proc_name in "${!_dialog_show_proc_status[@]}"; do
        proc_length=${#proc_name}
        if [[ $proc_length -gt $max_length ]]; then
            max_length=$proc_length
        fi
    done
    
    # Add padding for visual separation
    max_length=$((max_length + 3))
    
    # Create menu items array for dialog
    local menu_items=()
    local tag_num=1
    local status_display=""
    local formatted_item=""
    
    # Add each procedure with its status to the menu items
    for proc_name in "${!_dialog_show_proc_status[@]}"; do
        status="${_dialog_show_proc_status[$proc_name]}"
        status_display=$(dialog_get_status_icon "${status}")
        
        # Format item with proper alignment
        printf -v formatted_item "%-${max_length}s %s" "${proc_name}" "${status_display}"
        menu_items+=("$tag_num" "$formatted_item")
        ((tag_num++))
    done
    
    # Calculate appropriate menu height (min 12, max 20)
    local menu_height=$(( ${#_dialog_show_proc_status[@]} + 7 ))
    [[ $menu_height -lt 12 ]] && menu_height=12
    [[ $menu_height -gt 20 ]] && menu_height=20
    
    # Display the menu dialog with wider width to accommodate aligned text
    exec 3>&1
    selection=$(dialog --clear \
                      --title "Installation Status" \
                      --backtitle "Pimp My Ubuntu" \
                      --colors \
                      --ok-label "Continue" \
                      --cancel-label "Cancel" \
                      --menu "Current status of installation procedures:" \
                      $menu_height 70 ${#_dialog_show_proc_status[@]} \
                      "${menu_items[@]}" \
                2>&1 1>&3)
    
    # Get the exit status
    local exit_status=$?
    exec 3>&-
    
    # Update the MAIN_DIALOG_MENU_SELECTION array
    MAIN_DIALOG_MENU_SELECTION=(${menu_items[$selection]})

    # Handle the exit status
    case $exit_status in
        $DIALOG_OK)
            # User clicked "Continue"
            return 0
            ;;
        $DIALOG_CANCEL)
            # User clicked "Cancel"
            return 1
            ;;
        $DIALOG_ESC)
            # User pressed ESC
            return 1
            ;;
        *)
            # Unknown status
            return 1
            ;;
    esac
    
    return 0
}

# Function to get the status icon based on the status
dialog_get_status_icon() {
    local status="$1"
    case "${status}" in
        "SUCCESS")
            echo "✅ SUCCESS"
            ;;
        "FAILED")
            echo "❌ FAILED"
            ;;
        "PENDING")
            echo "⏳ PENDING"
            ;;
        "INIT")
            echo "➕ INIT"
            ;;
        "SKIPPED")
            echo "⏭️ SKIPPED"
            ;;
        *)
            echo "${status}"
            ;;
    esac
}
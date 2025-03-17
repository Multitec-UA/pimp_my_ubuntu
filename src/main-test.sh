#!/usr/bin/env bash

# =============================================================================
# Pimp My Ubuntu - Main Installation Script
# =============================================================================
# Description: Automates the setup of a fresh Ubuntu 24.04 installation
# Author: Multitec-UA
# Repository: https://github.com/Multitec-UA/pimp_my_ubuntu
# License: MIT
# =============================================================================

# Strict mode
set -euo pipefail


main() {
    _source_lib "/src/lib/global.sh"
    _source_lib "/src/lib/main_utils.sh"
    _source_lib "/src/lib/dialog.sh"

    # Check if the script is running with root privileges
    main_check_root

    # Initialize logging
    main_setup_logging

    # Install basic dependencies
    main_log_message "INFO" "Installing basic dependencies\n"
    #install_basic_dependencies
    
    main_log_message "INFO" "Setting up procedures information\n"
    main_set_procedures_info
    procedures=($(main_get_procedure_names))

    # Display welcome message
    dialog --title "Pimp My Ubuntu" --backtitle "Installation Script" \
           --msgbox "Welcome to Pimp My Ubuntu!\n\nThis script will help you set up your Ubuntu system with your preferred software and configurations." 10 60
    
    # TODO: show_procedure_selector_menu
    if [[ ${#procedures[@]} -eq 0 ]]; then
        dialog --title "Error" --backtitle "Pimp My Ubuntu" \
               --msgbox "No installation procedures found!" 8 40
        main_log_message "ERROR" "No installation procedures found"
        exit 1
    fi

    # Get user selection menu
    # Loop to let user select software or exit
    local selected=()
    local exit_flag=false
    
    while [[ "$exit_flag" == "false" ]]; do
        # Call dialog_show_menu and capture its output and exit status
        selected=($(dialog_show_menu "${procedures[@]}"))
        local menu_status=$?
        
        # Check if user pressed Cancel/Esc
        if [[ $menu_status -ne 0 ]]; then
            dialog --title "Cancelled" --backtitle "Pimp My Ubuntu" \
                   --msgbox "Installation cancelled by user." 8 40
            main_log_message "INFO" "User cancelled the installation."
            exit 0
        fi
        
        # Check if user made a selection
        if [[ ${#selected[@]} -eq 0 ]]; then
            dialog --title "No Selection" --backtitle "Pimp My Ubuntu" \
                   --msgbox "Please select at least one software to continue." 8 50
            main_log_message "INFO" "No software selected. Prompting again."
        else
            # User made a valid selection, exit the loop
            exit_flag=true
            main_log_message "INFO" "User selected: ${selected[*]}"
        fi
    done

    main_log_message "INFO" "\nStarting Pimp My Ubuntu installation script\n"
}

# Necessary function to source libraries
_source_lib() {
    readonly REPOSITORY_URL="https://api.github.com/repos/Multitec-UA/pimp_my_ubuntu/contents"
    local header="Accept: application/vnd.github.v3.raw"
    local file="${1:-}"
    
    if [[ -n "${file}" ]]; then
        source <(curl -H "${header}" -s "${REPOSITORY_URL}/${file}")
    else
        echo "Error: No file specified" >&2
        exit 1
    fi
}


# Install basic dependencies
_install_basic_dependencies() {
    apt-get update
    apt-get install -y curl git dialog jq
}



main "$@"
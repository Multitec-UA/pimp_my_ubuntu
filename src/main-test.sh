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


REPOSITORY_URL="https://api.github.com/repos/Multitec-UA/pimp_my_ubuntu/contents"
REPOSITORY_LIB_URL="${REPOSITORY_URL}/src/lib"
REPOSITORY_PROCEDURES_URL="${REPOSITORY_URL}/src/procedures"


main() {
    source_dependencies ${REPOSITORY_LIB_URL} "globals.sh"
    source_dependencies ${REPOSITORY_LIB_URL} "dialog.sh"

    # Check if the script is running with root privileges
    global_check_root

    # Initialize logging
    global_setup_logging

    # Install basic dependencies
    global_log_message "INFO" "Installing basic dependencies\n"
    install_basic_dependencies
    
    global_log_message "INFO" "Setting up procedures information\n"
    global_set_procedures_info
    procedures=($(global_get_procedure_names))

    # Display welcome message
    dialog --title "Pimp My Ubuntu" --backtitle "Installation Script" \
           --msgbox "Welcome to Pimp My Ubuntu!\n\nThis script will help you set up your Ubuntu system with your preferred software and configurations." 10 60
    
    # TODO: show_procedure_selector_menu
    if [[ ${#procedures[@]} -eq 0 ]]; then
        dialog --title "Error" --backtitle "Pimp My Ubuntu" \
               --msgbox "No installation procedures found!" 8 40
        global_log_message "ERROR" "No installation procedures found"
        exit 1
    fi

    # Get user selection
    local selected
    selected=($(show_menu "${procedures[@]}"))
    
    if [[ ${#selected[@]} -eq 0 ]]; then
        dialog --title "Cancelled" --backtitle "Pimp My Ubuntu" \
               --msgbox "No software selected. Installation cancelled." 8 40
        global_log_message "INFO" "No software selected. Installation cancelled."
        exit 0
    fi

    global_log_message "INFO" "\nStarting Pimp My Ubuntu installation script\n"
}


source_dependencies() {
    local path="${1:-}"
    local file="${2:-}"
    local header="Accept: application/vnd.github.v3.raw"
    
    if [[ -n "${file}" ]]; then
        source <(curl -H "${header}" -s "${path}/${file}")
    else
        echo "Error: No file specified" >&2
        exit 1
    fi
}


# Install basic dependencies
install_basic_dependencies() {
    apt-get update
    apt-get install -y curl git dialog jq
}



main "$@"
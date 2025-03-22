#!/usr/bin/env bash

# =============================================================================
# Pimp My Ubuntu - Main Installation Script
# =============================================================================
# Description: Automates the setup of a fresh Ubuntu 24.04 installation
# Author: Multitec-UA
# Repository: https://github.com/Multitec-UA/pimp_my_ubuntu
# License: MIT
# =============================================================================

# Debug flag - set to true to enable debug messages
readonly DEBUG=${DEBUG:-true}

# Software-common constants
readonly _REPOSITORY_URL="https://api.github.com/repos/Multitec-UA/pimp_my_ubuntu/contents"
readonly _SOFTWARE_COMMAND="main-menu"
readonly _SOFTWARE_DESCRIPTION="Main menu for Pimp My Ubuntu"
readonly _SOFTWARE_VERSION="1.0.0"
readonly _DEPENDENCIES=("curl" "wget" "dialog" "jq")

# Software-specific constants
readonly _PROCEDURES_PATH="${_REPOSITORY_URL}/src/procedures"

# Strict mode
set -euo pipefail

main() {
    #_source_lib "/src/lib/main_utils.sh"
    _source_lib "/src/lib/global_utils.sh"
    _source_lib "/src/lib/dialog.sh"

    # Check if the script is running with root privileges
    global_check_root

    # Initialize main menu
    _step_init
  
    
    global_log_message "INFO" "Initializing procedures information"
    _init_procedures_info

    _welcome_screen

    _PROCEDURES_SELECTED=()
    _procedure_selector_screen
    echo "Selected procedures: ${_PROCEDURES_SELECTED[*]}"

    # Make status array available to child scripts
    global_export_installation_status


    while IFS= read -r procedure; do
        _run_procedure "${procedure}"
    done <<< "${_PROCEDURES_SELECTED[@]}"



    global_log_message "INFO" "\nStarting Pimp My Ubuntu installation script\n"
}

# Necessary function to source libraries
_source_lib() {
    local header="Accept: application/vnd.github.v3.raw"
    local file="${1:-}"
    
    if [[ -n "${file}" ]]; then
        source <(curl -H "${header}" -s "${_REPOSITORY_URL}/${file}")
    else
        echo "Error: No library file specified to source" >&2
        exit 1
    fi
}


# Prepare for installation
_step_init() {
    global_setup_logging
    global_log_message "INFO" "Starting Main Menu"
    global_log_message "INFO" "Installing basic dependencies"
    global_install_apt_package "${_DEPENDENCIES[@]}"
}

# Initialize procedures information
# Fetches procedures from repository and initializes their status
_init_procedures_info() {
    global_log_message "INFO" "Setting up procedures information"
        
    # Get procedures list from GitHub API
    local procedures_json
    procedures_json=$(curl -s -H "Accept: application/vnd.github.v3+json" "${_PROCEDURES_PATH}")
    
    # Parse procedure names from JSON response and filter out template.sh
    local names
    names=$(echo "${procedures_json}" | jq -r '.[].name | select(. != "template.sh")')
    
    # Initialize each procedure's status as pending
    while IFS= read -r proc_name; do
        GLOBAL_INSTALLATION_STATUS["${proc_name}"]="INIT"
        global_log_message "INFO" "Added procedure '${proc_name}' with status 'INIT'"
    done <<< "${names}"
    
    global_log_message "INFO" "All procedures initialized with INIT status"
}

_welcome_screen() {
        # Display welcome message
    dialog --title "Pimp My Ubuntu" --backtitle "Installation Script" \
           --msgbox "Welcome to Pimp My Ubuntu!\n\nThis script will help you set up your Ubuntu system with your preferred software and configurations." 10 60
    
    # Check if there are any procedures to install
    if [[ ${#GLOBAL_INSTALLATION_STATUS[@]} -eq 0 ]]; then
        dialog --title "Error" --backtitle "Pimp My Ubuntu" \
               --msgbox "No installation procedures found!" 8 40
        global_log_message "ERROR" "No installation procedures found"
        exit 1
    fi
}

_procedure_selector_screen() {
    # Get user selection menu
    # Loop to let user select software or exit
    local exit_flag=false
    
    while [[ "$exit_flag" == "false" ]]; do
        # Build menu items from GLOBAL_INSTALLATION_STATUS
        local menu_items=()
        for proc_name in "${!GLOBAL_INSTALLATION_STATUS[@]}"; do
            local status="${GLOBAL_INSTALLATION_STATUS[$proc_name]}"
            menu_items+=("$proc_name")
        done
        
        # Call dialog_show_menu and capture its output and exit status
        _PROCEDURES_SELECTED=($(dialog_show_menu "${menu_items[@]}"))
        local menu_status=$?
        
        # Check if user pressed Cancel/Esc
        if [[ $menu_status -ne 0 ]]; then
            dialog --title "Cancelled" --backtitle "Pimp My Ubuntu" \
                   --msgbox "Installation cancelled by user." 8 40
            global_log_message "INFO" "User cancelled the installation."
            exit 0
        fi
        
        # Check if user made a selection
        if [[ ${#_PROCEDURES_SELECTED[@]} -eq 0 ]]; then
            dialog --title "No Selection" --backtitle "Pimp My Ubuntu" \
                   --msgbox "Please select at least one software to continue." 8 50
            global_log_message "INFO" "No software selected. Prompting again."
        else
            # User made a valid selection, exit the loop
            exit_flag=true
            global_log_message "INFO" "User selected: ${_PROCEDURES_SELECTED[*]}"
        fi
    done

}


_run_procedure() {
    local procedure="${1:-}"
    global_log_message "INFO" "Starting procedure: ${procedure}"
    echo "GLOBAL_INSTALLATION_STATUS: ${GLOBAL_INSTALLATION_STATUS[@]}"

    curl -H "Accept: application/vnd.github.v3.raw" -s "${_PROCEDURES_PATH}/${procedure}/${procedure}.sh" | sudo -E bash


#curl -H "Accept: application/vnd.github.v3.raw" \
#-s https://api.github.com/repos/Multitec-UA/pimp_my_ubuntu/contents/src/procedures/test/test.sh | sudo bash
}


main "$@"
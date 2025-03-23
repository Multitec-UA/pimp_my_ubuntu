#!/usr/bin/env bash

# =============================================================================
# Pimp My Ubuntu - Main Installation Script
# =============================================================================
# Description: Automates the setup of a fresh Ubuntu 24.04 installation
# Author: Multitec-UA
# Repository: https://github.com/Multitec-UA/pimp_my_ubuntu
# License: MIT
# =============================================================================

# Declare the global installation status array
declare -A GLOBAL_INSTALLATION_STATUS

# Debug flag - set to true to enable debug messages
readonly DEBUG=${DEBUG:-true}

# Software-common constants
readonly _REPOSITORY_URL="https://raw.github.com/Multitec-UA/pimp_my_ubuntu/main"
readonly _SOFTWARE_COMMAND="main-menu"
readonly _SOFTWARE_DESCRIPTION="Main menu for Pimp My Ubuntu"
readonly _SOFTWARE_VERSION="1.0.1"
readonly _DEPENDENCIES=("curl" "wget" "dialog" "jq")

# Software-specific constants
readonly _PROCEDURES_PATH="https://api.github.com/repos/Multitec-UA/pimp_my_ubuntu/contents/src/procedures"

# Declare GLOBAL_INSTALLATION_STATUS if not already declared
declare -A GLOBAL_INSTALLATION_STATUS


# Strict mode
set -euo pipefail

main() {
    #_source_lib "/src/lib/main_utils.sh"
    _source_lib "/src/lib/global_utils.sh"
    _source_lib "/src/lib/dialog.sh"

    # Check if the script is running with root privileges
    global_check_root

    _step_init
  
    _init_procedures_info

    _welcome_screen

    _procedure_selector_screen

    # Run procedures in the order of selection
    for procedure in "${!GLOBAL_INSTALLATION_STATUS[@]}"; do
        _run_procedure "${procedure}"
    done

    _print_global_installation_status
    
    global_log_message "INFO" "Finished Pimp My Ubuntu installation script\n"

    
}

# Necessary function to source libraries
_source_lib() {
    local file="${1:-}"
    
    if [[ -n "${file}" ]]; then
        # Add error handling for curl command
        if ! source <(curl -fsSL "${_REPOSITORY_URL}/${file}"); then
            global_log_message "ERROR" "Failed to source library: ${file}"
            exit 1
        fi
        global_log_message "DEBUG" "Successfully sourced library: ${file}"
    else
        global_log_message "ERROR" "No library file specified to source"
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
    global_log_message "INFO" "Initializing procedures information"
        
    # Get procedures list from GitHub API
    local procedures_json
    procedures_json=$(curl -fsSL "${_PROCEDURES_PATH}")
    
    # Parse procedure names from JSON response and filter out template
    local names
    names=$(echo "${procedures_json}" | jq -r '.[].name | select(. != "template")')
    
    # Initialize each procedure's status as pending
    while IFS= read -r proc_name; do
        global_log_message "INFO" "Added procedure '${proc_name}' with status 'INIT'"
        GLOBAL_INSTALLATION_STATUS["${proc_name}"]="INIT"
    done <<< "${names}"
    
    global_export_installation_status
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
    local procedures_selected=()
    
    while [[ "$exit_flag" == "false" ]]; do
        # Build menu items from GLOBAL_INSTALLATION_STATUS
        local menu_items=()
        for proc_name in "${!GLOBAL_INSTALLATION_STATUS[@]}"; do
            local status="${GLOBAL_INSTALLATION_STATUS[$proc_name]}"
            menu_items+=("$proc_name")
        done
        
        # Call dialog_show_menu and capture its output and exit status
        procedures_selected=($(dialog_show_menu "${menu_items[@]}"))
        local menu_status=$?
        
        # Check if user pressed Cancel/Esc
        if [[ $menu_status -ne 0 ]]; then
            dialog --title "Cancelled" --backtitle "Pimp My Ubuntu" \
                   --msgbox "Installation cancelled by user." 8 40
            global_log_message "INFO" "User cancelled the installation."
            exit 0
        fi
        
        # Check if user made a selection
        if [[ ${#procedures_selected[@]} -eq 0 ]]; then
            dialog --title "No Selection" --backtitle "Pimp My Ubuntu" \
                   --msgbox "Please select at least one software to continue." 8 50
            global_log_message "INFO" "No software selected. Prompting again."
        else
            # User made a valid selection, exit the loop
            exit_flag=true
            global_log_message "INFO" "User selected: ${procedures_selected[*]}"
        fi
    done

    # Remove procedures not selected from GLOBAL_INSTALLATION_STATUS
    local all_procedures=("${!GLOBAL_INSTALLATION_STATUS[@]}")
    for proc in "${all_procedures[@]}"; do
        if [[ ! " ${procedures_selected[@]} " =~ " ${proc} " ]]; then
            unset "GLOBAL_INSTALLATION_STATUS[$proc]"
            global_log_message "DEBUG" "Removed $proc from installation status"
        fi
    done

    # Set all remaining procedures to PENDING status
    for proc in "${!GLOBAL_INSTALLATION_STATUS[@]}"; do
        GLOBAL_INSTALLATION_STATUS["$proc"]="PENDING"
        global_log_message "DEBUG" "Set $proc status to PENDING"
    done

    # Make status array available to child scripts
    global_export_installation_status
}

_print_global_installation_status() {
    echo -e "\n"
    global_log_message "INFO" "Current installation status:"
    for proc_name in "${!GLOBAL_INSTALLATION_STATUS[@]}"; do
        global_log_message "INFO" "${proc_name}: ${GLOBAL_INSTALLATION_STATUS[$proc_name]}"
    done
    global_log_message "INFO" "For more details, check the log file ${GLOBAL_LOG_FILE}"
    echo -e "\n"
}

_run_procedure() {
    local procedure="${1:-}"

    # Print all installation statuses
    _print_global_installation_status

    global_log_message "INFO" "Starting procedure: ${procedure}"

    curl -fsSL "${_PROCEDURES_PATH}/${procedure}/${procedure}.sh" | sudo -E bash
    local exit_statuses=("${PIPESTATUS[@]}")
    local curl_status="${exit_statuses[0]}"
    local bash_status="${exit_statuses[1]}"
    
    global_log_message "INFO" "Procedure ${procedure} completed with status: ${bash_status} (curl status: ${curl_status})"

    global_import_installation_status

}


main "$@"
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
    if ! dialog_show_welcome; then
        global_log_message "ERROR" "No installation procedures found"
        exit 1
    fi
}

_procedure_selector_screen() {
    local procedures=()
    
    # Get list of available procedures
    for proc_name in "${!GLOBAL_INSTALLATION_STATUS[@]}"; do
        procedures+=("$proc_name")
    done
    
    # Show selector and get choices
    local selected
    selected=$(dialog_show_procedure_selector "${procedures[@]}")
    
    if [[ $? -ne 0 ]]; then
        global_log_message "INFO" "User cancelled the installation."
        exit 0
    fi
    
    # Update GLOBAL_INSTALLATION_STATUS based on selection
    local all_procedures=("${!GLOBAL_INSTALLATION_STATUS[@]}")
    for proc in "${all_procedures[@]}"; do
        if [[ ! " ${selected} " =~ " ${proc} " ]]; then
            unset "GLOBAL_INSTALLATION_STATUS[$proc]"
            global_log_message "DEBUG" "Removed $proc from installation status"
        else
            GLOBAL_INSTALLATION_STATUS["$proc"]="PENDING"
            global_log_message "DEBUG" "Set $proc status to PENDING"
        fi
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
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
readonly DEBUG=${DEBUG:-false}

# Software-common constants
readonly _SOFTWARE_COMMAND="main-menu"
readonly _SOFTWARE_DESCRIPTION="Main menu for Pimp My Ubuntu"
readonly _SOFTWARE_VERSION="1.0.1"
readonly _DEPENDENCIES=("curl" "wget" "dialog" "jq")

# Software-specific constants
readonly _PROCEDURES_CONTENT_URL="https://api.github.com/repos/Multitec-UA/pimp_my_ubuntu/contents/src/procedures"
readonly _REPOSITORY_RAW_URL="https://raw.github.com/Multitec-UA/pimp_my_ubuntu/main"
readonly _PROCEDURES_REMOTE_URL="${_REPOSITORY_RAW_URL}/src/procedures/"
readonly _LIBS_REMOTE_URL="${_REPOSITORY_RAW_URL}/src/libs/"


# Get the real user's home directory (works with sudo)
if [[ -n "${SUDO_USER:-}" ]]; then
    GLOBAL_REAL_USER="${SUDO_USER}"
    GLOBAL_REAL_HOME=$(getent passwd "${SUDO_USER}" | cut -d: -f6)
else
    GLOBAL_REAL_USER="${USER}"
    GLOBAL_REAL_HOME="${HOME}"
fi

GLOBAL_DOWNLOAD_DIR="$GLOBAL_REAL_HOME/Documents/pimp_my_ubuntu"


main() {
    #_source_lib "/src/lib/main_utils.sh"
    _source_lib "global_utils.sh"
    _source_lib "dialog.sh"

    # Check if the script is running with root privileges
    global_check_root

    _step_init    
  
    _init_procedures_info

    _welcome_screen

    _procedure_selector_screen

    # Get all procedures with PENDING status
    _run_pending_procedures
    
    _print_global_installation_status
    
    global_log_message "INFO" "Finished Pimp My Ubuntu installation script\n"
}

# Necessary function to source libraries
_source_lib() {
    local file="${1:-}"
    
    if [[ -n "${file}" ]]; then
        # Redirect curl errors to console
        if ! source <(curl -fsSL "${_LIBS_REMOTE_URL}${file}" 2>&1); then
            echo "ERROR" "Failed to source library: ${file}"
            exit 1
        fi
        global_log_message "DEBUG" "Successfully sourced library: ${file}"
    else
        echo "ERROR" "No library file specified to source"
        exit 1
    fi
}


# Prepare for installation
_step_init() {
    # Log all environment variables for debugging
    global_log_message "DEBUG" "_PROCEDURES_CONTENT_URL: ${_PROCEDURES_CONTENT_URL}"
    global_log_message "DEBUG" "_REPOSITORY_RAW_URL: ${_REPOSITORY_RAW_URL}"
    global_log_message "DEBUG" "_PROCEDURES_REMOTE_URL: ${_PROCEDURES_REMOTE_URL}"
    global_log_message "DEBUG" "_LIBS_REMOTE_URL: ${_LIBS_REMOTE_URL}"
    global_log_message "DEBUG" "_SOFTWARE_COMMAND: ${_SOFTWARE_COMMAND}"
    global_log_message "DEBUG" "_SOFTWARE_DESCRIPTION: ${_SOFTWARE_DESCRIPTION}"
    global_log_message "DEBUG" "_SOFTWARE_VERSION: ${_SOFTWARE_VERSION}"
    global_log_message "DEBUG" "_DEPENDENCIES: ${_DEPENDENCIES[*]}"
    global_log_message "DEBUG" "DEBUG_MODE: ${DEBUG}"
    global_log_message "DEBUG" "GLOBAL_LOG_DIR: ${GLOBAL_LOG_DIR}"
    global_log_message "DEBUG" "GLOBAL_LOG_FILE: ${GLOBAL_LOG_FILE}"
    global_log_message "DEBUG" "GLOBAL_REAL_USER: ${GLOBAL_REAL_USER}"
    global_log_message "DEBUG" "GLOBAL_REAL_HOME: ${GLOBAL_REAL_HOME}"
    global_log_message "DEBUG" "GLOBAL_DOWNLOAD_DIR: ${GLOBAL_DOWNLOAD_DIR}"
    global_log_message "DEBUG" "GLOBAL_LOGGING_INITIALIZED: ${GLOBAL_LOGGING_INITIALIZED}"
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
    procedures_json=$(curl -fsSL "${_PROCEDURES_CONTENT_URL}")
    
    # Parse procedure names from JSON response and filter out template
    local names
    names=$(echo "${procedures_json}" | jq -r '.[].name | select(. != "template")')
    
    # Initialize each procedure's status as INIT
    while IFS= read -r proc_name; do
        if [[ -n "$proc_name" && ! "$proc_name" =~ ^[0-9]+$ ]]; then
            global_log_message "DEBUG" "Adding procedure: '${proc_name}' with status 'INIT'"
            global_set_installation_status "${proc_name}" "INIT"
        else
            global_log_message "WARNING" "Skipping invalid procedure name: '${proc_name}'"
        fi
    done <<< "${names}"
    
    # Verify the initialized procedures
    global_import_installation_status
    global_log_message "DEBUG" "Initialized procedures: ${!GLOBAL_INSTALLATION_STATUS[@]}"
    global_log_message "DEBUG" "All procedures initialized with INIT status"
}

_welcome_screen() {
    if ! dialog_show_welcome; then
        global_log_message "ERROR" "No installation procedures found"
        exit 1
    fi
}

_procedure_selector_screen() {
    local procedures=()
    
    # Import procedures from status file
    global_import_installation_status
    
    # Get list of available procedures
    for proc_key in "${!GLOBAL_INSTALLATION_STATUS[@]}"; do
        procedures+=("$proc_key")
    done
    
    global_log_message "DEBUG" "Available procedures for selection: ${procedures[*]}"
    
    # Show selector and get choices
    local selected
    selected=$(dialog_show_procedure_selector "${procedures[@]}")
    
    if [[ $? -ne 0 ]]; then
        global_log_message "INFO" "User cancelled the installation."
        exit 0
    fi
    
    global_log_message "DEBUG" "User selected procedures: $selected"
    
    # Update installation status based on selection
    for proc in "${procedures[@]}"; do
        if [[ " ${selected} " =~ " ${proc} " ]]; then
            # Set selected procedures to PENDING status
            global_set_installation_status "${proc}" "PENDING"
            global_log_message "DEBUG" "Set $proc status to PENDING"
        else
            # Clear procedures that aren't selected
            global_unset_installation_status "${proc}"
            global_log_message "DEBUG" "Removed $proc from installation status"
        fi
    done
}

_print_global_installation_status() {
    echo -e "\n"
    global_log_message "INFO" "Current installation status:"
    
    # Get all procedures from the temp file
    global_import_installation_status
    local all_procedures=()
    
    # Get the list of all procedures from the status file
    for proc_key in "${!GLOBAL_INSTALLATION_STATUS[@]}"; do
        all_procedures+=("$proc_key")
    done
    
    for proc_name in "${all_procedures[@]}"; do
        local status=$(global_get_installation_status "$proc_name")
        global_log_message "INFO" "${proc_name}: ${status}"
    done
    
    global_log_message "INFO" "For more details, check the log file ${GLOBAL_LOG_FILE}"
    echo -e "\n"
}

_run_procedure() {
    local procedure="${1:-}"

    # Print all installation statuses
    _print_global_installation_status

    global_log_message "INFO" "Starting procedure: ${procedure}"
    

    curl -fsSL "${_PROCEDURES_REMOTE_URL}${procedure}/${procedure}.sh" | bash
    
    local exit_statuses=("${PIPESTATUS[@]}")
    local curl_status="${exit_statuses[0]}"
    local bash_status="${exit_statuses[1]}"
    
    global_log_message "INFO" "Procedure ${procedure} completed with status: ${bash_status} (curl status: ${curl_status})"

}

# Run all procedures with PENDING status
_run_pending_procedures() {
    # Get all procedures from the temp file
    global_import_installation_status
    local all_procedures=()
    
    # Get the list of all procedures from the status file
    for proc_key in "${!GLOBAL_INSTALLATION_STATUS[@]}"; do
        all_procedures+=("$proc_key")
    done
    
    global_log_message "DEBUG" "Available procedures: ${all_procedures[*]}"
    
    # Run each procedure with PENDING status
    for proc_name in "${all_procedures[@]}"; do
        local status=$(global_get_installation_status "$proc_name")
        global_log_message "DEBUG" "Checking procedure $proc_name with status $status"
        
        if [[ "$status" == "PENDING" ]]; then
            global_log_message "INFO" "Running procedure: $proc_name"
            _run_procedure "$proc_name"
        else
            global_log_message "DEBUG" "Skipping procedure $proc_name (status: $status)"
        fi
    done
}

main "$@"
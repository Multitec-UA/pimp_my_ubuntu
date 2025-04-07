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
readonly LOCAL=${LOCAL:-false}

# Software-common constants
readonly _SOFTWARE_COMMAND="main-menu"
readonly _SOFTWARE_DESCRIPTION="Main menu for Pimp My Ubuntu"
readonly _SOFTWARE_VERSION="1.1.21"
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
MAIN_DIALOG_MENU_SELECTION=""

main() {

    # Source libraries
    if [[ "$LOCAL" == "true" ]]; then
        # Strict mode
        set -euo pipefail
        # Source libraries from local directory
        source "./src/libs/global_utils.sh"
        source "./src/libs/dialog.sh"
    else
        # Source libraries from remote repository
        _source_lib "global_utils.sh"
        _source_lib "dialog.sh"
    fi  

    global_log_message "DEBUG" "MF: --> main"
    # Check if the script is running with root privileges
    global_check_root

    # Show  global variables and install basic dependencies
    _step_init    

  
    # Get procedures information from GitHub
    _init_procedures_info

    # Show welcome screen
    if [[ "$DEBUG" == "false" ]]; then
        _welcome_screen
    fi
   
    # Select procedures to install
    local selected_procedures
    selected_procedures=$(dialog_show_procedure_selector_screen "${!GLOBAL_INSTALLATION_STATUS[@]}")
    _remove_no_selected_procedures "${selected_procedures}"

    

    # TODO: AUTOMATIC
    #if [[ "$MAIN_DIALOG_MENU_SELECTION" == "automatic" ]]; then
    # --mixedgauge for show progress bar when automatic is selected



    # MANUALLY
    # Show procedures status screen selector 
    # MAIN_DIALOG_MENU_SELECTION save each iteration user selection
    while true; do
        global_import_installation_status
        dialog_show_procedure_selector_status_screen
        global_log_message "DEBUG" "GLOBAL_INSTALLATION_STATUS_ALL: ${!GLOBAL_INSTALLATION_STATUS[@]}"
        global_log_message "DEBUG" "GLOBAL_INSTALLATION_STATUS_SELECTED: $MAIN_DIALOG_MENU_SELECTION : ${GLOBAL_INSTALLATION_STATUS[${MAIN_DIALOG_MENU_SELECTION}]}"

        global_press_any_key
        if [[ "${GLOBAL_INSTALLATION_STATUS[${MAIN_DIALOG_MENU_SELECTION}]}" != "SUCCESS" ]]; then
            _run_procedure "${MAIN_DIALOG_MENU_SELECTION}"
        fi
        global_press_any_key

    done

    _print_global_installation_status

    
    global_log_message "INFO" "Finished Pimp My Ubuntu installation script\n"
    global_log_message "DEBUG" "MF: <-- main"
}

# Necessary function to source libraries
_source_lib() {
    global_log_message "DEBUG" "MF: --> _source_lib"
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
    global_log_message "DEBUG" "MF: <-- _source_lib"
}


# Prepare for installation
_step_init() {
    global_log_message "DEBUG" "MF: --> _step_init"
    # Log all environment variables for debugging
    global_log_message "DEBUG" "GLOBAL_UTILS_VERSION: ${GLOBAL_UTILS_VERSION}"
    global_log_message "DEBUG" "DIALOG_UTILS_VERSION: ${DIALOG_VERSION}"
    global_log_message "DEBUG" "MAIN_VERSION: ${_SOFTWARE_VERSION}"
    global_log_message "DEBUG" "_PROCEDURES_CONTENT_URL: ${_PROCEDURES_CONTENT_URL}"
    global_log_message "DEBUG" "_REPOSITORY_RAW_URL: ${_REPOSITORY_RAW_URL}"
    global_log_message "DEBUG" "_PROCEDURES_REMOTE_URL: ${_PROCEDURES_REMOTE_URL}"
    global_log_message "DEBUG" "_LIBS_REMOTE_URL: ${_LIBS_REMOTE_URL}"
    global_log_message "DEBUG" "_SOFTWARE_COMMAND: ${_SOFTWARE_COMMAND}"
    global_log_message "DEBUG" "_SOFTWARE_DESCRIPTION: ${_SOFTWARE_DESCRIPTION}"
    global_log_message "DEBUG" "_DEPENDENCIES: ${_DEPENDENCIES[*]}"
    global_log_message "DEBUG" "DEBUG_MODE: ${DEBUG}"
    global_log_message "DEBUG" "LOCAL_MODE: ${LOCAL}"
    global_log_message "DEBUG" "GLOBAL_LOG_DIR: ${GLOBAL_LOG_DIR}"
    global_log_message "DEBUG" "GLOBAL_LOG_FILE: ${GLOBAL_LOG_FILE}"
    global_log_message "DEBUG" "GLOBAL_REAL_USER: ${GLOBAL_REAL_USER}"
    global_log_message "DEBUG" "GLOBAL_REAL_HOME: ${GLOBAL_REAL_HOME}"
    global_log_message "DEBUG" "GLOBAL_DOWNLOAD_DIR: ${GLOBAL_DOWNLOAD_DIR}"
    global_log_message "DEBUG" "GLOBAL_LOGGING_INITIALIZED: ${GLOBAL_LOGGING_INITIALIZED}"
    global_log_message "INFO" "Starting Main Menu"
    global_log_message "INFO" "Installing basic dependencies"

    # Install basic dependencies
    global_install_apt_package "${_DEPENDENCIES[@]}"
    global_log_message "DEBUG" "MF: <-- _step_init"
}

# Initialize procedures information
# Fetches procedures from repository and initializes their status
_init_procedures_info() {
    global_log_message "DEBUG" "MF: --> _init_procedures_info"
    global_log_message "INFO" "Initializing procedures information"
        
    # Get procedures list from GitHub API
    local procedures_json
    procedures_json=$(curl -fsSL "${_PROCEDURES_CONTENT_URL}")
    
    # Parse procedure names from JSON response and filter out template
    local names
    names=$(echo "${procedures_json}" | jq -r '.[].name | select(. != "template")')
    
    # Initialize each procedure's status as INIT
    while IFS= read -r proc_name; do
        global_set_installation_status "${proc_name}" "INIT"
        global_log_message "DEBUG" "Added procedure '${proc_name}' with status 'INIT'"
    done <<< "${names}"
    
    global_log_message "DEBUG" "All procedures initialized with INIT status"
    global_log_message "DEBUG" "MF: <-- _init_procedures_info"
}

_welcome_screen() {
    global_log_message "DEBUG" "MF: --> _welcome_screen"
    if ! dialog_show_welcome_screen; then
        global_log_message "ERROR" "No installation procedures found"
        exit 1
    fi
    global_log_message "DEBUG" "MF: <-- _welcome_screen"
}

_remove_no_selected_procedures() {
    global_log_message "DEBUG" "MF: --> _remove_no_selected_procedures"
    local selected_procedures="${1:-}"
    # Update installation status based on selection
    local all_procedures=("${!GLOBAL_INSTALLATION_STATUS[@]}")
    for proc in "${all_procedures[@]}"; do
        # Check if the procedure is in the selected procedures list
        if echo "${selected_procedures}" | grep -q "${proc}"; then
            global_log_message "DEBUG" "Keeping $proc in installation list"
            # Set selected procedures to PENDING status
            #global_set_installation_status "${proc}" "PENDING"
            #global_log_message "DEBUG" "Set $proc status to PENDING"
        else
            # Remove procedures that aren't selected
            global_unset_installation_status "${proc}"
            global_log_message "DEBUG" "Removed $proc from installation status"
        fi
    done
    global_log_message "DEBUG" "MF: <-- _remove_no_selected_procedures"
}

_print_global_installation_status() {
    global_log_message "DEBUG" "MF: --> _print_global_installation_status"
    echo -e "\n"
    global_log_message "INFO" "Current installation status:"

    #global_import_installation_status
    for proc_name in "${!GLOBAL_INSTALLATION_STATUS[@]}"; do
        global_log_message "INFO" "${proc_name}: ${GLOBAL_INSTALLATION_STATUS[${proc_name}]}"
    done
    global_log_message "INFO" "For more details, check the log file ${GLOBAL_LOG_FILE}"
    echo -e "\n"
    global_log_message "DEBUG" "MF: <-- _print_global_installation_status"
}

_run_procedure() {
    global_log_message "DEBUG" "MF: --> _run_procedure"
    local procedure="${1:-}"

    # Print all installation statuses
    _print_global_installation_status

    global_log_message "INFO" "Starting procedure: ${procedure}"

    curl -fsSL "${_PROCEDURES_REMOTE_URL}${procedure}/${procedure}.sh" | bash
    
    local exit_statuses=("${PIPESTATUS[@]}")
    local curl_status="${exit_statuses[0]}"
    local bash_status="${exit_statuses[1]}"
    
    global_log_message "INFO" "Procedure ${procedure} completed with status: ${bash_status} (curl status: ${curl_status})"
    global_log_message "DEBUG" "MF: <-- _run_procedure"
}


main "$@"
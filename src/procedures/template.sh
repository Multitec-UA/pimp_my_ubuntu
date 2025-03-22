#!/usr/bin/env bash

# =============================================================================
# Pimp My Ubuntu - PROCEDURE_NAME
# =============================================================================
# Description: DESCRIPTION_HERE
# Author: Multitec-UA
# Repository: https://github.com/Multitec-UA/pimp_my_ubuntu
# License: MIT
#
# COMMON INSTRUCTIONS:
# 1. Dont use echo. Use global_log_message instead.
# 2. Send all output to log file. command >>"${LOG_FILE}" 2>&1
# =============================================================================

# Debug flag - set to true to enable debug messages
readonly DEBUG=${DEBUG:-true}

# Software-common constants
readonly _REPOSITORY_URL="https://api.github.com/repos/Multitec-UA/pimp_my_ubuntu/contents"
readonly _SOFTWARE_COMMAND="SOFTWARE_COMMAND_HERE"
readonly _SOFTWARE_DESCRIPTION="SOFTWARE_DESCRIPTION_HERE"
readonly _SOFTWARE_VERSION="1.0.0"
readonly _DEPENDENCIES=("dependency1" "dependency2" "dependency3")

# Software-specific constants
# Add any software-specific constants here
readonly _EXAMPLE_CONFIG_VALUE="example_value"

# Declare GLOBAL_INSTALLATION_STATUS if not already declared
if ! declare -p GLOBAL_INSTALLATION_STATUS >/dev/null 2>&1; then
    declare -A GLOBAL_INSTALLATION_STATUS
fi

# Strict mode
set -euo pipefail

# Main procedure function
main() {

    # Source global variables and functions
    _source_lib "/src/lib/global_utils.sh"
    
    global_check_root

    _step_init

    if [ "$(global_get_status "${_SOFTWARE_COMMAND}")" == "SKIPPED" ]; then
        global_log_message "INFO" "${_SOFTWARE_COMMAND} is already installed"
        _step_post_install
        _step_cleanup
        return 0
    fi

    _step_install_dependencies

    if _step_install_software; then
        _step_post_install
        global_log_message "INFO" "${_SOFTWARE_COMMAND} installation completed successfully"
        global_set_status "${_SOFTWARE_COMMAND}" "SUCCESS"
        _step_cleanup
        return 0
    else
        global_log_message "ERROR" "Failed to install ${_SOFTWARE_COMMAND}"
        global_set_status "${_SOFTWARE_COMMAND}" "FAILED"
        _step_cleanup
        return 1
    fi

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
    global_log_message "INFO" "Starting installation of ${_SOFTWARE_COMMAND}"
    
    if global_check_if_installed "${_SOFTWARE_COMMAND}"; then
        global_set_status "${_SOFTWARE_COMMAND}" "SKIPPED"
        return 0
    fi
}

# Install dependencies
_step_install_dependencies() {
    global_log_message "INFO" "Installing dependencies for ${_SOFTWARE_COMMAND}"

    # Install dependencies from the _DEPENDENCIES array
    global_install_apt_package "${_DEPENDENCIES[@]}"
    
    # Example for adding a PPA if needed
    # global_add_apt_repository "ppa:example/ppa"
}

# Install the software
_step_install_software() {
    global_log_message "INFO" "Installing ${_SOFTWARE_COMMAND}"

    # Replace with actual installation commands
    # Example for APT install:
    # global_install_apt_package "${_SOFTWARE_COMMAND}"
    
    # Example for manual installation:
    # mkdir -p "/tmp/${_SOFTWARE_COMMAND}" >>"${LOG_FILE}" 2>&1
    # cd "/tmp/${_SOFTWARE_COMMAND}" >>"${LOG_FILE}" 2>&1
    # wget "https://example.com/${_SOFTWARE_COMMAND}.tar.gz" >>"${LOG_FILE}" 2>&1
    # tar -xzf "${_SOFTWARE_COMMAND}.tar.gz" >>"${LOG_FILE}" 2>&1
    # ./configure >>"${LOG_FILE}" 2>&1
    # make >>"${LOG_FILE}" 2>&1
    # make install >>"${LOG_FILE}" 2>&1
    
    # Return true if installation succeeded
    return 0
}

# Post-installation configuration
_step_post_install() {
    global_log_message "INFO" "Post installation of ${_SOFTWARE_COMMAND}"
    
    # Add any post-installation steps here
    # Example:
    # global_log_message "INFO" "Configuring ${_SOFTWARE_COMMAND}"
    # _configure_software
}

# Cleanup after installation
_step_cleanup() {
    global_log_message "INFO" "Cleaning up after installation of ${_SOFTWARE_COMMAND}"
    
    # Remove downloaded files if any
    if [[ -f "${GLOBAL_DOWNLOAD_DIR}/${_SOFTWARE_COMMAND}.tar.gz" ]]; then
        global_log_message "DEBUG" "Removing downloaded files"
        rm -f "${GLOBAL_DOWNLOAD_DIR}/${_SOFTWARE_COMMAND}.tar.gz" >>"${LOG_FILE}" 2>&1
    fi
    
    # Clean any temporary files
    if [[ -d "/tmp/${_SOFTWARE_COMMAND}" ]]; then
        global_log_message "DEBUG" "Removing temporary files"
        rm -rf "/tmp/${_SOFTWARE_COMMAND}" >>"${LOG_FILE}" 2>&1
    fi
    
    # Clean apt cache if we installed new packages
    if [[ "$(global_get_status "${_SOFTWARE_COMMAND}")" == "SUCCESS" ]]; then
        global_log_message "DEBUG" "Cleaning apt cache"
        apt-get clean >>"${LOG_FILE}" 2>&1
    fi
}

# Add any additional helper functions here
# _configure_software() {
#     # Example configuration function
#     global_log_message "INFO" "Configuring software settings"
#     
#     # Create config directory if it doesn't exist
#     sudo mkdir -p /etc/${_SOFTWARE_COMMAND}/
#     
#     # Copy configuration file
#     sudo cp "${GLOBAL_DOWNLOAD_DIR}/config.example" "/etc/${_SOFTWARE_COMMAND}/config" >>"${LOG_FILE}" 2>&1
#     
#     # Modify configuration
#     sudo sed -i "s/default_value/${_EXAMPLE_CONFIG_VALUE}/" "/etc/${_SOFTWARE_COMMAND}/config" >>"${LOG_FILE}" 2>&1
# }

# Execute main function
main "$@" 
#!/usr/bin/env bash

# =============================================================================
# Pimp My Ubuntu - TFSwitch Installation Procedure
# =============================================================================
# Description: Installs TFSwitch - Terraform version switcher command-line tool
# Author: Multitec-UA
# Repository: https://github.com/Multitec-UA/pimp_my_ubuntu
# License: MIT
#
# COMMON INSTRUCTIONS:
# 1. Dont use echo. Use global_log_message instead.
# 2. Send all output to log file. command >>"${GLOBAL_LOG_FILE}" 2>&1
# =============================================================================

# Debug flag - set to true to enable debug messages
readonly DEBUG=${DEBUG:-false}
readonly LOCAL=${LOCAL:-false}

# Software-common constants
readonly _SOFTWARE_COMMAND="tfswitch"
readonly _SOFTWARE_DESCRIPTION="Terraform version switcher command-line tool"
readonly _SOFTWARE_VERSION="1.0.0"
readonly _DEPENDENCIES=("curl" "bash" "wget" "unzip")
readonly _REPOSITORY_TAG="v0.1.0"
readonly _REPOSITORY_RAW_URL="https://raw.github.com/Multitec-UA/pimp_my_ubuntu/refs/tags/${_REPOSITORY_TAG}/"
readonly _LIBS_REMOTE_URL="${_REPOSITORY_RAW_URL}/src/libs/"

# Software-specific constants
readonly _TFSWITCH_INSTALL_URL="https://raw.githubusercontent.com/warrensbox/terraform-switcher/master/install.sh"
readonly _TFSWITCH_INSTALL_PATH="/usr/local/bin"

# Main procedure function
main() {

    # Source global variables and functions
    _source_lib "global_utils.sh"
    
    global_check_root

    _step_init

    if [[ "$(global_get_proc_status "${_SOFTWARE_COMMAND}")" == "SKIPPED" ]]; then
        global_log_message "INFO" "${_SOFTWARE_COMMAND} is already installed"
        _step_post_install
        _step_cleanup
        return 0
    fi

    _step_install_dependencies

    if _step_install_software; then
        _step_post_install
        global_log_message "INFO" "${_SOFTWARE_COMMAND} installation completed successfully"
        global_set_proc_status "${_SOFTWARE_COMMAND}" "SUCCESS"
        _step_cleanup
        return 0
    else
        global_log_message "ERROR" "Failed to install ${_SOFTWARE_COMMAND}"
        global_set_proc_status "${_SOFTWARE_COMMAND}" "FAILED"
        _step_cleanup
        return 1
    fi

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
    global_log_message "INFO" "Starting installation of ${_SOFTWARE_COMMAND}"
    global_log_message "INFO" "_SOFTWARE_VERSION: ${_SOFTWARE_VERSION}"
    
    if global_check_if_installed "${_SOFTWARE_COMMAND}"; then
        global_set_proc_status "${_SOFTWARE_COMMAND}" "SKIPPED"
        return 0
    fi
}

# Install dependencies
_step_install_dependencies() {
    global_log_message "INFO" "Installing dependencies for ${_SOFTWARE_COMMAND}"

    # Update package list
    apt-get update >>"${GLOBAL_LOG_FILE}" 2>&1

    # Install dependencies from the _DEPENDENCIES array
    global_install_apt_package "${_DEPENDENCIES[@]}"
}

# Install the software
_step_install_software() {
    global_log_message "INFO" "Installing ${_SOFTWARE_COMMAND}"

    # Download and execute the official install script
    global_log_message "INFO" "Downloading ${_SOFTWARE_COMMAND} installer from ${_TFSWITCH_INSTALL_URL}"
    
    # Download the install script to a temporary location
    local temp_install_script="/tmp/tfswitch_install.sh"
    
    if curl -fsSL "${_TFSWITCH_INSTALL_URL}" -o "${temp_install_script}" >>"${GLOBAL_LOG_FILE}" 2>&1; then
        global_log_message "INFO" "Downloaded ${_SOFTWARE_COMMAND} installer successfully"
        
        # Make the script executable
        chmod +x "${temp_install_script}" >>"${GLOBAL_LOG_FILE}" 2>&1
        
        # Execute the install script with custom installation path
        global_log_message "INFO" "Running ${_SOFTWARE_COMMAND} installer"
        if bash "${temp_install_script}" -b "${_TFSWITCH_INSTALL_PATH}" >>"${GLOBAL_LOG_FILE}" 2>&1; then
            global_log_message "INFO" "${_SOFTWARE_COMMAND} installed successfully to ${_TFSWITCH_INSTALL_PATH}"
            
            # Verify installation
            if command -v "${_SOFTWARE_COMMAND}" >/dev/null 2>&1; then
                local installed_version
                installed_version=$("${_SOFTWARE_COMMAND}" --version 2>/dev/null | head -n1 || echo "Unknown version")
                global_log_message "INFO" "${_SOFTWARE_COMMAND} verification successful - Version: ${installed_version}"
                return 0
            else
                global_log_message "ERROR" "${_SOFTWARE_COMMAND} installation verification failed"
                return 1
            fi
        else
            global_log_message "ERROR" "Failed to execute ${_SOFTWARE_COMMAND} installer"
            return 1
        fi
    else
        global_log_message "ERROR" "Failed to download ${_SOFTWARE_COMMAND} installer"
        return 1
    fi
}

# Post-installation configuration
_step_post_install() {
    global_log_message "INFO" "Post installation of ${_SOFTWARE_COMMAND}"
    
    # Create symlink if needed to ensure it's in PATH
    if [[ ! -L "/usr/bin/${_SOFTWARE_COMMAND}" && -f "${_TFSWITCH_INSTALL_PATH}/${_SOFTWARE_COMMAND}" ]]; then
        global_log_message "INFO" "Creating symlink for ${_SOFTWARE_COMMAND} in /usr/bin"
        ln -sf "${_TFSWITCH_INSTALL_PATH}/${_SOFTWARE_COMMAND}" "/usr/bin/${_SOFTWARE_COMMAND}" >>"${GLOBAL_LOG_FILE}" 2>&1
    fi
    
    # Display usage information
    global_log_message "INFO" "${_SOFTWARE_COMMAND} is now available. Use 'tfswitch' to switch between Terraform versions"
    global_log_message "INFO" "You can also use 'tfswitch <version>' to install and switch to a specific version"
}

# Cleanup after installation
_step_cleanup() {
    global_log_message "INFO" "Cleaning up after installation of ${_SOFTWARE_COMMAND}"
    
    # Remove temporary install script
    if [[ -f "/tmp/tfswitch_install.sh" ]]; then
        global_log_message "DEBUG" "Removing temporary install script"
        rm -f "/tmp/tfswitch_install.sh" >>"${GLOBAL_LOG_FILE}" 2>&1
    fi
    
    # Clean apt cache if we installed new packages
    if [[ "$(global_get_proc_status "${_SOFTWARE_COMMAND}")" == "SUCCESS" ]]; then
        global_log_message "DEBUG" "Cleaning apt cache"
        apt-get clean >>"${GLOBAL_LOG_FILE}" 2>&1
    fi
}

# Execute main function
main "$@"

# Exit with success
exit 0
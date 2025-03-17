#!/usr/bin/env bash

# =============================================================================
# Pimp My Ubuntu - Grub Customizer Installation
# =============================================================================
# Description: Installs Grub Customizer for managing GRUB bootloader settings
# Author: Multitec-UA
# Repository: https://github.com/Multitec-UA/pimp_my_ubuntu
# License: MIT
# =============================================================================

# Debug flag - set to true to enable debug messages
readonly DEBUG=${DEBUG:-false}

# Software-specific constants
readonly _SOFTWARE_COMMAND="grub-customizer"
readonly _SOFTWARE_DESCRIPTION="Grub Customizer is a tool for managing GRUB bootloader settings"
readonly _SOFTWARE_VERSION="1.0.0"


# Strict mode
set -euo pipefail


# Main procedure function
main() {
    global_check_root

    # Source global variables and functions
    _source_lib "/src/lib/global_utils.sh"
    echo "I'm here for you see me"
    global_debug_echo "Global utilities loaded successfully"

    _step_init_procedure
    _step_install_dependencies

    if _step_install_software; then
        global_debug_echo "Software installation successful, proceeding with post-install"
        _step_post_install
        _step_update_status "SUCCESS"
        global_log_message "INFO" "${_SOFTWARE_COMMAND} installation completed successfully"
    else
        global_debug_echo "Software installation failed"
        _step_update_status "FAILED"
        global_log_message "ERROR" "Failed to install ${_SOFTWARE_COMMAND}"
        echo "Failed to install ${_SOFTWARE_COMMAND}!" >&2
        return 1
    fi

    _step_cleanup
    global_debug_echo "Installation procedure completed"
}

# Necessary function to source libraries
_source_lib() {
    readonly REPOSITORY_URL="https://api.github.com/repos/Multitec-UA/pimp_my_ubuntu/contents"
    local header="Accept: application/vnd.github.v3.raw"
    local file="${1:-}"
    
    if [[ -n "${file}" ]]; then
        source <(curl -H "${header}" -s "${REPOSITORY_URL}/${file}")
    else
        echo "Error: No library file specified to source" >&2
        exit 1
    fi
}


# Prepare for installation
_step_init_procedure() {
    global_debug_echo "Initializing installation procedure for ${_SOFTWARE_COMMAND}"
    global_log_message "INFO" "Starting installation of ${_SOFTWARE_COMMAND}"
    
    if global_check_if_installed "${_SOFTWARE_COMMAND}"; then
        global_debug_echo "${_SOFTWARE_COMMAND} is already installed, skipping installation"
        global_log_message "INFO" "${_SOFTWARE_COMMAND} is already installed"
        _step_update_status "SKIPPED"
        return 0
    fi
    global_debug_echo "Installation check passed, ${_SOFTWARE_COMMAND} is not installed"
}

# Main installation function
_step_install_dependencies() {
    global_debug_echo "Installing dependencies for ${_SOFTWARE_COMMAND}"
    global_log_message "INFO" "Installing dependencies for ${_SOFTWARE_COMMAND}"

    global_debug_echo "Running installation for dependencies: curl, wget"
    global_install_apt_package "curl" "wget"
    global_debug_echo "Dependencies installed successfully"
}

# Install the software
_step_install_software() {
    global_debug_echo "Beginning installation of ${_SOFTWARE_COMMAND}"
    global_log_message "INFO" "Installing ${_SOFTWARE_COMMAND}"
    echo "Installing ${_SOFTWARE_COMMAND}..."
    # Implement installation logic here
    global_debug_echo "Installation logic completed for ${_SOFTWARE_COMMAND}"
}


# Post-installation configuration
_step_post_install() {
    global_debug_echo "Beginning post-installation configuration"
    global_log_message "INFO" "Configuring ${_SOFTWARE_COMMAND}"
    echo "Configuring ${_SOFTWARE_COMMAND}..."
    # Implement post-installation configuration
    global_debug_echo "Post-installation configuration completed"
}

# Update installation status
_step_update_status() {
    local status="$1"
    global_debug_echo "Updating installation status to: ${status}"
    INSTALLATION_STATUS["${_SOFTWARE_COMMAND}"]="${status}"
    global_log_message "INFO" "Installation status for ${_SOFTWARE_COMMAND}: ${status}"
    global_debug_echo "Status updated successfully"
}

# Cleanup after installation
_step_cleanup() {
    global_debug_echo "Performing cleanup after installation"
    global_log_message "INFO" "Cleaning up after installation of ${_SOFTWARE_COMMAND}"
    # Add cleanup logic here if needed
    global_debug_echo "Cleanup completed"
}

# Execute main function
main "$@" 
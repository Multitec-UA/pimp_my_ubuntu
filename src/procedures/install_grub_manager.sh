#!/usr/bin/env bash

# =============================================================================
# Pimp My Ubuntu - Grub Customizer Installation
# =============================================================================
# Description: Installs Grub Customizer for managing GRUB bootloader settings
# Author: Multitec-UA
# Repository: https://github.com/Multitec-UA/pimp_my_ubuntu
# License: MIT
# =============================================================================

# Software-specific constants
readonly _SOFTWARE_COMMAND="grub-customizer"
readonly _SOFTWARE_DESCRIPTION="Grub Customizer is a tool for managing GRUB bootloader settings"
readonly _SOFTWARE_VERSION="1.0.0"

# Declare INSTALLATION_STATUS if not already declared
if ! declare -p INSTALLATION_STATUS >/dev/null 2>&1; then
    declare -A INSTALLATION_STATUS
fi

# Strict mode
set -euo pipefail


# Main procedure function
main() {

    # Source global variables and functions
    _source_lib "/src/lib/global_utils.sh"
    
    global_check_root



    _step_init_procedure

    if [ "$(global_get_status "${_SOFTWARE_COMMAND}")" == "SKIPPED" ]; then
        global_log_message "INFO" "${_SOFTWARE_COMMAND} is already installed"
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

# Main installation function
_step_install_dependencies() {
    global_log_message "INFO" "Installing dependencies for ${_SOFTWARE_COMMAND}"

    global_install_apt_package "curl" "wget" "coreutils"
    
}

# Install the software
_step_install_software() {
    global_log_message "INFO" "Installing ${_SOFTWARE_COMMAND}"

    global_add_apt_repository "ppa:danielrichter2007/grub-customizer"
    global_install_apt_package "grub-customizer"

}


# Post-installation configuration
_step_post_install() {
    global_log_message "INFO" "Post installation of ${_SOFTWARE_COMMAND}"
    # Implement post-installation configuration
}


# Prepare for installation
_step_init_procedure() {
    global_log_message "INFO" "Starting installation of ${_SOFTWARE_COMMAND}"
    
    if global_check_if_installed "${_SOFTWARE_COMMAND}"; then
        global_log_message "INFO" "${_SOFTWARE_COMMAND} is already installed"
        global_set_status "${_SOFTWARE_COMMAND}" "SKIPPED"
        return 0
    fi
}

# Cleanup after installation
_step_cleanup() {
    global_log_message "INFO" "Cleaning up after installation of ${_SOFTWARE_COMMAND}"
    # Add cleanup logic here if needed
}
# Execute main function
main "$@" 
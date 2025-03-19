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
readonly DEBUG=${DEBUG:-true}

# Software-common constants
readonly _REPOSITORY_URL="https://api.github.com/repos/Multitec-UA/pimp_my_ubuntu/contents"
readonly _SOFTWARE_COMMAND="grub-customizer"
readonly _SOFTWARE_DESCRIPTION="Grub Customizer is a tool for managing GRUB bootloader settings and install a theme"
readonly _SOFTWARE_VERSION="1.0.0"

# Software-specific constants
# Options: crt-amber-theme, monterey-theme
readonly _THEME_NAME="monterey-theme"

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

    # TODO REMOVE THIS
    _step_post_install
    exit 0

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
_step_init_procedure() {
    global_log_message "INFO" "Starting installation of ${_SOFTWARE_COMMAND}"
    
    if global_check_if_installed "${_SOFTWARE_COMMAND}"; then
        global_set_status "${_SOFTWARE_COMMAND}" "SKIPPED"
        return 0
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
    
    global_log_message "INFO" "Installing grub theme"
    _install_grub_theme
}

# Install GRUB theme
_install_grub_theme() {
    
    
    # Download and extract theme
    global_log_message "INFO" "Downloading and extracting GRUB theme"
    global_download_media "/src/procedures/install_grub_manager/media/${_THEME_NAME}.zip"
    
    # Create themes directory if it doesn't exist
    global_log_message "INFO" "Creating GRUB themes directory"
    sudo mkdir -p /boot/grub/themes
    
    # Extract theme to GRUB themes directory
    global_log_message "INFO" "Extracting theme to GRUB themes directory"
    sudo unzip -o "${GLOBAL_DOWNLOAD_DIR}/${_THEME_NAME}.zip" -d /boot/grub/themes/ >>"${LOG_FILE}" 2>&1
    
    # Edit GRUB configuration
    global_log_message "INFO" "Configuring GRUB theme"
    sudo sed -i "s/^.*GRUB_THEME=.*/GRUB_THEME=\"\/boot\/grub\/themes\/${_THEME_NAME}\/theme.txt\"/" /etc/default/grub
    
    # Update GRUB
    global_log_message "INFO" "Updating GRUB configuration"
    # If DEBUG is true, show the output of the update-grub command
    sudo update-grub >>"${LOG_FILE}" 2>&1
    
    global_log_message "INFO" "GRUB theme installation completed. Changes will take effect after next reboot."
}

# Cleanup after installation
_step_cleanup() {
    global_log_message "INFO" "Cleaning up after installation of ${_SOFTWARE_COMMAND}"
    # Add cleanup logic here if needed
}

# Execute main function
main "$@" 
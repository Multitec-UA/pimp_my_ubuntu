#!/usr/bin/env bash

# =============================================================================
# Pimp My Ubuntu - Grub Customizer Installation
# =============================================================================
# Description: Installs Grub Customizer for managing GRUB bootloader settings
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

# Software-common constants
readonly _REPOSITORY_RAW_URL="https://raw.github.com/Multitec-UA/pimp_my_ubuntu/main"
readonly _LIBS_REMOTE_URL="${_REPOSITORY_RAW_URL}/src/libs/"
readonly _SOFTWARE_COMMAND="test"
readonly _SOFTWARE_DESCRIPTION="Test procedure"
readonly _SOFTWARE_VERSION="1.0.0"
readonly _DEPENDENCIES=("curl" "wget" "coreutils")

# Software-specific constants
# More themes in https://www.gnome-look.org/ Add .zip with theme.txt file inside to media folder
readonly _THEME_OPTIONS=("crt-amber-theme" "monterey-theme" "solarized-theme" "cybergrub-theme") # Available theme options
readonly _THEME_POSITION=${1:-0} #Default theme position, can be overridden by command line argument
readonly _THEME_NAME="${_THEME_OPTIONS[_THEME_POSITION]}"
readonly _MEDIA_PATH="/src/procedures/grub-customizer/media"



# Main procedure function
main() {

    # Source global variables and functions
    _source_lib "global_utils.sh"
    
    global_check_root
    echo "TEST: GLOBAL_INSTALLATION_STATUS: ${GLOBAL_INSTALLATION_STATUS[@]}"
    global_set_installation_status "${_SOFTWARE_COMMAND}" "SUCCESS"
    global_set_installation_status "debug" "FAILED"
    echo "TEST: GLOBAL_INSTALLATION_STATUS: ${GLOBAL_INSTALLATION_STATUS[@]}"
    echo "TEST: GLOBAL_INSTALLATION_STATUS_KEYS: ${!GLOBAL_INSTALLATION_STATUS[@]}"

    echo "TEST: STATUS: $(global_get_installation_status ${_SOFTWARE_COMMAND})"
    echo "TEST: GLOBAL_INSTALLATION_STATUS: ${GLOBAL_INSTALLATION_STATUS[@]}"
    exit 0
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
    
    if global_check_if_installed "${_SOFTWARE_COMMAND}"; then
        global_set_installation_status "${_SOFTWARE_COMMAND}" "SKIPPED"
        return 0
    fi
}

# Main installation function
_step_install_dependencies() {
    global_log_message "INFO" "Installing dependencies for ${_SOFTWARE_COMMAND}"
    global_install_apt_package "${_DEPENDENCIES[@]}"
    
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

# Cleanup after installation
_step_cleanup() {
    global_log_message "INFO" "Cleaning up after installation of ${_SOFTWARE_COMMAND}"
    
    # Remove downloaded theme file if it exists
    if [[ -f "${GLOBAL_DOWNLOAD_DIR}/${_THEME_NAME}.zip" ]]; then
        global_log_message "DEBUG" "Removing downloaded theme file"
        rm -f "${GLOBAL_DOWNLOAD_DIR}/${_THEME_NAME}.zip" >>"${GLOBAL_LOG_FILE}" 2>&1
    fi
    
    # Clean any temporary files that might have been created
    if [[ -d "/tmp/grub-customizer-temp" ]]; then
        global_log_message "DEBUG" "Removing temporary files"
        rm -rf "/tmp/grub-customizer-temp" >>"${GLOBAL_LOG_FILE}" 2>&1
    fi
    
    # Clean apt cache if we installed new packages
    if [[ "$(global_get_installation_status "${_SOFTWARE_COMMAND}")" == "SUCCESS" ]]; then
        global_log_message "DEBUG" "Cleaning apt cache"
        apt-get clean >>"${GLOBAL_LOG_FILE}" 2>&1
    fi
}

# Install GRUB theme
_install_grub_theme() {
    
    
    # Download and extract theme
    global_log_message "INFO" "Downloading and extracting GRUB theme"
    global_download_media "${_MEDIA_PATH}/${_THEME_NAME}.zip"
    
    # Create themes directory if it doesn't exist
    global_log_message "INFO" "Creating GRUB themes directory"
    sudo mkdir -p /boot/grub/themes
    
    # Extract theme to GRUB themes directory
    global_log_message "INFO" "Extracting theme to GRUB themes directory"
    sudo unzip -o "${GLOBAL_DOWNLOAD_DIR}/${_THEME_NAME}.zip" -d /boot/grub/themes/ >>"${GLOBAL_LOG_FILE}" 2>&1
    
    # Edit GRUB configuration
    global_log_message "INFO" "Configuring GRUB theme"
    sudo sed -i "s/^.*GRUB_THEME=.*/GRUB_THEME=\"\/boot\/grub\/themes\/${_THEME_NAME}\/theme.txt\"/" /etc/default/grub
    global_log_message "INFO" "Configuring GRUB Resolution to 1920x1080x24"    
    sudo sed -i "s/^.*GRUB_GFXMODE=.*/GRUB_GFXMODE=\"1920x1080x24\"/" /etc/default/grub
    global_log_message "INFO" "Configuring GRUB SAVEDEFAULT to true"
    sudo sed -i "s/^.*GRUB_SAVEDEFAULT=.*/GRUB_SAVEDEFAULT=\"true\"/" /etc/default/grub
    
    # Update GRUB
    global_log_message "INFO" "Updating GRUB configuration"
    sudo update-grub >>"${GLOBAL_LOG_FILE}" 2>&1
    
    global_log_message "INFO" "GRUB theme installation completed. Changes will take effect after next reboot."
}

# Execute main function
main "$@" 
#!/usr/bin/env bash

# =============================================================================
# Pimp My Ubuntu - Terminator Terminal Installation Procedure
# =============================================================================
# Description: Install and configure Terminator terminal emulator with custom settings
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
readonly _SOFTWARE_COMMAND="terminator"
readonly _SOFTWARE_DESCRIPTION="Terminator terminal emulator with custom configuration"
readonly _SOFTWARE_VERSION="1.0.0"
readonly _DEPENDENCIES=("python3-gi" "gir1.2-vte-2.91" "python3-psutil" "python3-configobj" "python3-six" "gir1.2-keybinder-3.0")
readonly _REPOSITORY_TAG="v0.1.0"
readonly _REPOSITORY_RAW_URL="https://raw.github.com/Multitec-UA/pimp_my_ubuntu/refs/tags/${_REPOSITORY_TAG}/"
readonly _LIBS_REMOTE_URL="${_REPOSITORY_RAW_URL}/src/libs/"

# Software-specific constants
# Note: Config paths will be set dynamically after sourcing global_utils.sh



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

    # Update package lists
    apt-get update >>"${GLOBAL_LOG_FILE}" 2>&1
    
    # Install dependencies from the _DEPENDENCIES array
    global_install_apt_package "${_DEPENDENCIES[@]}"
}

# Install the software
_step_install_software() {
    global_log_message "INFO" "Installing ${_SOFTWARE_COMMAND}"

    # Install Terminator via APT
    global_install_apt_package "${_SOFTWARE_COMMAND}"
    
    # Verify installation
    if global_check_if_installed "${_SOFTWARE_COMMAND}"; then
        global_log_message "INFO" "Successfully installed ${_SOFTWARE_COMMAND}"
        return 0
    else
        global_log_message "ERROR" "Failed to verify ${_SOFTWARE_COMMAND} installation"
        return 1
    fi
}

# Post-installation configuration
_step_post_install() {
    global_log_message "INFO" "Post installation of ${_SOFTWARE_COMMAND}"
    
    # Copy custom configuration
    _copy_terminator_config
    
    # Set Terminator as default terminal
    _set_default_terminal
    
    global_log_message "INFO" "Terminator configuration completed"
}

# Copy the custom configuration file
_copy_terminator_config() {
    global_log_message "INFO" "Configuring ${_SOFTWARE_COMMAND}"
    
    # Define paths dynamically now that GLOBAL_REAL_HOME is available
    local terminator_config_dir="${GLOBAL_REAL_HOME}/.config/terminator"
    local terminator_config_file="${terminator_config_dir}/config"
    
    # Create the terminator config directory
    global_run_as_user mkdir -p "${terminator_config_dir}"
    
    # Backup existing config if it exists
    if [[ -f "${terminator_config_file}" ]]; then
        global_log_message "INFO" "Backing up existing terminator config"
        global_run_as_user cp "${terminator_config_file}" "${terminator_config_file}.backup.$(date +%Y%m%d_%H%M%S)" >>"${GLOBAL_LOG_FILE}" 2>&1
    fi
    
    # Copy the custom config file from the files directory
    local source_config
    if [[ "$LOCAL" == "true" ]]; then
        source_config="./src/procedures/terminator/files/config"
    else
        source_config="${_REPOSITORY_RAW_URL}/src/procedures/terminator/files/config"
        # Download the config file first
        global_log_message "INFO" "Downloading terminator config file"
        if ! curl -fsSL "${source_config}" -o "${terminator_config_file}" >>"${GLOBAL_LOG_FILE}" 2>&1; then
            global_log_message "ERROR" "Failed to download terminator config file"
            return 1
        fi
    fi
    
    if [[ "$LOCAL" == "true" ]]; then
        # Copy from local file system
        if [[ -f "${source_config}" ]]; then
            global_log_message "INFO" "Copying custom config from local file"
            cp "${source_config}" "${terminator_config_file}" >>"${GLOBAL_LOG_FILE}" 2>&1
        else
            global_log_message "ERROR" "Source config file not found: ${source_config}"
            return 1
        fi
    fi
    
    # Set proper ownership for the config file
    chown "${GLOBAL_REAL_USER}:${GLOBAL_REAL_USER}" "${terminator_config_file}" >>"${GLOBAL_LOG_FILE}" 2>&1
    
    # Set proper ownership for the config directory
    chown -R "${GLOBAL_REAL_USER}:${GLOBAL_REAL_USER}" "${terminator_config_dir}" >>"${GLOBAL_LOG_FILE}" 2>&1
    
    global_log_message "INFO" "Terminator config file copied successfully"
}

# Set Terminator as the default terminal
_set_default_terminal() {
    global_log_message "INFO" "Setting ${_SOFTWARE_COMMAND} as default terminal"
    
    # Check if terminator is available in alternatives
    if update-alternatives --query x-terminal-emulator | grep -q terminator; then
        global_log_message "INFO" "Terminator already in alternatives system"
    else
        # Add terminator to alternatives if not present
        global_log_message "INFO" "Adding terminator to alternatives system"
        update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/bin/terminator 50 >>"${GLOBAL_LOG_FILE}" 2>&1
    fi
    
    # Set terminator as the default
    global_log_message "INFO" "Setting terminator as default x-terminal-emulator"
    update-alternatives --set x-terminal-emulator /usr/bin/terminator >>"${GLOBAL_LOG_FILE}" 2>&1
    
    # Also set it for GNOME if gsettings is available
    if command -v gsettings >/dev/null 2>&1; then
        global_log_message "INFO" "Setting terminator as default terminal in GNOME"
        global_run_as_user gsettings set org.gnome.desktop.default-applications.terminal exec '/usr/bin/terminator' >>"${GLOBAL_LOG_FILE}" 2>&1
        global_run_as_user gsettings set org.gnome.desktop.default-applications.terminal exec-arg '--new-tab' >>"${GLOBAL_LOG_FILE}" 2>&1
    fi
    
    global_log_message "INFO" "Terminator set as default terminal successfully"
}

# Cleanup after installation
_step_cleanup() {
    global_log_message "INFO" "Cleaning up after installation of ${_SOFTWARE_COMMAND}"
    
    # Clean apt cache if we installed new packages
    if [[ "$(global_get_proc_status "${_SOFTWARE_COMMAND}")" == "SUCCESS" ]]; then
        global_log_message "DEBUG" "Cleaning apt cache"
        apt-get clean >>"${GLOBAL_LOG_FILE}" 2>&1
    fi
}

# Source global variables and functions
if [[ "$LOCAL" == "true" ]]; then
    # Strict mode
    set -euo pipefail
    # Source libraries from local directory
    source "./src/libs/global_utils.sh"
else
    # Source libraries from remote repository
    _source_lib "global_utils.sh"
fi

# Execute main function
main "$@"


# Exit with success
exit 0

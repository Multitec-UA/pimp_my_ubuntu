#!/usr/bin/env bash

# =============================================================================
# Pimp My Ubuntu - Cursor Installation
# =============================================================================
# Description: Installs Cursor IDE with all necessary dependencies and configurations
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
readonly _REPOSITORY_TAG="v0.1.0"
readonly _REPOSITORY_RAW_URL="https://raw.github.com/Multitec-UA/pimp_my_ubuntu/refs/tags/${_REPOSITORY_TAG}/"
readonly _LIBS_REMOTE_URL="${_REPOSITORY_RAW_URL}/src/libs/"
readonly _SOFTWARE_COMMAND="cursor"
readonly _SOFTWARE_DESCRIPTION="A modern and powerful IDE with AI integrated"
readonly _SOFTWARE_VERSION="0.49.6"
readonly _CURSOR_DOWNLOAD_URL="https://downloads.cursor.com/production/0781e811de386a0c5bcb07ceb259df8ff8246a52/linux/x64/Cursor-0.49.6-x86_64.AppImage"



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
    global_log_message "DEBUG" "Exiting _source_lib"
}


# Software-specific constants
readonly _APPLICATIONS_DIR="${GLOBAL_REAL_HOME}/Applications"
readonly _CURSOR_APPIMAGE="${_APPLICATIONS_DIR}/cursor.AppImage"
readonly _USER_CONFIG_DIR="${GLOBAL_REAL_HOME}/.config"
readonly _USER_LOCAL_DIR="${GLOBAL_REAL_HOME}/.local"
readonly _SHELL_RC_FILES=("${GLOBAL_REAL_HOME}/.bashrc" "${GLOBAL_REAL_HOME}/.zshrc")



# Main procedure function
main() {


    global_log_message "DEBUG" "Entering main function"
    
    # Check if the script is running with root privileges
    global_check_root

    # Show  global variables and install basic dependencies
    _show_global_variables

    # Show  global variables and install basic dependencies
    _step_init

    _step_install_dependencies

    _step_install_software
    _step_post_install
    global_log_message "INFO" "${_SOFTWARE_COMMAND} installation completed successfully"
    global_set_proc_status "${_SOFTWARE_COMMAND}" "SUCCESS"
    _step_cleanup
    global_log_message "DEBUG" "Exiting main function"

}



# Show global variables
_show_global_variables() {
    global_log_message "DEBUG" "_REPOSITORY_RAW_URL: ${_REPOSITORY_RAW_URL}"
    global_log_message "DEBUG" "_LIBS_REMOTE_URL: ${_LIBS_REMOTE_URL}"
    global_log_message "DEBUG" "_SOFTWARE_COMMAND: ${_SOFTWARE_COMMAND}"
    global_log_message "DEBUG" "_SOFTWARE_DESCRIPTION: ${_SOFTWARE_DESCRIPTION}"
    global_log_message "DEBUG" "_SOFTWARE_VERSION: ${_SOFTWARE_VERSION}"
    global_log_message "DEBUG" "_CURSOR_DOWNLOAD_URL: ${_CURSOR_DOWNLOAD_URL}"
    global_log_message "DEBUG" "_CURSOR_APPIMAGE: ${_CURSOR_APPIMAGE}"
    global_log_message "DEBUG" "_APPLICATIONS_DIR: ${_APPLICATIONS_DIR}"
    global_log_message "DEBUG" "_USER_CONFIG_DIR: ${_USER_CONFIG_DIR}"
    global_log_message "DEBUG" "_USER_LOCAL_DIR: ${_USER_LOCAL_DIR}"
    global_log_message "DEBUG" "_SHELL_RC_FILES: ${_SHELL_RC_FILES[@]}"
    global_log_message "DEBUG" "GLOBAL_REAL_USER: ${GLOBAL_REAL_USER}"
    global_log_message "DEBUG" "GLOBAL_REAL_HOME: ${GLOBAL_REAL_HOME}"  
    global_log_message "DEBUG" "GLOBAL_LOG_FILE: ${GLOBAL_LOG_FILE}"
    global_log_message "DEBUG" "GLOBAL_TEMP_PATH: ${GLOBAL_TEMP_PATH}"
    global_log_message "DEBUG" "GLOBAL_STATUS_FILE: ${GLOBAL_STATUS_FILE}"
    global_log_message "DEBUG" "GLOBAL_STATUS_FILE_INITIALIZED: ${GLOBAL_STATUS_FILE_INITIALIZED}"
    global_log_message "DEBUG" "GLOBAL_INSTALLATION_STATUS: ${GLOBAL_INSTALLATION_STATUS[@]}"
}
# Prepare for installation
_step_init() {
    global_log_message "DEBUG" "Entering _step_init"
    global_log_message "INFO" "Starting installation of ${_SOFTWARE_COMMAND}"
    global_log_message "INFO" "_SOFTWARE_VERSION: ${_SOFTWARE_VERSION}"
    
    if global_check_if_installed "${_SOFTWARE_COMMAND}"; then
        global_set_proc_status "${_SOFTWARE_COMMAND}" "SKIPPED"
        return 0
    fi
    
    # Create Applications directory if it doesn't exist
    global_ensure_dir "${_APPLICATIONS_DIR}"
    
    # Remove any existing AppImage launcher conflicts
    if systemctl --user -q is-active appimaged.service 2>/dev/null; then
        global_run_as_user systemctl --user stop appimaged.service >>"${GLOBAL_LOG_FILE}" 2>&1 || true
    fi
    apt-get -y purge appimagelauncher >>"${GLOBAL_LOG_FILE}" 2>&1 || true
    rm -f "${_USER_CONFIG_DIR}/systemd/user/default.target.wants/appimagelauncherd.service" >>"${GLOBAL_LOG_FILE}" 2>&1 || true
    rm -f "${_USER_LOCAL_DIR}/share/applications/appimage"* >>"${GLOBAL_LOG_FILE}" 2>&1 || true
    global_log_message "DEBUG" "Exiting _step_init"
}

# Install dependencies
_step_install_dependencies() {
    global_log_message "DEBUG" "Entering _step_install_dependencies"
    global_log_message "INFO" "Installing dependencies for ${_SOFTWARE_COMMAND}"

    # Update package lists
    apt-get update >>"${GLOBAL_LOG_FILE}" 2>&1

    # First, ensure curl and wget are installed
    global_install_apt_package "curl" "wget"

    # Handle FUSE packages carefully
    global_log_message "INFO" "Installing FUSE packages"
    
    # Remove old fuse if installed to prevent conflicts
    if dpkg -l | grep -q "^ii  fuse "; then
        apt-get remove -y fuse >>"${GLOBAL_LOG_FILE}" 2>&1
    fi

    # Install FUSE3 packages
    global_install_apt_package "libfuse3-3" "fuse3"

    # Install libfuse2 for compatibility
    if ! dpkg -l | grep -q "^ii  libfuse2"; then
        global_install_apt_package "libfuse2"
    fi
    global_log_message "DEBUG" "Exiting _step_install_dependencies"
}

# Install the software
_step_install_software() {
    global_log_message "DEBUG" "Entering _step_install_software"
    global_log_message "INFO" "Installing ${_SOFTWARE_COMMAND}"
    
    # Install appimaged
    global_log_message "INFO" "Installing appimaged"
    local appimaged_url
    appimaged_url=$(global_run_as_user wget -q https://github.com/probonopd/go-appimage/releases/expanded_assets/continuous -O - | grep "appimaged-.*-x86_64.AppImage" | head -n 1 | cut -d '"' -f 2)
    global_run_as_user wget -c "https://github.com/${appimaged_url}" -P "${_APPLICATIONS_DIR}/" >>"${GLOBAL_LOG_FILE}" 2>&1
    global_run_as_user chmod +x "${_APPLICATIONS_DIR}"/appimaged-*.AppImage >>"${GLOBAL_LOG_FILE}" 2>&1
    
    # Fix sandbox issues
    global_log_message "INFO" "Configuring system settings"
    if ! grep -q "kernel.apparmor_restrict_unprivileged_unconfined" /etc/sysctl.d/99-cursor.conf 2>/dev/null; then
        echo "kernel.apparmor_restrict_unprivileged_unconfined=0" >> /etc/sysctl.d/99-cursor.conf
        echo "kernel.apparmor_restrict_unprivileged_userns=0" >> /etc/sysctl.d/99-cursor.conf
        sysctl -p /etc/sysctl.d/99-cursor.conf >>"${GLOBAL_LOG_FILE}" 2>&1
    fi
    
    # Download and verify Cursor AppImage
    if ! _download_cursor_appimage; then
        global_log_message "ERROR" "Failed to download Cursor AppImage"
        return 1
    fi

    global_log_message "DEBUG" "Exiting _step_install_software"
    return 0
}

# Function to download and verify Cursor AppImage
_download_cursor_appimage() {
    global_log_message "DEBUG" "Entering _download_cursor_appimage"
    global_log_message "INFO" "Downloading Cursor AppImage to ${_CURSOR_APPIMAGE}"
    
    # Download Cursor AppImage
    global_run_as_user curl -L -s "${_CURSOR_DOWNLOAD_URL}" -o "${_CURSOR_APPIMAGE}" >>"${GLOBAL_LOG_FILE}" 2>&1
    
    # Check if the downloaded file exists and has minimum size
    if ! global_check_file_size "${_CURSOR_APPIMAGE}"; then
        global_log_message "ERROR" "Failed to download Cursor AppImage or file is corrupted"
        return 1
    fi
    
    # Make the file executable
    global_run_as_user chmod +x "${_CURSOR_APPIMAGE}" >>"${GLOBAL_LOG_FILE}" 2>&1
    
    global_log_message "DEBUG" "Exiting _download_cursor_appimage"
    return 0
}

_delete_previous_cursor_function() {
    local rc_file="${1:-}"
    global_log_message "DEBUG" "Entering _delete_previous_cursor_function with rc_file: ${rc_file}"
    if grep -q "cursor()" "${rc_file}"; then
        global_log_message "INFO" "Deleting previous cursor function from ${rc_file}"
        sed -i '/cursor()/,/^}/d' "${rc_file}"
    fi
    global_log_message "DEBUG" "Exiting _delete_previous_cursor_function"
}

# Post-installation configuration
_step_post_install() {
    global_log_message "DEBUG" "Entering _step_post_install"
    global_log_message "INFO" "Configuring ${_SOFTWARE_COMMAND}"
    
    # Add cursor function to shell RC files
    local cursor_function='
cursor() {
    local folder_path="${1:-}"
    # Find the Cursor AppImage in the home directory
    local cursor_path="$HOME/Applications/cursor.AppImage"

    # Ensure the AppImage is executable
    chmod +x "$cursor_path"

    # Launch Cursor - either in current directory or with specified path
    if [[ -z "$folder_path" ]]; then
        # No arguments, launch in current directory
        "$cursor_path" --no-sandbox >/dev/null 2>&1 &
    else
        # Convert relative path to absolute and open that location
        "$cursor_path" --no-sandbox "$(realpath "$folder_path")" >/dev/null 2>&1 &
    fi
    # Prevent the process from being killed when terminal closes
    disown
}'

    # Loop through each shell RC file (bashrc, zshrc)
    for rc_file in "${_SHELL_RC_FILES[@]}"; do
        global_log_message "DEBUG" "Reading ${rc_file} file"
        # Check if the RC file exists
        if [[ -f "${rc_file}" ]]; then
            global_log_message "DEBUG" "Check if the cursor function is already defined in the RC file"
            if grep -q "cursor()" "${rc_file}"; then
                _delete_previous_cursor_function "${rc_file}"
            fi
            global_log_message "DEBUG" "Append the cursor function to the RC file if not already present"
            echo "${cursor_function}" >> "${rc_file}"
            # Ensure the RC file has the correct ownership
            chown "${GLOBAL_REAL_USER}:${GLOBAL_REAL_USER}" "${rc_file}" >>"${GLOBAL_LOG_FILE}" 2>&1
            
            # Verify the function was added correctly
            if grep -q "cursor()" "${rc_file}"; then
                global_log_message "INFO" "Successfully added cursor function to ${rc_file}"
            else
                global_log_message "WARNING" "Failed to add cursor function to ${rc_file}"
            fi

        fi
    done
    
    # Start appimaged
    global_log_message "INFO" "Starting appimaged"
    global_run_as_user XDG_RUNTIME_DIR="/run/user/$(id -u ${GLOBAL_REAL_USER})" "${_APPLICATIONS_DIR}"/appimaged-*.AppImage >>"${GLOBAL_LOG_FILE}" 2>&1 &
    
    global_log_message "INFO" "Installation of ${_SOFTWARE_COMMAND} completed"
    global_log_message "DEBUG" "Exiting _step_post_install"
}

# Cleanup after installation
_step_cleanup() {
    global_log_message "DEBUG" "Entering _step_cleanup"
    global_log_message "INFO" "Cleaning up after installation of ${_SOFTWARE_COMMAND}"
    
    # Clean apt cache if we installed new packages
    if [[ "$(global_get_proc_status "${_SOFTWARE_COMMAND}")" == "SUCCESS" ]]; then
        global_log_message "DEBUG" "Cleaning apt cache"
        apt-get clean >>"${GLOBAL_LOG_FILE}" 2>&1
    fi
    global_log_message "DEBUG" "Exiting _step_cleanup"
}

# Source libraries
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

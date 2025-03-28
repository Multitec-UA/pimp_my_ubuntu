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

# Software-common constants
readonly _REPOSITORY_RAW_URL="https://raw.github.com/Multitec-UA/pimp_my_ubuntu/main"
readonly _LIBS_REMOTE_URL="${_REPOSITORY_RAW_URL}/src/libs/"
readonly _SOFTWARE_COMMAND="cursor"
readonly _SOFTWARE_DESCRIPTION="A modern and powerful IDE built on web technologies"
readonly _SOFTWARE_VERSION="latest"

# Software-specific constants
readonly _APPLICATIONS_DIR="${GLOBAL_REAL_HOME}/Applications"
readonly _CURSOR_APPIMAGE="${_APPLICATIONS_DIR}/cursor.AppImage"
readonly _USER_CONFIG_DIR="${GLOBAL_REAL_HOME}/.config"
readonly _USER_LOCAL_DIR="${GLOBAL_REAL_HOME}/.local"
readonly _SHELL_RC_FILES=("${GLOBAL_REAL_HOME}/.bashrc" "${GLOBAL_REAL_HOME}/.zshrc")



# Main procedure function
main() {

    # Source global variables and functions
    _source_lib "global_utils.sh"
    
    global_check_root

    _step_init

    if [ "$(global_get_installation_status "${_SOFTWARE_COMMAND}")" == "SKIPPED" ]; then
        global_log_message "INFO" "${_SOFTWARE_COMMAND} is already installed"
        _step_post_install
        _step_cleanup
        return 0
    fi

    _step_install_dependencies

    if _step_install_software; then
        _step_post_install
        global_log_message "INFO" "${_SOFTWARE_COMMAND} installation completed successfully"
        global_set_installation_status "${_SOFTWARE_COMMAND}" "SUCCESS"
        _step_cleanup
        return 0
    else
        global_log_message "ERROR" "Failed to install ${_SOFTWARE_COMMAND}"
        global_set_installation_status "${_SOFTWARE_COMMAND}" "FAILED"
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
            global_log_message "ERROR" "Failed to source library: ${file}"
            exit 1
        fi
        global_log_message "DEBUG" "Successfully sourced library: ${file}"
    else
        global_log_message "ERROR" "No library file specified to source"
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
    
    # Create Applications directory if it doesn't exist
    global_ensure_dir "${_APPLICATIONS_DIR}"
    
    # Remove any existing AppImage launcher conflicts
    if systemctl --user -q is-active appimaged.service 2>/dev/null; then
        global_run_as_user systemctl --user stop appimaged.service >>"${GLOBAL_LOG_FILE}" 2>&1 || true
    fi
    apt-get -y purge appimagelauncher >>"${GLOBAL_LOG_FILE}" 2>&1 || true
    rm -f "${_USER_CONFIG_DIR}/systemd/user/default.target.wants/appimagelauncherd.service" >>"${GLOBAL_LOG_FILE}" 2>&1 || true
    rm -f "${_USER_LOCAL_DIR}/share/applications/appimage"* >>"${GLOBAL_LOG_FILE}" 2>&1 || true
}

# Install dependencies
_step_install_dependencies() {
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
}

# Install the software
_step_install_software() {
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
    
    # Download Cursor AppImage
    global_log_message "INFO" "Downloading Cursor AppImage"
    global_run_as_user curl -L "https://download.cursor.sh/linux/appImage/x64" -o "${_CURSOR_APPIMAGE}" >>"${GLOBAL_LOG_FILE}" 2>&1
    global_run_as_user chmod +x "${_CURSOR_APPIMAGE}" >>"${GLOBAL_LOG_FILE}" 2>&1

    return 0
}

# Post-installation configuration
_step_post_install() {
    global_log_message "INFO" "Configuring ${_SOFTWARE_COMMAND}"
    
    # Add cursor function to shell RC files
    local cursor_function='
# Cursor IDE launcher function
cursor() {
    local cursor_path=$(find $HOME/Applications -name "cursor*.AppImage" -type f | head -n 1)
    local cursor_args="--no-sandbox"
    if [ $# -eq 0 ]; then
        nohup "$cursor_path" $cursor_args >/dev/null 2>&1 &
        disown
    else
        # Convert relative path to absolute
        local path=$(realpath "$1")
        nohup "$cursor_path" $cursor_args "$path" >/dev/null 2>&1 &
        disown
    fi
}'

    # Loop through each shell RC file (bashrc, zshrc)
    for rc_file in "${_SHELL_RC_FILES[@]}"; do
        # Check if the RC file exists
        if [[ -f "${rc_file}" ]]; then
            # Check if the cursor function is already defined in the RC file
            if ! grep -q "cursor()" "${rc_file}"; then
                # Append the cursor function to the RC file if not already present
                echo "${cursor_function}" >> "${rc_file}"
                # Ensure the RC file has the correct ownership
                chown "${GLOBAL_REAL_USER}:${GLOBAL_REAL_USER}" "${rc_file}" >>"${GLOBAL_LOG_FILE}" 2>&1
                
                # Verify the function was added correctly
                if grep -q "cursor()" "${rc_file}"; then
                    global_log_message "INFO" "Successfully added cursor function to ${rc_file}"
                else
                    global_log_message "WARNING" "Failed to add cursor function to ${rc_file}"
                fi
            else
                global_log_message "INFO" "Cursor function already exists in ${rc_file}"
            fi
        fi
    done
    
    # Start appimaged
    global_log_message "INFO" "Starting appimaged"
    global_run_as_user XDG_RUNTIME_DIR="/run/user/$(id -u ${GLOBAL_REAL_USER})" "${_APPLICATIONS_DIR}"/appimaged-*.AppImage >>"${GLOBAL_LOG_FILE}" 2>&1 &
    
    global_log_message "INFO" "Installation of ${_SOFTWARE_COMMAND} completed"
}

# Cleanup after installation
_step_cleanup() {
    global_log_message "INFO" "Cleaning up after installation of ${_SOFTWARE_COMMAND}"
    
    # Clean apt cache if we installed new packages
    if [[ "$(global_get_installation_status "${_SOFTWARE_COMMAND}")" == "SUCCESS" ]]; then
        global_log_message "DEBUG" "Cleaning apt cache"
        apt-get clean >>"${GLOBAL_LOG_FILE}" 2>&1
    fi
}

# Execute main function
main "$@"

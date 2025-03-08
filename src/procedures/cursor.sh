#!/usr/bin/env bash

# =============================================================================
# Pimp My Ubuntu - Cursor Installation Procedure
# =============================================================================
# Description: Installs Cursor IDE with all necessary dependencies and configurations
# Author: Multitec-UA
# Repository: https://github.com/Multitec-UA/pimp_my_ubuntu
# License: MIT
# =============================================================================

# Strict mode
set -euo pipefail

# Source global variables and functions
# shellcheck source=../lib/globals.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/globals.sh"

# Software-specific constants
readonly SOFTWARE_NAME="Cursor IDE"
readonly SOFTWARE_DESCRIPTION="A modern and powerful IDE built on web technologies"
readonly SOFTWARE_VERSION="latest"
readonly CURSOR_APPIMAGE="${APPLICATIONS_DIR}/cursor.AppImage"

# Check if all required dependencies are installed
check_dependencies() {
    log_message "INFO" "Checking and installing dependencies for ${SOFTWARE_NAME}"
    
    # Update package lists
    apt-get update

    # First, ensure curl and wget are installed
    apt-get install -y curl wget

    # Handle FUSE packages carefully
    log_message "INFO" "Installing FUSE packages"
    
    # Remove old fuse if installed to prevent conflicts
    if dpkg -l | grep -q "^ii  fuse "; then
        apt-get remove -y fuse
    fi

    # Install FUSE3 packages
    apt-get install -y libfuse3-3 fuse3

    # Install libfuse2 for compatibility
    if ! dpkg -l | grep -q "^ii  libfuse2"; then
        apt-get install -y libfuse2
    fi
}

# Check if software is already installed
check_if_installed() {
    [[ -f "${CURSOR_APPIMAGE}" ]] && return 0
    return 1
}

# Prepare for installation
prepare_installation() {
    log_message "INFO" "Preparing ${SOFTWARE_NAME} installation"
    
    # Create Applications directory if it doesn't exist
    ensure_dir "${APPLICATIONS_DIR}"
    
    # Remove any existing AppImage launcher conflicts
    if systemctl --user -q is-active appimaged.service 2>/dev/null; then
        run_as_user systemctl --user stop appimaged.service || true
    fi
    apt-get -y purge appimagelauncher || true
    rm -f "${USER_CONFIG_DIR}/systemd/user/default.target.wants/appimagelauncherd.service" || true
    rm -f "${USER_LOCAL_DIR}/share/applications/appimage"* || true
}

# Main installation function
install_software() {
    log_message "INFO" "Installing ${SOFTWARE_NAME}"
    
    # Install appimaged
    log_message "INFO" "Installing appimaged"
    local appimaged_url
    appimaged_url=$(run_as_user wget -q https://github.com/probonopd/go-appimage/releases/expanded_assets/continuous -O - | grep "appimaged-.*-x86_64.AppImage" | head -n 1 | cut -d '"' -f 2)
    run_as_user wget -c "https://github.com/${appimaged_url}" -P "${APPLICATIONS_DIR}/"
    run_as_user chmod +x "${APPLICATIONS_DIR}"/appimaged-*.AppImage
    
    # Fix sandbox issues
    log_message "INFO" "Configuring system settings"
    if ! grep -q "kernel.apparmor_restrict_unprivileged_unconfined" /etc/sysctl.d/99-cursor.conf 2>/dev/null; then
        echo "kernel.apparmor_restrict_unprivileged_unconfined=0" >> /etc/sysctl.d/99-cursor.conf
        echo "kernel.apparmor_restrict_unprivileged_userns=0" >> /etc/sysctl.d/99-cursor.conf
        sysctl -p /etc/sysctl.d/99-cursor.conf
    fi
    
    # Download Cursor AppImage
    log_message "INFO" "Downloading Cursor AppImage"
    run_as_user curl -L "https://download.cursor.sh/linux/appImage/x64" -o "${CURSOR_APPIMAGE}"
    run_as_user chmod +x "${CURSOR_APPIMAGE}"

    return 0
}

# Post-installation configuration
post_install() {
    log_message "INFO" "Configuring ${SOFTWARE_NAME}"
    
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

    for rc_file in "${SHELL_RC_FILES[@]}"; do
        if [[ -f "${rc_file}" ]]; then
            if ! grep -q "cursor()" "${rc_file}"; then
                echo "${cursor_function}" >> "${rc_file}"
                chown "${REAL_USER}:${REAL_USER}" "${rc_file}"
            fi
        fi
    done
    
    # Start appimaged
    log_message "INFO" "Starting appimaged"
    run_as_user XDG_RUNTIME_DIR="/run/user/$(id -u ${REAL_USER})" "${APPLICATIONS_DIR}"/appimaged-*.AppImage &
    
    log_message "INFO" "Installation of ${SOFTWARE_NAME} completed"
    echo "Installation completed! You can now run Cursor by typing 'cursor' in your terminal."
    echo "Note: You may need to log out and back in for the group changes to take effect."
}

# Update installation status
update_status() {
    local status="$1"
    INSTALLATION_STATUS["${SOFTWARE_NAME}"]="${status}"
    log_message "INFO" "Installation status for ${SOFTWARE_NAME}: ${status}"
}

# Main procedure function
main() {
    log_message "INFO" "Starting installation of ${SOFTWARE_NAME}"
    
    if check_if_installed; then
        log_message "INFO" "${SOFTWARE_NAME} is already installed"
        update_status "SKIPPED"
        return 0
    fi

    check_dependencies
    prepare_installation
    
    if install_software; then
        post_install
        update_status "SUCCESS"
        log_message "INFO" "${SOFTWARE_NAME} installation completed successfully"
    else
        update_status "FAILED"
        log_message "ERROR" "Failed to install ${SOFTWARE_NAME}"
        echo "Failed to install ${SOFTWARE_NAME}!" >&2
        return 1
    fi
}

# Execute main function
main "$@" 
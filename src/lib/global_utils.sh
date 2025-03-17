#!/usr/bin/env bash

# =============================================================================
# Pimp My Ubuntu - Common Utilities
# =============================================================================
# Description: Common utility functions used across installation procedures
# Author: Multitec-UA
# Repository: https://github.com/Multitec-UA/pimp_my_ubuntu
# License: MIT
# =============================================================================
# Debug flag - set to true to enable debug messages
readonly DEBUG=${DEBUG:-true}


# Ensure this script is sourced, not executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script should be sourced, not executed directly"
    exit 1
fi

readonly LOG_DIR="/var/log/pimp_my_ubuntu"
readonly LOG_FILE="${LOG_DIR}/install.log"

# Get the real user's home directory (works with sudo)
if [[ -n "${SUDO_USER:-}" ]]; then
    REAL_USER="${SUDO_USER}"
    REAL_HOME=$(getent passwd "${SUDO_USER}" | cut -d: -f6)
else
    REAL_USER="${USER}"
    REAL_HOME="${HOME}"
fi




# Function to run commands as the real user
global_run_as_user() {
    sudo -u "${REAL_USER}" "$@"
}

# Function to ensure a directory exists and has correct ownership
global_ensure_dir() {
    local dir=$1
    mkdir -p "${dir}"
    chown "${REAL_USER}:${REAL_USER}" "${dir}"
}

# Print last lines of the log file
global_debug_echo() {
    if [[ "${DEBUG}" == "true" ]]; then
        tail -n 1 "${LOG_FILE}"
    fi
}


# Log a message with timestamp
# Usage: log_message "INFO" "Starting installation"
global_log_message() {
    local level=$1
    local message=$2
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "[${timestamp}] [${level}] ${message}" >> "${LOG_FILE}"
    global_debug_echo
}

# Initialize logging
global_setup_logging() {
    global_ensure_dir "${LOG_DIR}"
    rm -f "${LOG_FILE}"
    touch "${LOG_FILE}"
    exec 3>&1 4>&2
    exec 1> >(tee -a "${LOG_FILE}") 2>&1
}


# Check for root privileges
global_check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root" >&2
        echo "Please run: sudo $0" >&2
        exit 1
    fi
}


# Check if software is already installed using multiple methods
# Usage: global_check_if_installed "software_name"
# Returns: 0 if installed, 1 if not installed
global_check_if_installed() {
    local software=$1
    local log_prefix="[CHECK] ${software}"
    
    # Log the check attempt
    global_log_message "INFO" "${log_prefix}: Checking if installed"
    
    # Method 1: Check if it's an APT package
    if dpkg -l "${software}" &> /dev/null; then
        global_log_message "INFO" "${log_prefix}: Found as APT package"
        return 0
    fi
    
    # Method 2: Try running the command with --version or -v (common patterns)
    if "${software}" --version &> /dev/null || "${software}" -v &> /dev/null; then
        global_log_message "INFO" "${log_prefix}: Responds to --version or -v flag"
        return 0
    fi
    
    # Method 3: Check if executable exists in PATH
    if command -v "${software}" &> /dev/null; then
        global_log_message "INFO" "${log_prefix}: Found in PATH"
        return 0
    fi
    
    # Method 4: Check if it's a snap package
    if snap list 2>/dev/null | grep -q "^${software} "; then
        global_log_message "INFO" "${log_prefix}: Found as Snap package"
        return 0
    fi
    
    # Method 5: Check if it's a flatpak
    if command -v flatpak &> /dev/null && flatpak list --app 2>/dev/null | grep -q "${software}"; then
        global_log_message "INFO" "${log_prefix}: Found as Flatpak"
        return 0
    fi
    
    # Method 6: Check common installation directories
    #for dir in "/usr/bin" "/usr/local/bin" "/opt/${software}" "/usr/share/${software}"; do
    #    if [ -d "${dir}" ] || [ -f "${dir}/${software}" ] || [ -f "${dir}" ]; then
    #        global_log_message "INFO" "${log_prefix}: Found in ${dir}"
    #        return 0
    #    fi
    #done
    
    # Method 7: Check systemd services
    if systemctl list-unit-files --type=service 2>/dev/null | grep -q "${software}.service"; then
        global_log_message "INFO" "${log_prefix}: Found as systemd service"
        return 0
    fi
    
    # Method 8: Check desktop entries
    if [ -f "/usr/share/applications/${software}.desktop" ] || \
       [ -f "$HOME/.local/share/applications/${software}.desktop" ]; then
        global_log_message "INFO" "${log_prefix}: Found desktop entry"
        return 0
    fi
    
    # If we made it here, the software was not found
    global_log_message "INFO" "${log_prefix}: Not found"
    return 1
}


# Install one or more apt packages and verify installation
# Usage: global_install_apt_package "package1" "package2" ...
# Returns: 0 if all packages successfully installed, 1 if any installation failed
global_install_apt_package() {
    local packages=("$@")
    local max_attempts=3
    local failed_packages=()
    
    for package in "${packages[@]}"; do
        local attempt=1
        local installed=false
        
        while [ $attempt -le $max_attempts ] && [ "$installed" = false ]; do
            global_log_message "INFO" "Installing ${package} (attempt ${attempt}/${max_attempts})"
            
            # Try to install the package
            if apt-get install -y "${package}"; then
                # Verify installation
                if global_check_if_installed "${package}"; then
                    global_log_message "INFO" "Successfully installed ${package}"
                    installed=true
                    break
                else
                    global_log_message "WARNING" "Package ${package} was installed but verification failed"
                fi
            else
                global_log_message "ERROR" "Failed to install ${package} on attempt ${attempt}"
            fi
            
            # Increment attempt counter
            ((attempt++))
            
            # Wait a bit before retrying (increasing delay with each attempt)
            if [ $attempt -le $max_attempts ]; then
                sleep $((attempt * 2))
            fi
        done
        
        if [ "$installed" = false ]; then
            global_log_message "ERROR" "Failed to install ${package} after ${max_attempts} attempts"
            failed_packages+=("${package}")
        fi
    done
    
    if [ ${#failed_packages[@]} -gt 0 ]; then
        global_log_message "ERROR" "Failed to install packages: ${failed_packages[*]}"
        return 1
    fi
    
    return 0
}

#--------------------------

# Add an APT repository safely
# Usage: add_apt_repository "ppa:user/repo-name"
global_add_apt_repository() {
    local repo=$1
    if ! grep -q "^deb.*${repo}" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
        add-apt-repository -y "$repo"
        apt-get update
    fi
}

# Download a file with progress
# Usage: download_file "https://example.com/file.tar.gz" "/tmp/file.tar.gz"
global_download_file() {
    local url=$1
    local output=$2
    wget --progress=bar:force -O "$output" "$url" 2>&1
}

# Check if running inside a terminal
# Usage: if is_terminal; then echo "Running in terminal"; fi
global_is_terminal() {
    [ -t 0 ]
}


# Create a backup of a file
# Usage: backup_file "/etc/example.conf"
global_backup_file() {
    local file=$1
    local backup="${file}.bak.$(date +%Y%m%d_%H%M%S)"
    
    if [[ -f "$file" ]]; then
        cp "$file" "$backup"
        global_log_message "INFO" "Created backup of ${file} at ${backup}"
    fi
}

# Check system requirements
# Usage: check_system_requirements "20.04"
global_check_system_requirements() {
    local required_version=$1
    local current_version
    
    current_version=$(lsb_release -rs)
    if [[ "${current_version}" != "${required_version}" ]]; then
        global_log_message "ERROR" "Unsupported Ubuntu version: ${current_version}. Required: ${required_version}"
        return 1
    fi
    return 0
}

# Clean up temporary files
# Usage: cleanup "/tmp/installation-files"
global_cleanup() {
    local dir=$1
    if [[ -d "$dir" ]]; then
        rm -rf "$dir"
        global_log_message "INFO" "Cleaned up temporary directory: ${dir}"
    fi
} 
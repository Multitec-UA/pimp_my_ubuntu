#!/usr/bin/env bash

# =============================================================================
# Pimp My Ubuntu - Common Utilities
# =============================================================================
# Description: Common utility functions used across installation procedures
# Author: Multitec-UA
# Repository: https://github.com/Multitec-UA/pimp_my_ubuntu
# License: MIT
# =============================================================================

# Global Variables --------------------------------

declare -A GLOBAL_INSTALLATION_STATUS
echo "THIS IS A COMMENT"

# Function to serialize and export the installation status array
# Usage: global_export_installation_status
global_export_installation_status() {
  local serialized=""
  for key in "${!GLOBAL_INSTALLATION_STATUS[@]}"; do
    # Create a string like "key1:value1;key2:value2"
    serialized+="${key}:${GLOBAL_INSTALLATION_STATUS[$key]};"
  done
  # Export as a normal environment variable
  export PMU_INSTALLATION_STATUS="$serialized"
  global_log_message "INFO" "Exported installation status: ${serialized}"
}

# Function to import and deserialize the installation status array
# Usage: global_import_installation_status
global_import_installation_status() {
  # Create a local associative array
  declare -A local_status
  
  if [[ -n "${PMU_INSTALLATION_STATUS:-}" ]]; then
    local IFS=";"
    for pair in $PMU_INSTALLATION_STATUS; do
      if [[ -n "$pair" ]]; then
        key="${pair%%:*}"
        value="${pair#*:}"
        local_status["$key"]="$value"
        global_log_message "INFO" "Imported status: ${key}=${value}"
      fi
    done
  else
    global_log_message "WARNING" "No installation status found in environment"
  fi
  
  # Make the array available globally
  GLOBAL_INSTALLATION_STATUS=()
  for key in "${!local_status[@]}"; do
    GLOBAL_INSTALLATION_STATUS["$key"]="${local_status[$key]}"
  done
}

# Ensure this script is sourced, not executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script should be sourced, not executed directly"
    exit 1
fi

readonly GLOBAL_LOG_DIR="/var/log/pimp_my_ubuntu"
readonly LOG_FILE="${GLOBAL_LOG_DIR}/install.log"

# Get the real user's home directory (works with sudo)
if [[ -n "${SUDO_USER:-}" ]]; then
    GLOBAL_REAL_USER="${SUDO_USER}"
    GLOBAL_REAL_HOME=$(getent passwd "${SUDO_USER}" | cut -d: -f6)
else
    GLOBAL_REAL_USER="${USER}"
    GLOBAL_REAL_HOME="${HOME}"
fi

readonly GLOBAL_DOWNLOAD_DIR="$GLOBAL_REAL_HOME/Documents/pimp_my_ubuntu"


# Gloabl functions --------------------------------

# Function to run commands as the real user
global_run_as_user() {
    sudo -u "${GLOBAL_REAL_USER}" "$@"
}


# Update installation status
global_set_status() {
    local software_command="$1"
    local status="$2"
    # Check if GLOBAL_INSTALLATION_STATUS exists before using it
    if declare -p GLOBAL_INSTALLATION_STATUS >/dev/null 2>&1; then
        GLOBAL_INSTALLATION_STATUS["${software_command}"]="${status}"
        global_log_message "INFO" "Installation status for ${software_command}: ${status}"
    else
        global_log_message "WARNING" "GLOBAL_INSTALLATION_STATUS array not available, status not updated"
    fi
}

# Get installation status for a software
# Usage: global_get_status "software_name"
global_get_status() {
    local software_command="$1"
    # Check if GLOBAL_INSTALLATION_STATUS exists before using it
    if declare -p GLOBAL_INSTALLATION_STATUS >/dev/null 2>&1; then
        echo "${GLOBAL_INSTALLATION_STATUS["${software_command}"]:-UNKNOWN}"
    else
        global_log_message "WARNING" "GLOBAL_INSTALLATION_STATUS array not available, returning UNKNOWN status"
        echo "UNKNOWN"
    fi
}


# Function to ensure a directory exists and has correct ownership
global_ensure_dir() {
    local dir=$1
    mkdir -p "${dir}"
    chown "${GLOBAL_REAL_USER}:${GLOBAL_REAL_USER}" "${dir}"
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
    global_ensure_dir "${GLOBAL_LOG_DIR}"
    local level=$1
    local message=$2
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "[${timestamp}] [${level}] ${message}" >> "${LOG_FILE}"
    global_debug_echo
}

# Initialize logging system for the application
# This function:
# 1. Ensures the log directory exists with proper permissions
# 2. Removes any existing log file to start fresh
# 3. Creates a new empty log file
# 4. Saves the original stdout (file descriptor 1) to fd 3
# 5. Saves the original stderr (file descriptor 2) to fd 4
# 6. Redirects stdout and stderr to both the terminal and the log file using tee
# Usage: global_setup_logging
global_setup_logging() {
    global_ensure_dir "${GLOBAL_LOG_DIR}"
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
    
    # Method 6: Check systemd services
    if systemctl list-unit-files --type=service 2>/dev/null | grep -q "${software}.service"; then
        global_log_message "INFO" "${log_prefix}: Found as systemd service"
        return 0
    fi
    
    # Method 7: Check desktop entries
    if [ -f "/usr/share/applications/${software}.desktop" ] || \
       [ -f "$GLOBAL_REAL_HOME/.local/share/applications/${software}.desktop" ]; then
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
        # First check if the package is already installed
        if global_check_if_installed "${package}"; then
            global_log_message "INFO" "Package ${package} is already installed, skipping"
            continue
        fi
        
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

# Function to download media files from repo
global_download_media() {
    local header="Accept: application/vnd.github.v3.raw"
    local file_path="${1:-}"
    local destination_dir="$GLOBAL_REAL_HOME/Documents/pimp_my_ubuntu"
    
    # Create destination directory if it doesn't exist
    mkdir -p "${GLOBAL_DOWNLOAD_DIR}"
    
    # Ensure the directory is owned by the real user
    chown "${GLOBAL_REAL_USER}:${GLOBAL_REAL_USER}" "${GLOBAL_DOWNLOAD_DIR}"
    
    if [[ -n "${file_path}" ]]; then
        global_log_message "INFO" "Downloading media file: ${file_path}"
        local output_file="${GLOBAL_DOWNLOAD_DIR}/$(basename "${file_path}")"

        # Use raw URL for GitHub content instead of API
        curl -H "${header}" -s "${_REPOSITORY_URL}/${file_path}" -o "${output_file}"
        local curl_status=$?
        
        # Ensure the downloaded file is owned by the real user
        chown "${GLOBAL_REAL_USER}:${GLOBAL_REAL_USER}" "${output_file}"
        
        return $curl_status
    else
        global_log_message "ERROR" "No media file specified to download"
        return 1
    fi
}

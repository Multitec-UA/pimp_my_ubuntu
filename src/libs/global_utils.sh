#!/usr/bin/env bash

# =============================================================================
# Pimp My Ubuntu - Common Utilities
# =============================================================================
# Description: Common utility functions used across installation procedures
# Author: Multitec-UA
# Repository: https://github.com/Multitec-UA/pimp_my_ubuntu
# License: MIT
# =============================================================================

readonly GLOBAL_UTILS_VERSION="1.1.4"

# Ensure this script is sourced, not executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script should be sourced, not executed directly"
    exit 1
fi

readonly GLOBAL_LOG_DIR="/var/log/pimp_my_ubuntu"
readonly GLOBAL_LOG_FILE="${GLOBAL_LOG_DIR}/install.log"

readonly GLOBAL_TEMP_PATH="/tmp/pimp_my_ubuntu"
readonly GLOBAL_STATUS_FILE="${GLOBAL_TEMP_PATH}/pmu_installation_status.tmp"

# Get the real user's home directory (works with sudo)
if [[ -n "${SUDO_USER:-}" ]]; then
    GLOBAL_REAL_USER="${SUDO_USER}"
    GLOBAL_REAL_HOME=$(getent passwd "${SUDO_USER}" | cut -d: -f6)
else
    GLOBAL_REAL_USER="${USER}"
    GLOBAL_REAL_HOME="${HOME}"
fi

GLOBAL_DOWNLOAD_DIR="$GLOBAL_REAL_HOME/Documents/pimp_my_ubuntu"

# Flag to track if logging has been initialized
GLOBAL_LOGGING_INITIALIZED=false
GLOBAL_STATUS_FILE_INITIALIZED=false

# Gloabl functions ------------------------------------------------------------

# Function to run commands as the real user
global_run_as_user() {
    sudo -u "${GLOBAL_REAL_USER}" "$@"
}


# Function to ensure a directory exists and has correct ownership
global_ensure_dir() {
    local dir=$1
    mkdir -p "${dir}"
    chown "${GLOBAL_REAL_USER}:${GLOBAL_REAL_USER}" "${dir}"
}

# Initialize logging system for the application
global_setup_logging() {
    if [[ "${GLOBAL_LOGGING_INITIALIZED}" == "false" ]] && [[ "${_SOFTWARE_COMMAND}" == "main-menu" ]]; then
        global_ensure_dir "${GLOBAL_LOG_DIR}"
        rm -f "${GLOBAL_LOG_FILE}"
        touch "${GLOBAL_LOG_FILE}"
        GLOBAL_LOGGING_INITIALIZED=true
    fi
}

# Log a message with timestamp and level
# Usage: global_log_message "INFO" "Starting installation"
global_log_message() {
    # Initialize logging if this is the first call form main menu
    global_setup_logging

    local level="${1:-INFO}"
    local message="${2:-}"
    local timestamp
    
    # Get current timestamp once
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    
    # Format log entry
    local log_entry="[${timestamp}] [${level}] ${message}"
    
    # Write to log file
    echo -e "${log_entry}" >> "${GLOBAL_LOG_FILE}"

    # Print to terminal based on debug level
    if [[ "${DEBUG}" == "true" ]] || [[ "${level}" != "DEBUG" ]]; then
        echo -e "${log_entry}"
    fi
}


# Check for root privileges
global_check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root" >&2
        echo "Please run: sudo $0" >&2
        exit 1
    fi
}

global_declare_installation_status() {
    if ! declare -p GLOBAL_INSTALLATION_STATUS >/dev/null 2>&1; then
        declare -gA GLOBAL_INSTALLATION_STATUS
        global_log_message "DEBUG" "GLOBAL_INSTALLATION_STATUS declared as global associative array"
    fi
}


# Initialize logging system for the application
global_setup_installation_status() {
    # Declare a associative array if it not exist yet
    global_declare_installation_status

    # Initialize the status file if it not initialized yet and is main-menu
    if [[ "${GLOBAL_STATUS_FILE_INITIALIZED}" == "false" ]] && [[ "${_SOFTWARE_COMMAND}" == "main-menu" ]]; then
        global_ensure_dir "${GLOBAL_TEMP_PATH}"
        rm -f "${GLOBAL_STATUS_FILE}"
        touch "${GLOBAL_STATUS_FILE}"
        GLOBAL_STATUS_FILE_INITIALIZED=true
    fi
}

# Function to serialize and export the installation status array
# Usage: global_export_installation_status
global_export_installation_status() {
    local serialized=""

    global_setup_installation_status
    local temp_status_file="$GLOBAL_STATUS_FILE"
    
    # Debug existing array content
    global_log_message "DEBUG" "Exporting keys: ${!GLOBAL_INSTALLATION_STATUS[@]}"
    global_log_message "DEBUG" "Exporting values: ${GLOBAL_INSTALLATION_STATUS[@]}"
    
    for key in "${!GLOBAL_INSTALLATION_STATUS[@]}"; do
        local value="${GLOBAL_INSTALLATION_STATUS[$key]}"
        # Create a string like "key1:value1;key2:value2"
        serialized+="${key}:${value};"
        global_log_message "DEBUG" "Serializing: ${key}:${value}"
    done
    
    # Write to temporary file instead of environment variable
    echo "$serialized" > "$temp_status_file"
    
    # Ensure the file has appropriate permissions
    chmod 644 "$temp_status_file"
    
    # Verify serialized content
    global_log_message "DEBUG" "Serialized content: $(cat $temp_status_file)"
    global_log_message "DEBUG" "Exported installation status to file: ${temp_status_file}"
}

# Function to import and deserialize the installation status array
# Usage: global_import_installation_status
global_import_installation_status() {
    # Create a local associative array
    declare -A local_status
    
    # Ensure declare it as an associative array (-A) and ensure file exists
    global_setup_installation_status
    local temp_status_file="$GLOBAL_STATUS_FILE"
    
    if [[ -f "$temp_status_file" ]]; then
        local serialized=$(cat "$temp_status_file")
        
        local IFS=";"
        for pair in $serialized; do
        if [[ -n "$pair" ]]; then
            key="${pair%%:*}"
            value="${pair#*:}"
            local_status["$key"]="$value"
            global_log_message "DEBUG" "Imported status: ${key}=${value}"
        fi
        done
    else
        global_log_message "WARNING" "No installation status file found at ${temp_status_file}"
    fi
    

    
    # Clear existing array values
    for key in "${!GLOBAL_INSTALLATION_STATUS[@]}"; do
        unset GLOBAL_INSTALLATION_STATUS["$key"]
    done
    
    # Copy imported values to global array
    for key in "${!local_status[@]}"; do
        GLOBAL_INSTALLATION_STATUS["$key"]="${local_status[$key]}"
    done
    
    # DEBUG
    global_log_message "DEBUG" "GLOBAL_INSTALLATION_STATUS_KEYS after import: ${!GLOBAL_INSTALLATION_STATUS[@]}"
    global_log_message "DEBUG" "GLOBAL_INSTALLATION_STATUS after import: ${GLOBAL_INSTALLATION_STATUS[@]}"
}

# Function to get installation status for a command
# Ensure exsist variable and file, import existing values and return value
# Usage: global_get_installation_status "command_name"
global_get_installation_status() {
    local command=$1
    
    # Import existing values first
    global_import_installation_status
    
    # Use parameter expansion with default to avoid unbound variable error
    echo "${GLOBAL_INSTALLATION_STATUS[$command]:-}"
}

# Function to set installation status for a command
# Ensure exsist variable and file, import existing values and set value
# Usage: global_set_installation_status "command_name" "status"
global_set_installation_status() {
    local command=$1
    local status=$2
    global_declare_installation_status
    
    # Import existing values first
    global_import_installation_status
    
    GLOBAL_INSTALLATION_STATUS["$command"]="$status"
    global_log_message "DEBUG" "GLOBAL_INSTALLATION_STATUS set: [$command]=$status"
    global_export_installation_status
}

# Function to remove a command from the installation status array
# Usage: global_remove_installation_status "command_name"
global_unset_installation_status() {
    local command=$1
    unset GLOBAL_INSTALLATION_STATUS["$command"]
    global_export_installation_status
}

# Check if software is already installed using multiple methods
# Usage: global_check_if_installed "software_name"
# Returns: 0 if installed, 1 if not installed
global_check_if_installed() {
    local software=$1
    local log_prefix="[CHECK] ${software}"
    
    # Log the check attempt
    global_log_message "DEBUG" "${log_prefix}: Checking if installed"
    
    # Method 1: Check if it's an APT package
    if dpkg -l "${software}" &> /dev/null; then
        global_log_message "DEBUG" "${log_prefix}: Found as APT package"
        return 0
    fi
    
    # Method 2: Try running the command with --version or -v (common patterns)
    if "${software}" --version &> /dev/null || "${software}" -v &> /dev/null; then
        global_log_message "DEBUG" "${log_prefix}: Responds to --version or -v flag"
        return 0
    fi
    
    # Method 3: Check if executable exists in PATH
    if command -v "${software}" &> /dev/null; then
        global_log_message "DEBUG" "${log_prefix}: Found in PATH"
        return 0
    fi
    
    # Method 4: Check if it's a snap package
    if snap list 2>/dev/null | grep -q "^${software} "; then
        global_log_message "DEBUG" "${log_prefix}: Found as Snap package"
        return 0
    fi
    
    # Method 5: Check if it's a flatpak
    if command -v flatpak &> /dev/null && flatpak list --app 2>/dev/null | grep -q "${software}"; then
        global_log_message "DEBUG" "${log_prefix}: Found as Flatpak"
        return 0
    fi
    
    # Method 6: Check systemd services
    if systemctl list-unit-files --type=service 2>/dev/null | grep -q "${software}.service"; then
        global_log_message "DEBUG" "${log_prefix}: Found as systemd service"
        return 0
    fi
    
    # Method 7: Check desktop entries
    if [ -f "/usr/share/applications/${software}.desktop" ] || \
       [ -f "$GLOBAL_REAL_HOME/.local/share/applications/${software}.desktop" ]; then
        global_log_message "DEBUG" "${log_prefix}: Found desktop entry"
        return 0
    fi
    
    # If we made it here, the software was not found
    global_log_message "DEBUG" "${log_prefix}: Not found"
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

    global_log_message "DEBUG" "GLOBAL_DOWNLOAD_DIR-GLOBAL_UTILS: ${GLOBAL_DOWNLOAD_DIR}"
    if [[ -n "${file_path}" ]]; then
        global_log_message "INFO" "Downloading media file: ${file_path} to ${GLOBAL_DOWNLOAD_DIR}"
        local output_file="${GLOBAL_DOWNLOAD_DIR}/$(basename "${file_path}")"

        # Use raw URL for GitHub content instead of API
        curl -fsSL "${_REPOSITORY_RAW_URL}/${file_path}" -o "${output_file}"  >>"${GLOBAL_LOG_FILE}" 2>&1
        local curl_status=$?
        
        # Ensure the downloaded file is owned by the real user
        chown "${GLOBAL_REAL_USER}:${GLOBAL_REAL_USER}" "${output_file}"  >>"${GLOBAL_LOG_FILE}" 2>&1
        
        return $curl_status
    else

        global_log_message "ERROR" "No media file specified to download"
        return 1
    fi
}

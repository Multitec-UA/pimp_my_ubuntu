#!/usr/bin/env bash

# =============================================================================
# Pimp My Ubuntu - Common Utilities
# =============================================================================
# Description: Common utility functions used across installation procedures
# Author: Multitec-UA
# Repository: https://github.com/Multitec-UA/pimp_my_ubuntu
# License: MIT
# =============================================================================

# Exit immediately if a command exits with a non-zero status.
# Treat unset variables as an error when substituting.
# Pipelines return the exit status of the last command that failed.
# set -e  # Be cautious with this, might uncomment later if appropriate
set -u
set -o pipefail

readonly GLOBAL_UTILS_VERSION="1.2.1"

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
    if [[ $? -ne 0 ]]; then
        global_log_message "ERROR" "Failed to create directory: ${dir}"
        return 1
    fi
    chown "${GLOBAL_REAL_USER}:${GLOBAL_REAL_USER}" "${dir}"
    if [[ $? -ne 0 ]]; then
        global_log_message "ERROR" "Failed to set ownership for directory: ${dir}"
        return 1
    fi
}

# Initialize logging system for the application
global_setup_logging() {
    # Don't log the start of this function to avoid bootstrapping issues
    if [[ "${GLOBAL_LOGGING_INITIALIZED}" == "false" ]] && \
       ( [[ ! -f "${GLOBAL_LOG_FILE}" ]] || [[ "${_SOFTWARE_COMMAND:-}" == "main-menu" ]] ); then
        global_ensure_dir "${GLOBAL_LOG_DIR}" || return 1 # Propagate error from ensure_dir
        rm -f "${GLOBAL_LOG_FILE}"
        if [[ $? -ne 0 ]]; then
             # Log potentially to stderr if logging isn't setup yet
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] Failed to remove old log file: ${GLOBAL_LOG_FILE}" >&2
            return 1 # Still attempt to proceed, but log error
        fi
        touch "${GLOBAL_LOG_FILE}"
        if [[ $? -ne 0 ]]; then
             # Log potentially to stderr if logging isn't setup yet
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] Failed to create log file: ${GLOBAL_LOG_FILE}" >&2
            return 1
        fi
        chown "${GLOBAL_REAL_USER}:${GLOBAL_REAL_USER}" "${GLOBAL_LOG_FILE}"
        if [[ $? -ne 0 ]]; then
             # Log potentially to stderr if logging isn't setup yet
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] Failed to set ownership for log file: ${GLOBAL_LOG_FILE}" >&2
            # Log failure but allow initialization to proceed if file was created
        fi
        GLOBAL_LOGGING_INITIALIZED=true
    fi
}

# Log a message with timestamp and level
# Usage: global_log_message "INFO" "Starting installation"
global_log_message() {
    # No start log here to avoid infinite recursion
    
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

    # Print to terminal based on level
    if [[ "${level}" == "INFO" ]]; then
        # Print to terminal in stdout
        echo -e "${log_entry}"
    elif [[ "${level}" != "DEBUG" ]]; then
        # Print to terminal in stderr
        echo -e "${log_entry}" >&2
    elif [[ "${DEBUG}" == "true" ]]; then
        # Print DEBUG to terminal in stderr
        echo -e "${log_entry}" >&2
    fi
    
    
    # Don't add end debug message to this function to avoid infinite recursion
}


# Check for root privileges
global_check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root" >&2
        echo "Please run: sudo $0" >&2
        exit 1
    fi
    global_log_message "INFO" "You can see debug logs in ${GLOBAL_LOG_FILE}"
}



# INSTALLATION STATUS FUNCTIONS ------------------------------------------------

# Initialize logging system for the application
global_create_proc_status_file() {
    global_log_message "DEBUG" "GF: --> global_create_proc_status_file"

    # Initialize the status file if it not initialized yet or is main-menu
    if [[ "${GLOBAL_STATUS_FILE_INITIALIZED}" == "false" ]]; then
        if [[ ! -f "${GLOBAL_STATUS_FILE}" ]] || [[ "${_SOFTWARE_COMMAND:-}" == "main-menu" ]]; then
            global_log_message "DEBUG" "GF: --> Creating status file"
            global_ensure_dir "${GLOBAL_TEMP_PATH}" || return 1 # Propagate error from ensure_dir
            rm -f "${GLOBAL_STATUS_FILE}"
            if [[ $? -ne 0 ]]; then
                global_log_message "ERROR" "Failed to remove old status file: ${GLOBAL_STATUS_FILE}"
                # Proceeding might be okay, but log the error
            fi
            touch "${GLOBAL_STATUS_FILE}"
            if [[ $? -ne 0 ]]; then
                global_log_message "ERROR" "Failed to create status file: ${GLOBAL_STATUS_FILE}"
                global_log_message "DEBUG" "GF: <-- global_create_proc_status_file"
                return 1
            fi
            # No chown needed here as ensure_dir handles parent, and touch respects umask
            GLOBAL_STATUS_FILE_INITIALIZED=true
        fi
    fi
    global_log_message "DEBUG" "GF: <-- global_create_proc_status_file"
}

# Function to serialize and store the installation status array
# Usage: global_write_proc_status_file "temp_status_array"
global_write_proc_status_file() {
    global_log_message "DEBUG" "GF: --> global_write_proc_status_file"
    local -n write_array_ref=${1:-}  # Use nameref to access the array indirectly
    local temp_status_file="$GLOBAL_STATUS_FILE"

    if [[ -z "${!write_array_ref[@]}" ]]; then  # Check if the referenced array is empty
        global_log_message "ERROR" "Procedure or status is empty"
        global_log_message "DEBUG" "GF: <-- global_write_proc_status_file"
        return 1
    fi

    # Ensure procedure status file exists
    global_create_proc_status_file || return 1 # Ensure file/dir exists before writing
    
    # Serialize the installation status array
    local serialized=""
    for key in "${!write_array_ref[@]}"; do  # Iterate over the keys of the referenced array
        local value="${write_array_ref[$key]}"  # Access values using the nameref
        # Create a string like "key1:value1;key2:value2"
        serialized+="${key}:${value};"
    done
    
    # Write serialized data to the status file
    echo "$serialized" > "$GLOBAL_STATUS_FILE"
    if [[ $? -ne 0 ]]; then
        global_log_message "ERROR" "Failed to write to status file: ${GLOBAL_STATUS_FILE}"
        global_log_message "DEBUG" "GF: <-- global_write_proc_status_file"
        return 1
    fi
    
    global_log_message "DEBUG" "GF: <-- global_write_proc_status_file"
}

# Function deserialize the installation status array from file
# declare -A result_array_read
# Usage: global_read_proc_status_file "temp_status_array"
global_read_proc_status_file() {
    global_log_message "DEBUG" "GF: --> global_read_proc_status_file"
    # Use nameref to access the array indirectly, using a different local name
    local -n read_array_ref=${1:-}
    
    if [[ -f "$GLOBAL_STATUS_FILE" ]]; then
        # Read the serialized data from the status file
        local serialized=$(cat "$GLOBAL_STATUS_FILE")
        # Set the field separator to semicolon for parsing the key-value pairs
        local IFS=";"
        # Iterate through each key-value pair in the serialized string
        for pair in $serialized; do
            # Only process non-empty pairs
            if [[ -n "$pair" ]]; then
                # Extract the key (everything before the first colon)
                key="${pair%%:*}"
                # Extract the value (everything after the first colon)
                value="${pair#*:}"
                # Store the key-value pair in the temporary associative array
                read_array_ref["$key"]="$value"
            fi
        done
    else
        global_log_message "WARNING" "No installation status file found at ${GLOBAL_STATUS_FILE}"
    fi
 
    global_log_message "DEBUG" "GF: <-- global_read_proc_status_file"
}

# Function to get installation status of specific procedure
# Usage: global_get_proc_status "procedure_name"
global_get_proc_status() {
    global_log_message "DEBUG" "GF: --> global_get_proc_status"
    local procedure=$1
    declare -A _temp_status_array_ref
    # Get procedure status from file
    global_read_proc_status_file "_temp_status_array_ref"
    
    global_log_message "DEBUG" "GF: <-- global_get_proc_status"
    # Use parameter expansion with default to avoid unbound variable error
    echo "${_temp_status_array_ref[$procedure]:-}"
}

# Function to set installation status of specific procedure
# Usage: global_set_proc_status "procedure_name" "status"
global_set_proc_status() {
    global_log_message "DEBUG" "GF: --> global_set_proc_status"
    local procedure=$1
    local status=$2

    if [[ -z "${procedure:-}" ]] || [[ -z "${status:-}" ]]; then
        global_log_message "ERROR" "Procedure or status is empty"
        global_log_message "DEBUG" "GF: <-- global_set_proc_status"
        return 1
    fi
    #Create the status file if it doesn't exist
    global_create_proc_status_file
    
    # Get procedure stored status from file
    # Declare a local associative array and pass its name to global_read_proc_status_file
    declare -A temp_status_array
    global_read_proc_status_file "temp_status_array"
    
    # Set the status of the procedure
    temp_status_array["$procedure"]="$status"

    # Write the status to the file
    global_write_proc_status_file "temp_status_array"

    global_log_message "DEBUG" "GF: <-- global_set_proc_status"
    return 0
}

# Function to remove a procedure from the installation status array
# Usage: global_unset_proc_status "procedure_name"
global_unset_proc_status() {
    global_log_message "DEBUG" "GF: --> global_unset_proc_status"
    local procedure=$1

    # Get procedure status from file
    # Declare a local associative array and pass its name to global_read_proc_status_file
    declare -A _unset_temp_status_array
    global_read_proc_status_file "_unset_temp_status_array"
    
    unset _unset_temp_status_array["$procedure"]
    global_write_proc_status_file "_unset_temp_status_array"

    global_log_message "DEBUG" "GF: <-- global_unset_proc_status"
    return 0
}

# END INSTALLATION STATUS FUNCTIONS ------------------------------------------------


# Check if software is already installed using multiple methods
# Usage: global_check_if_installed "software_name"
# Returns: 0 if installed, 1 if not installed
global_check_if_installed() {
    global_log_message "DEBUG" "GF: --> global_check_if_installed"
    local software=$1
    local log_prefix="[CHECK] ${software}"
    
    # Log the check attempt
    global_log_message "DEBUG" "${log_prefix}: Checking if installed"
    
    # Method 1: Check if it's an APT package
    if dpkg -l "${software}" &> /dev/null; then
        global_log_message "DEBUG" "${log_prefix}: Found as APT package"
        global_log_message "DEBUG" "GF: <-- global_check_if_installed"
        return 0
    fi
    
    # Method 2: Try running the command with --version or -v (common patterns)
    if "${software}" --version &> /dev/null || "${software}" -v &> /dev/null; then
        global_log_message "DEBUG" "${log_prefix}: Responds to --version or -v flag"
        global_log_message "DEBUG" "GF: <-- global_check_if_installed"
        return 0
    fi
    
    # Method 3: Check if executable exists in PATH
    if command -v "${software}" &> /dev/null; then
        global_log_message "DEBUG" "${log_prefix}: Found in PATH"
        global_log_message "DEBUG" "GF: <-- global_check_if_installed"
        return 0
    fi
    
    # Method 4: Check if it's a snap package
    if snap list 2>/dev/null | grep -q "^${software} "; then
        global_log_message "DEBUG" "${log_prefix}: Found as Snap package"
        global_log_message "DEBUG" "GF: <-- global_check_if_installed"
        return 0
    fi
    
    # Method 5: Check if it's a flatpak
    if command -v flatpak &> /dev/null && flatpak list --app 2>/dev/null | grep -q "${software}"; then
        global_log_message "DEBUG" "${log_prefix}: Found as Flatpak"
        global_log_message "DEBUG" "GF: <-- global_check_if_installed"
        return 0
    fi
    
    # Method 6: Check systemd services
    if systemctl list-unit-files --type=service 2>/dev/null | grep -q "${software}.service"; then
        global_log_message "DEBUG" "${log_prefix}: Found as systemd service"
        global_log_message "DEBUG" "GF: <-- global_check_if_installed"
        return 0
    fi
    
    # Method 7: Check desktop entries
    if [ -f "/usr/share/applications/${software}.desktop" ] || \
       [ -f "$GLOBAL_REAL_HOME/.local/share/applications/${software}.desktop" ]; then
        global_log_message "DEBUG" "${log_prefix}: Found desktop entry"
        global_log_message "DEBUG" "GF: <-- global_check_if_installed"
        return 0
    fi
    
    # If we made it here, the software was not found
    global_log_message "DEBUG" "${log_prefix}: Not found"
    global_log_message "DEBUG" "GF: <-- global_check_if_installed"
    return 1
}


# Install one or more apt packages and verify installation
# Usage: global_install_apt_package "package1" "package2" ...
# Returns: 0 if all packages successfully installed, 1 if any installation failed
global_install_apt_package() {
    global_log_message "DEBUG" "GF: --> global_install_apt_package"
    local packages=("$@")
    local max_attempts=3
    local failed_packages=()
    
    for package in "${packages[@]}"; do
        # First check if the package is already installed
        #if global_check_if_installed "${package}"; then
        #    global_log_message "INFO" "Package ${package} is already installed, skipping"
        #    continue
        #fi
        
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
        global_log_message "DEBUG" "GF: <-- global_install_apt_package"
        return 1
    fi
    
    global_log_message "DEBUG" "GF: <-- global_install_apt_package"
    return 0
}

# Function to download media files from repo
global_download_media() {
    global_log_message "DEBUG" "GF: --> global_download_media"
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
        # Log curl errors to the main log file as well as stderr
        if ! curl -fsSL "${_REPOSITORY_RAW_URL}/${file_path}" -o "${output_file}" >>"${GLOBAL_LOG_FILE}" 2>&1; then
             local curl_status=$?
             global_log_message "ERROR" "curl failed with status ${curl_status} downloading ${file_path}"
             global_log_message "DEBUG" "GF: <-- global_download_media"
             return $curl_status
        fi

        # Ensure the downloaded file is owned by the real user
        if ! chown "${GLOBAL_REAL_USER}:${GLOBAL_REAL_USER}" "${output_file}" >>"${GLOBAL_LOG_FILE}" 2>&1; then
             global_log_message "WARNING" "Failed to set ownership for downloaded file: ${output_file}"
             # Continue even if chown fails, but log warning
        fi

        global_log_message "DEBUG" "GF: <-- global_download_media"
        return 0 # Explicitly return 0 on success
    else

        global_log_message "ERROR" "No media file specified to download"
        global_log_message "DEBUG" "GF: <-- global_download_media"
        return 1
    fi
}

# Function to check file size and existence
# Usage: global_check_file_size "file_path"
# Returns: 0 if file exists and is >= 50 bytes, 1 otherwise
global_check_file_size() {
    global_log_message "DEBUG" "GF: --> global_check_file_size"
    local file_path="${1:-}"
    
    if [[ -z "${file_path}" ]]; then
        global_log_message "ERROR" "No file path specified"
        global_log_message "DEBUG" "GF: <-- global_check_file_size"
        return 1
    fi
    
    if [[ ! -f "${file_path}" ]]; then
        global_log_message "ERROR" "File does not exist: ${file_path}"
        global_log_message "DEBUG" "GF: <-- global_check_file_size"
        return 1
    fi
    
    local file_size=$(stat -c %s "${file_path}" 2>/dev/null)
    if [[ $? -ne 0 ]]; then
        global_log_message "ERROR" "Failed to get file size for: ${file_path}"
        global_log_message "DEBUG" "GF: <-- global_check_file_size"
        return 1
    fi
    
    if [[ ${file_size} -lt 1048576 ]]; then
        global_log_message "ERROR" "File size is less than 1 megabyte: ${file_path} (${file_size} bytes)"
        global_log_message "DEBUG" "GF: <-- global_check_file_size"
        return 1
    fi
    
    global_log_message "DEBUG" "File size check passed: ${file_path} (${file_size} bytes)"
    global_log_message "DEBUG" "GF: <-- global_check_file_size"
    return 0
}


global_press_any_key() {
    global_log_message "DEBUG" "GF: --> global_press_any_key"
    local timeout
    if [[ "${DEBUG}" == "true" ]]; then
        timeout=600
    else
        timeout=10
    fi
    
    local message="Press any key to continue or wait ${timeout} seconds... "
    echo # Add a newline before the prompt for better spacing

    # Use read with timeout, prompt, single char, silent, raw
    # If read returns 0, a key was pressed within the timeout
    # If read returns non-zero (> 128 for timeout), the timeout occurred
    if read -t $timeout -n 1 -s -r -p "$message"; then
        echo # Key was pressed, print a newline after the prompt
        global_log_message "DEBUG" "Key pressed, continuing."
    else
        # Timeout occurred
        echo # Print a newline to move past the prompt
        echo "Timeout reached, continuing automatically."
        global_log_message "DEBUG" "Timeout reached (${timeout}s), continuing automatically."
    fi
    global_log_message "DEBUG" "GF: <-- global_press_any_key"
}

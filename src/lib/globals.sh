#!/usr/bin/env bash

# =============================================================================
# Pimp My Ubuntu - Global Variables and Settings
# =============================================================================
# Description: Common variables and settings used across all scripts
# Author: Multitec-UA
# Repository: https://github.com/Multitec-UA/pimp_my_ubuntu
# License: MIT
# =============================================================================

# Ensure this script is sourced, not executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script should be sourced, not executed directly"
    exit 1
fi


# Global paths
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly LOG_DIR="/var/log/pimp_my_ubuntu"
readonly LOG_FILE="${LOG_DIR}/install.log"
readonly PROCEDURES_FILE="${LOG_DIR}/procedures.json"



# Get the real user's home directory (works with sudo)
if [[ -n "${SUDO_USER:-}" ]]; then
    REAL_USER="${SUDO_USER}"
    REAL_HOME=$(getent passwd "${SUDO_USER}" | cut -d: -f6)
else
    REAL_USER="${USER}"
    REAL_HOME="${HOME}"
fi


# User specific paths
readonly USER_LOCAL_DIR="${REAL_HOME}/.local"
readonly USER_CONFIG_DIR="${REAL_HOME}/.config"
readonly APPLICATIONS_DIR="${REAL_HOME}/Applications"


# Shell configuration files
readonly SHELL_RC_FILES=(
    "${REAL_HOME}/.bashrc"
    "${REAL_HOME}/.zshrc"
)

# Global associative array for installation status
declare -A INSTALLATION_STATUS

# Function to run commands as the real user
_run_as_user() {
    sudo -u "${REAL_USER}" "$@"
}

# Function to ensure a directory exists and has correct ownership
_ensure_dir() {
    local dir=$1
    mkdir -p "${dir}"
    chown "${REAL_USER}:${REAL_USER}" "${dir}"
}

# Log a message with timestamp
# Usage: log_message "INFO" "Starting installation"
_log_message() {
    local level=$1
    local message=$2
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "[${timestamp}] [${level}] ${message}" >> "${LOG_FILE}"
}

# Check for root privileges
_check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root" >&2
        echo "Please run: sudo $0" >&2
        exit 1
    fi
}

# Initialize logging

_setup_logging() {
    _ensure_dir "${LOG_DIR}"
    rm -f "${LOG_FILE}"
    touch "${LOG_FILE}"
    exec 3>&1 4>&2
    exec 1> >(tee -a "${LOG_FILE}") 2>&1
}

# Set up procedures information
# Read all procedures from the repository and save them to a JSON file
_set_procedures_info() {
    _log_message "INFO" "Setting up procedures information"
    
    # Ensure directory exists and clean up old file
    _ensure_dir "${LOG_DIR}"
    rm -f "${PROCEDURES_FILE}"
    touch "${PROCEDURES_FILE}"
    
    # Fetch procedures from GitHub repository
    local procedures_json
    procedures_json=$(curl -s -H "Accept: application/vnd.github.v3+json" "${REPOSITORY_PROCEDURES_URL}")
    
    # Initialize JSON array
    echo "[" > "${PROCEDURES_FILE}"
    
    # Process each procedure
    local first=true
    echo "${procedures_json}" | jq -c '.[]' | while read -r procedure; do
        # Skip if not a file or not a .sh file
        local type=$(echo "${procedure}" | jq -r '.type')
        local name=$(echo "${procedure}" | jq -r '.name')
        
        if [[ "${type}" != "file" || ! "${name}" =~ \.sh$ ]]; then
            continue
        fi
        
        # Extract procedure name without extension
        local proc_name="${name%.sh}"
        
        # Skip template.sh
        if [[ "${proc_name}" == "template" ]]; then
            continue
        fi
        
        # Add comma for all but the first entry
        if [[ "${first}" == "true" ]]; then
            first=false
        else
            echo "," >> "${PROCEDURES_FILE}"
        fi
        
        # Add procedure entry to JSON
        cat << EOF >> "${PROCEDURES_FILE}"
{
  "name": "${proc_name}",
  "selected": false,
  "status": "PENDING"
}
EOF
    done
    
    # Close JSON array
    echo "]" >> "${PROCEDURES_FILE}"
    
    _log_message "INFO" "Procedures information saved to ${PROCEDURES_FILE}"
}

# Get procedure names from the procedures JSON file
# Returns a space-separated list of procedure names
_get_procedure_names() {
    _log_message "INFO" "Getting procedure names from ${PROCEDURES_FILE}"
    
    # Check if procedures file exists
    if [[ ! -f "${PROCEDURES_FILE}" ]]; then
        _log_message "ERROR" "Procedures file not found: ${PROCEDURES_FILE}"
        return 1
    fi
    
    # Use jq to extract the name field from each procedure in the JSON array
    local names
    names=$(jq -r '.[].name' "${PROCEDURES_FILE}")
    
    # Return the names as a space-separated list
    echo "${names}"
    
    _log_message "INFO" "Retrieved procedure names successfully"
}

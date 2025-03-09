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
readonly G_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly G_LOG_DIR="/var/log/pimp_my_ubuntu"
readonly G_LOG_FILE="${G_LOG_DIR}/install.log"
readonly G_PROCEDURES_FILE="${G_LOG_DIR}/procedures.json"



# Get the real user's home directory (works with sudo)
if [[ -n "${SUDO_USER:-}" ]]; then
    G_REAL_USER="${SUDO_USER}"
    G_REAL_HOME=$(getent passwd "${SUDO_USER}" | cut -d: -f6)
else
    G_REAL_USER="${USER}"
    G_REAL_HOME="${HOME}"
fi


# User specific paths
readonly G_USER_LOCAL_DIR="${G_REAL_HOME}/.local"
readonly G_USER_CONFIG_DIR="${G_REAL_HOME}/.config"
readonly G_APPLICATIONS_DIR="${G_REAL_HOME}/Applications"


# Shell configuration files
readonly G_SHELL_RC_FILES=(
    "${G_REAL_HOME}/.bashrc"
    "${G_REAL_HOME}/.zshrc"
)

# Global associative array for installation status
declare -A G_INSTALLATION_STATUS

# Function to run commands as the real user
global_run_as_user() {
    sudo -u "${G_REAL_USER}" "$@"
}

# Function to ensure a directory exists and has correct ownership
global_ensure_dir() {
    local dir=$1
    mkdir -p "${dir}"
    chown "${G_REAL_USER}:${G_REAL_USER}" "${dir}"
}

# Log a message with timestamp
# Usage: log_message "INFO" "Starting installation"
global_log_message() {
    local level=$1
    local message=$2
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "[${timestamp}] [${level}] ${message}" >> "${G_LOG_FILE}"
}

# Check for root privileges
global_check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root" >&2
        echo "Please run: sudo $0" >&2
        exit 1
    fi
}

# Initialize logging

global_setup_logging() {
    global_ensure_dir "${G_LOG_DIR}"
    rm -f "${G_LOG_FILE}"
    touch "${G_LOG_FILE}"
    exec 3>&1 4>&2
    exec 1> >(tee -a "${G_LOG_FILE}") 2>&1
}

# Set up procedures information
# Read all procedures from the repository and save them to a JSON file
global_set_procedures_info() {
    global_log_message "INFO" "Setting up procedures information"
    
    # Ensure directory exists and clean up old file
    global_ensure_dir "${G_LOG_DIR}"
    rm -f "${G_PROCEDURES_FILE}"
    touch "${G_PROCEDURES_FILE}"
    
    # Fetch procedures from GitHub repository
    local procedures_json
    procedures_json=$(curl -s -H "Accept: application/vnd.github.v3+json" "${REPOSITORY_PROCEDURES_URL}")
    
    # Initialize JSON array
    echo "[" > "${G_PROCEDURES_FILE}"
    
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
            echo "," >> "${G_PROCEDURES_FILE}"
        fi
        
        # Add procedure entry to JSON
        cat << EOF >> "${G_PROCEDURES_FILE}"
{
  "name": "${proc_name}",
  "selected": false,
  "status": "PENDING"
}
EOF
    done
    
    # Close JSON array
    echo "]" >> "${G_PROCEDURES_FILE}"
    
    global_log_message "INFO" "Procedures information saved to ${G_PROCEDURES_FILE}"
}

# Get procedure names from the procedures JSON file
# Returns a space-separated list of procedure names
global_get_procedure_names() {
    global_log_message "INFO" "Getting procedure names from ${G_PROCEDURES_FILE}"
    
    # Check if procedures file exists
    if [[ ! -f "${G_PROCEDURES_FILE}" ]]; then
        global_log_message "ERROR" "Procedures file not found: ${G_PROCEDURES_FILE}"
        return 1
    fi
    
    # Use jq to extract the name field from each procedure in the JSON array
    local names
    names=$(jq -r '.[].name' "${G_PROCEDURES_FILE}")
    
    # Return the names as a space-separated list
    echo "${names}"
    
    global_log_message "INFO" "Retrieved procedure names successfully"
}

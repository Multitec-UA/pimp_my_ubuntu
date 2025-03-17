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
readonly M_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly M_LOG_DIR="/var/log/pimp_my_ubuntu"
readonly M_LOG_FILE="${M_LOG_DIR}/install.log"
readonly M_PROCEDURES_FILE="${M_LOG_DIR}/procedures.json"



# Get the real user's home directory (works with sudo)
if [[ -n "${SUDO_USER:-}" ]]; then
    M_REAL_USER="${SUDO_USER}"
    M_REAL_HOME=$(getent passwd "${SUDO_USER}" | cut -d: -f6)
else
    M_REAL_USER="${USER}"
    M_REAL_HOME="${HOME}"
fi


# User specific paths
readonly M_USER_LOCAL_DIR="${M_REAL_HOME}/.local"
readonly M_USER_CONFIG_DIR="${M_REAL_HOME}/.config"
readonly M_APPLICATIONS_DIR="${M_REAL_HOME}/Applications"


# Shell configuration files
readonly M_SHELL_RC_FILES=(
    "${M_REAL_HOME}/.bashrc"
    "${M_REAL_HOME}/.zshrc"
)

# Global associative array for installation status
declare -A M_INSTALLATION_STATUS


# Set up procedures information
# Read all procedures from the repository and save them to a JSON file
main_set_procedures_info() {
    global_log_message "INFO" "Setting up procedures information"
    
    # Ensure directory exists and clean up old file
    global_ensure_dir "${M_LOG_DIR}"
    rm -f "${M_PROCEDURES_FILE}"
    touch "${M_PROCEDURES_FILE}"
    
    # Fetch procedures from GitHub repository
    local procedures_json
    procedures_json=$(curl -s -H "Accept: application/vnd.github.v3+json" "${REPOSITORY_PROCEDURES_URL}")
    
    # Initialize JSON array
    echo "[" > "${M_PROCEDURES_FILE}"
    
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
            echo "," >> "${M_PROCEDURES_FILE}"
        fi
        
        # Add procedure entry to JSON
        cat << EOF >> "${M_PROCEDURES_FILE}"
{
  "name": "${proc_name}",
  "selected": false,
  "status": "PENDING"
}
EOF
    done
    
    # Close JSON array
    echo "]" >> "${M_PROCEDURES_FILE}"
    
    global_log_message "INFO" "Procedures information saved to ${M_PROCEDURES_FILE}"
}

# Get procedure names from the procedures JSON file
# Returns a space-separated list of procedure names
main_get_procedure_names() {
    global_log_message "INFO" "Getting procedure names from ${M_PROCEDURES_FILE}"
    
    # Check if procedures file exists
    if [[ ! -f "${M_PROCEDURES_FILE}" ]]; then
        global_log_message "ERROR" "Procedures file not found: ${M_PROCEDURES_FILE}"
        return 1
    fi
    
    # Use jq to extract the name field from each procedure in the JSON array
    local names
    names=$(jq -r '.[].name' "${M_PROCEDURES_FILE}")
    
    # Return the names as a space-separated list
    echo "${names}"
    
    main_log_message "INFO" "Retrieved procedure names successfully"
}

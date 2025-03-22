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




# Set up procedures information
# Read all procedures from the repository and save them to a JSON file
main_init_procedures_info() {
    global_log_message "INFO" "Setting up procedures information"
        
    # Fetch procedures from GitHub repository
    local procedures_json
    procedures_json=$(curl -s -H "Accept: application/vnd.github.v3+json" "${_REPOSITORY_URL}/${MAIN_PROCEDURES_PATH}")
    
    # Initialize GLOBAL_INSTALLATION_STATUS if not already declared
    if ! declare -p GLOBAL_INSTALLATION_STATUS >/dev/null 2>&1; then
        declare -A GLOBAL_INSTALLATION_STATUS
    fi
    
    # Export GLOBAL_INSTALLATION_STATUS to make it available to other scripts
    export GLOBAL_INSTALLATION_STATUS
    
    # Extract all names from the procedures JSON and set them as PENDING in GLOBAL_INSTALLATION_STATUS
    local names
    names=$(echo "${procedures_json}" | jq -r '.[].name')
    
    # Loop through each name and set it as PENDING in GLOBAL_INSTALLATION_STATUS
    while IFS= read -r name; do
        GLOBAL_INSTALLATION_STATUS["${name}"]="PENDING"
        global_log_message "INFO" "Added procedure '${name}' with status 'PENDING'"
    done <<< "${names}"
    
    global_log_message "INFO" "All procedures initialized with PENDING status"
    echo "${procedures_json}"
}

# Get procedure names from the procedures JSON file
# Returns a space-separated list of procedure names
main_get_procedure_names() {
    global_log_message "INFO" "Getting procedure names"
    
    # Use jq to extract the name field from each key in GLOBAL_INSTALLATION_STATUS
    local names=""
    
    # Check if GLOBAL_INSTALLATION_STATUS is declared
    if declare -p GLOBAL_INSTALLATION_STATUS >/dev/null 2>&1; then
        for key in "${!GLOBAL_INSTALLATION_STATUS[@]}"; do
            names+="${key} "
        done
        names="${names% }" # Remove trailing space
        
        # Return the names as a space-separated list
        echo "${names}"
        global_log_message "INFO" "Retrieved procedure names successfully"
    else
        global_log_message "ERROR" "GLOBAL_INSTALLATION_STATUS not initialized"
        return 1
    fi
}

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
readonly MAIN_PROCEDURES_PATH="/src/procedures"



# Set up procedures information
# Read all procedures from the repository and save them to a JSON file
main_init_procedures_info() {
    global_log_message "INFO" "Setting up procedures information"
        
    # Fetch procedures from GitHub repository
    local procedures_json
    procedures_json=$(curl -s -H "Accept: application/vnd.github.v3+json" "${_REPOSITORY_URL}/${MAIN_PROCEDURES_PATH}")
    echo "${procedures_json}"

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

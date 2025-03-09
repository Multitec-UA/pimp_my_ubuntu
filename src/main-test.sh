#!/usr/bin/env bash

# =============================================================================
# Pimp My Ubuntu - Main Installation Script
# =============================================================================
# Description: Automates the setup of a fresh Ubuntu 24.04 installation
# Author: Multitec-UA
# Repository: https://github.com/Multitec-UA/pimp_my_ubuntu
# License: MIT
# =============================================================================

# Strict mode
set -euo pipefail


REPOSITORY_URL="https://api.github.com/repos/Multitec-UA/pimp_my_ubuntu/contents"
REPOSITORY_LIB_URL="${REPOSITORY_URL}/src/lib"
REPOSITORY_PROCEDURES_URL="${REPOSITORY_URL}/src/procedures"


main() {
    source_dependencies
    _check_root
    _setup_logging

    _log_message "INFO" "Installing basic dependencies\n"
    install_basic_dependencies
    
    _log_message "INFO" "Setting up procedures information\n"
    set_procedures_info

    # Display welcome message
    dialog --title "Pimp My Ubuntu" --backtitle "Installation Script" \
           --msgbox "Welcome to Pimp My Ubuntu!\n\nThis script will help you set up your Ubuntu 24.04 system with your preferred software and configurations." 10 60
    
    # TODO: show_procedure_selector_menu

    log_message "INFO" "\nStarting Pimp My Ubuntu installation script\n"
}


source_dependencies() {
    # Source global variables and functions
    source <(curl -H "Accept: application/vnd.github.v3.raw" -s "${REPOSITORY_LIB_URL}/globals.sh")
}


# Install basic dependencies
install_basic_dependencies() {
    apt-get update
    apt-get install -y curl git dialog jq
}

# Set up procedures information
# Read all procedures from the repository and save them to a JSON file
set_procedures_info() {
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



main "$@"
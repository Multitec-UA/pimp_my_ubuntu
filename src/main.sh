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

# Source global variables and functions
# shellcheck source=./lib/globals.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/globals.sh"

# Source dependencies
source_dependency() {
    local dep_name="$1"
    local local_path="${DEPENDENCIES_DIR}/${dep_name}"
    local github_path="${GITHUB_RAW_URL}/src/dependencies/${dep_name}"

    if [[ -f "${local_path}" ]]; then
        source "${local_path}"
    else
        if ! curl -sSf "${github_path}" -o "${local_path}"; then
            log_message "ERROR" "Failed to download dependency ${dep_name}"
            return 1
        fi
        source "${local_path}"
    fi
}

# Check for root privileges
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root" >&2
        echo "Please run: sudo $0" >&2
        exit 1
    fi
}

# Initialize logging
setup_logging() {
    ensure_dir "${GLOBAL_LOG_DIR}"
    touch "${LOG_FILE}"
    exec 3>&1 4>&2
    exec 1> >(tee -a "${LOG_FILE}") 2>&1
}

# Install basic dependencies
install_basic_dependencies() {
    apt-get update
    apt-get install -y curl git dialog
}

# Load all procedures
load_procedures() {
    local procedures=()
    if [[ -d "${PROCEDURES_DIR}" ]]; then
        while IFS= read -r -d '' file; do
            procedures+=("${file}")
        done < <(find "${PROCEDURES_DIR}" -type f -name "*.sh" -print0)
    fi
    echo "${procedures[@]:-}"
}

# Display menu and get user selection
show_menu() {
    local procedures=("$@")
    local choices=()
    local cmd=(dialog --title "Pimp My Ubuntu" --backtitle "Software Selection" --separate-output --checklist "Select software to install:" 22 76 16)
    
    for proc in "${procedures[@]}"; do
        local name=$(basename "${proc}" .sh)
        local desc=""
        
        # Try to extract description from the file
        if grep -q "readonly SOFTWARE_DESCRIPTION=" "${proc}"; then
            desc=$(grep "readonly SOFTWARE_DESCRIPTION=" "${proc}" | cut -d'"' -f2)
        fi
        
        cmd+=("${name}" "${desc:-"No description available"}" off)
    done
    
    choices=$("${cmd[@]}" 2>&1 >/dev/tty)
    echo "${choices}"
}

# Initialize status for all selected software
initialize_status() {
    local selected=("$@")
    for selection in "${selected[@]}"; do
        GLOBAL_INSTALLATION_STATUS["${selection}"]="QUEUED"
    done
}

# Update status display
update_status_display() {
    local temp_file
    temp_file=$(mktemp)
    
    # Create content for dialog
    {
        echo "STATUS          SOFTWARE"
        echo "------          --------"
        for software in "${!GLOBAL_INSTALLATION_STATUS[@]}"; do
            local status="${GLOBAL_INSTALLATION_STATUS[$software]}"
            local status_display
            
            case "${status}" in
                "SUCCESS")   status_display="[ INSTALLED  ]" ;;
                "FAILED")    status_display="[   FAILED   ]" ;;
                "IN_PROGRESS") status_display="[ IN PROCESS ]" ;;
                "QUEUED")    status_display="[   QUEUED   ]" ;;
                "SKIPPED")   status_display="[  SKIPPED   ]" ;;
                *)           status_display="[  UNKNOWN   ]" ;;
            esac
            
            echo "${status_display}   ${software}"
        done
    } > "${temp_file}"
    
    # Display the status
    dialog --title "Installation Progress" --backtitle "Pimp My Ubuntu" \
           --begin 3 10 --tailboxbg "${temp_file}" 15 50 \
           --and-widget --begin 19 10 --msgbox "Press OK to continue" 5 30 \
           2>/dev/null || true
    
    rm -f "${temp_file}"
}

# Install a single software
install_software() {
    local selection=$1
    
    # Update status
    GLOBAL_INSTALLATION_STATUS["${selection}"]="IN_PROGRESS"
    update_status_display
    
    # Run the installation script
    log_message "INFO" "Starting installation of ${selection}"
    if bash "${PROCEDURES_DIR}/${selection}.sh"; then
        log_message "INFO" "Installation of ${selection} completed successfully"
    else
        log_message "ERROR" "Installation of ${selection} failed"
        GLOBAL_INSTALLATION_STATUS["${selection}"]="FAILED"
    fi
    
    # Update status display again
    update_status_display
}

# Main function
main() {
    check_root
    setup_logging
    install_basic_dependencies
    
    log_message "INFO" "Starting Pimp My Ubuntu installation script"
    
    # Display welcome message
    dialog --title "Pimp My Ubuntu" --backtitle "Installation Script" \
           --msgbox "Welcome to Pimp My Ubuntu!\n\nThis script will help you set up your Ubuntu 24.04 system with your preferred software and configurations." 10 60
    
    
    # Create required directories
    _ensure_dir "${PROCEDURES_DIR}"
    _ensure_dir "${DEPENDENCIES_DIR}"
    
    # Load and execute procedures based on user selection
    local procedures
    procedures=($(load_procedures))
    
    if [[ ${#procedures[@]} -eq 0 ]]; then
        dialog --title "Error" --backtitle "Pimp My Ubuntu" \
               --msgbox "No installation procedures found!" 8 40
        _log_message "ERROR" "No installation procedures found"
        exit 1
    fi
    
    # Get user selection
    local selected
    selected=($(show_menu "${procedures[@]}"))
    
    if [[ ${#selected[@]} -eq 0 ]]; then
        dialog --title "Cancelled" --backtitle "Pimp My Ubuntu" \
               --msgbox "No software selected. Installation cancelled." 8 40
        log_message "INFO" "No software selected. Installation cancelled."
        exit 0
    fi
    
    # Initialize status for all selected software
    initialize_status "${selected[@]}"
    
    # Show initial status
    update_status_display
    
    # Install each selected software
    for selection in "${selected[@]}"; do
        install_software "${selection}"
    done
    
    # Show final status
    dialog --title "Installation Complete" --backtitle "Pimp My Ubuntu" \
           --msgbox "Installation process completed!\n\nCheck ${LOG_FILE} for details." 10 50
    
    log_message "INFO" "Installation complete"
}

# Execute main function
main "$@" 
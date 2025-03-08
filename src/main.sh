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

# Global constants
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROCEDURES_DIR="${SCRIPT_DIR}/procedures"
readonly DEPENDENCIES_DIR="${SCRIPT_DIR}/dependencies"
readonly LOG_DIR="/var/log/pimp_my_ubuntu"
readonly LOG_FILE="${LOG_DIR}/install.log"
readonly GITHUB_RAW_URL="https://raw.githubusercontent.com/Multitec-UA/pimp_my_ubuntu/main"

# Global variables
declare -A INSTALLATION_STATUS

# Source dependencies
source_dependency() {
    local dep_name="$1"
    local local_path="${DEPENDENCIES_DIR}/${dep_name}"
    local github_path="${GITHUB_RAW_URL}/src/dependencies/${dep_name}"

    if [[ -f "${local_path}" ]]; then
        source "${local_path}"
    else
        if ! curl -sSf "${github_path}" -o "${local_path}"; then
            echo "Error: Failed to download dependency ${dep_name}" >&2
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
    mkdir -p "${LOG_DIR}"
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
    local cmd=(dialog --separate-output --checklist "Select software to install:" 22 76 16)
    
    for proc in "${procedures[@]}"; do
        local name=$(basename "${proc}" .sh)
        cmd+=("${name}" "" off)
    done
    
    choices=$("${cmd[@]}" 2>&1 >/dev/tty)
    echo "${choices}"
}

# Main function
main() {
    check_root
    setup_logging
    
    echo "Pimp My Ubuntu - Installation Script"
    echo "==================================="
    
    install_basic_dependencies
    
    # Create required directories
    mkdir -p "${PROCEDURES_DIR}"
    mkdir -p "${DEPENDENCIES_DIR}"
    
    # Load and execute procedures based on user selection
    local procedures
    procedures=($(load_procedures))
    
    if [[ ${#procedures[@]} -eq 0 ]]; then
        echo "No installation procedures found!"
        exit 1
    fi
    
    local selected
    selected=($(show_menu "${procedures[@]}"))
    
    for selection in "${selected[@]}"; do
        echo "Installing: ${selection}"
        bash "${PROCEDURES_DIR}/${selection}.sh"
    done
    
    echo "Installation complete! Check ${LOG_FILE} for details."
}

# Execute main function
main "$@" 
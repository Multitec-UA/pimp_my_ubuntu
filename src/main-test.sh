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


source_dependencies() {
    # Source global variables and functions
    source <(curl -H "Accept: application/vnd.github.v3.raw" \
    -s https://api.github.com/repos/Multitec-UA/pimp_my_ubuntu/contents/src/lib/globals.sh)
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
    ensure_dir "${LOG_DIR}"
    touch "${LOG_FILE}"
    exec 3>&1 4>&2
    exec 1> >(tee -a "${LOG_FILE}") 2>&1
}

# Install basic dependencies
install_basic_dependencies() {
    apt-get update
    apt-get install -y curl git dialog
}

main() {
    source_dependencies
    check_root
    setup_logging
    install_basic_dependencies
    


    log_message "INFO" "Starting Pimp My Ubuntu installation script"
}

main "$@"
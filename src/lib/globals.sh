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

# Get the real user's home directory (works with sudo)
if [[ -n "${SUDO_USER:-}" ]]; then
    REAL_USER="${SUDO_USER}"
    REAL_HOME=$(getent passwd "${SUDO_USER}" | cut -d: -f6)
else
    REAL_USER="${USER}"
    REAL_HOME="${HOME}"
fi

# Global paths
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly LIB_DIR="${SCRIPT_DIR}/lib"
readonly PROCEDURES_DIR="${SCRIPT_DIR}/procedures"
readonly DEPENDENCIES_DIR="${SCRIPT_DIR}/dependencies"
readonly LOG_DIR="/var/log/pimp_my_ubuntu"
readonly LOG_FILE="${LOG_DIR}/install.log"

# User specific paths
readonly USER_LOCAL_DIR="${REAL_HOME}/.local"
readonly USER_CONFIG_DIR="${REAL_HOME}/.config"
readonly APPLICATIONS_DIR="${REAL_HOME}/Applications"

# GitHub repository information
readonly GITHUB_RAW_URL="https://raw.githubusercontent.com/Multitec-UA/pimp_my_ubuntu/main"

# Shell configuration files
readonly SHELL_RC_FILES=(
    "${REAL_HOME}/.bashrc"
    "${REAL_HOME}/.zshrc"
)

# Global associative array for installation status
declare -A INSTALLATION_STATUS

# Common functions
log_message() {
    local level=$1
    local message=$2
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [${level}] ${message}" >> "${LOG_FILE}"
}

# Function to run commands as the real user
run_as_user() {
    sudo -u "${REAL_USER}" "$@"
}

# Function to ensure a directory exists and has correct ownership
ensure_dir() {
    local dir=$1
    mkdir -p "${dir}"
    chown "${REAL_USER}:${REAL_USER}" "${dir}"
} 
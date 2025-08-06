#!/usr/bin/env bash

# =============================================================================
# Pimp My Ubuntu - Spotify Installation Procedure
# =============================================================================
# Description: Installs the Spotify client for Linux
# Author: Multitec-UA
# Repository: https://github.com/Multitec-UA/pimp_my_ubuntu
# License: MIT
#
# COMMON INSTRUCTIONS:
# 1. Dont use echo. Use global_log_message instead.
# 2. Send all output to log file. command >>"${GLOBAL_LOG_FILE}" 2>&1
# =============================================================================

# Debug flag - set to true to enable debug messages
readonly DEBUG=${DEBUG:-false}
readonly LOCAL=${LOCAL:-false}

# Software-common constants
readonly _SOFTWARE_COMMAND="spotify"
readonly _SOFTWARE_DESCRIPTION="Spotify Client for Linux"
readonly _SOFTWARE_VERSION="1.0.0"
readonly _DEPENDENCIES=("curl" "gpg")
readonly _REPOSITORY_TAG="v0.1.0"
readonly _REPOSITORY_RAW_URL="https://raw.github.com/Multitec-UA/pimp_my_ubuntu/refs/tags/${_REPOSITORY_TAG}/"
readonly _LIBS_REMOTE_URL="${_REPOSITORY_RAW_URL}/src/libs/"

# Spotify-specific constants
readonly _SPOTIFY_GPG_URL="https://download.spotify.com/debian/pubkey_C85668DF69375001.gpg"
readonly _SPOTIFY_GPG_KEY_PATH="/etc/apt/trusted.gpg.d/spotify.gpg"
readonly _SPOTIFY_REPO_URL="https://repository.spotify.com"


# Main procedure function
main() {

    # Source global variables and functions
    _source_lib "global_utils.sh"
    
    global_check_root

    _step_init

    if [[ "$(global_get_proc_status "${_SOFTWARE_COMMAND}")" == "SKIPPED" ]]; then
        global_log_message "INFO" "${_SOFTWARE_COMMAND} is already installed"
        _step_post_install
        _step_cleanup
        return 0
    fi

    _step_install_dependencies
    _step_setup_repository

    if _step_install_software; then
        _step_post_install
        global_log_message "INFO" "${_SOFTWARE_COMMAND} installation completed successfully"
        global_set_proc_status "${_SOFTWARE_COMMAND}" "SUCCESS"
        _step_cleanup
        return 0
    else
        global_log_message "ERROR" "Failed to install ${_SOFTWARE_COMMAND}"
        global_set_proc_status "${_SOFTWARE_COMMAND}" "FAILED"
        _step_cleanup
        return 1
    fi

}

# Necessary function to source libraries
_source_lib() {
    local file="${1:-}"
    
    if [[ -n "${file}" ]]; then
        if [[ "$LOCAL" == "true" ]]; then
            # Source local libs
             if ! source "src/libs/${file}"; then
                echo "ERROR" "Failed to source local library: ${file}"
                exit 1
            fi
        else
            # Redirect curl errors to console
            if ! source <(curl -fsSL "${_LIBS_REMOTE_URL}${file}" 2>&1); then
                echo "ERROR" "Failed to source library: ${file}"
                exit 1
            fi
        fi
        global_log_message "DEBUG" "Successfully sourced library: ${file}"
    else
        echo "ERROR" "No library file specified to source"
        exit 1
    fi
}

# Prepare for installation
_step_init() {
    global_log_message "INFO" "Starting installation of ${_SOFTWARE_COMMAND}"
    global_log_message "INFO" "_SOFTWARE_VERSION: ${_SOFTWARE_VERSION}"
    
    if global_check_if_installed "${_SOFTWARE_COMMAND}"; then
        global_set_proc_status "${_SOFTWARE_COMMAND}" "SKIPPED"
        return 0
    fi
}


# Install dependencies
_step_install_dependencies() {
    global_log_message "INFO" "Installing dependencies for ${_SOFTWARE_COMMAND}"
    apt-get update >>"${GLOBAL_LOG_FILE}" 2>&1
    global_install_apt_package "${_DEPENDENCIES[@]}"
}

# Setup spotify repository
_step_setup_repository() {
    global_log_message "INFO" "Setting up Spotify repository"
    
    # Add spotify's official GPG key
    global_log_message "INFO" "Adding Spotify's official GPG key"
    curl -sS "${_SPOTIFY_GPG_URL}" | gpg --dearmor --yes -o "${_SPOTIFY_GPG_KEY_PATH}" >>"${GLOBAL_LOG_FILE}" 2>&1

    if [[ ! -f "${_SPOTIFY_GPG_KEY_PATH}" ]]; then
        global_log_message "ERROR" "Failed to download Spotify GPG key"
        return 1
    fi
    
    # Add spotify repository to APT sources
    global_log_message "INFO" "Adding Spotify repository to APT sources"
    echo "deb ${_SPOTIFY_REPO_URL} stable non-free" | tee /etc/apt/sources.list.d/spotify.list >>"${GLOBAL_LOG_FILE}" 2>&1
    
    # Update package index with new repository
    apt-get update >>"${GLOBAL_LOG_FILE}" 2>&1
}


# Install the software
_step_install_software() {
    global_log_message "INFO" "Installing ${_SOFTWARE_COMMAND}"
    
    global_install_apt_package "spotify-client"
    
    return 0 
}

# Post-installation configuration
_step_post_install() {
    global_log_message "INFO" "Post installation of ${_SOFTWARE_COMMAND}"
    # No post-installation steps required for Spotify client
}

# Cleanup after installation
_step_cleanup() {
    global_log_message "INFO" "Cleaning up after installation of ${_SOFTWARE_COMMAND}"
    
    if [[ "$(global_get_proc_status "${_SOFTWARE_COMMAND}")" == "SUCCESS" ]]; then
        apt-get clean >>"${GLOBAL_LOG_FILE}" 2>&1
    fi
}

# Execute main function
main "$@"

# Exit with success
exit 0
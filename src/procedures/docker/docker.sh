#!/usr/bin/env bash

# =============================================================================
# Pimp My Ubuntu - Docker Engine Installation Procedure
# =============================================================================
# Description: Installs Docker Engine (CE) on Ubuntu using the official repository
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
readonly _SOFTWARE_COMMAND="docker"
readonly _SOFTWARE_DESCRIPTION="Docker Engine - containerization platform"
readonly _SOFTWARE_VERSION="1.0.0"
readonly _DEPENDENCIES=("apt-transport-https" "ca-certificates" "curl" "software-properties-common" "gnupg" "lsb-release")
readonly _REPOSITORY_TAG="v0.1.0"
readonly _REPOSITORY_RAW_URL="https://raw.github.com/Multitec-UA/pimp_my_ubuntu/refs/tags/${_REPOSITORY_TAG}/"
readonly _LIBS_REMOTE_URL="${_REPOSITORY_RAW_URL}/src/libs/"

# Docker-specific constants
readonly _DOCKER_GPG_URL="https://download.docker.com/linux/ubuntu/gpg"
readonly _DOCKER_GPG_KEY_PATH="/usr/share/keyrings/docker-archive-keyring.gpg"
readonly _DOCKER_REPO_URL="https://download.docker.com/linux/ubuntu"
readonly _DOCKER_PACKAGES=("docker-ce" "docker-ce-cli" "containerd.io" "docker-buildx-plugin" "docker-compose-plugin")


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

    _step_uninstall_old_versions
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
        # Redirect curl errors to console
        if ! source <(curl -fsSL "${_LIBS_REMOTE_URL}${file}" 2>&1); then
            echo "ERROR" "Failed to source library: ${file}"
            exit 1
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

# Uninstall old or conflicting Docker versions
_step_uninstall_old_versions() {
    global_log_message "INFO" "Removing old or conflicting Docker versions"
    
    local old_packages=("docker.io" "docker-doc" "docker-compose" "docker-compose-v2" "podman-docker" "containerd" "runc")
    
    for package in "${old_packages[@]}"; do
        if dpkg -l | grep -q "^ii.*${package}"; then
            global_log_message "INFO" "Removing conflicting package: ${package}"
            apt-get remove -y "${package}" >>"${GLOBAL_LOG_FILE}" 2>&1
        fi
    done
}

# Install dependencies
_step_install_dependencies() {
    global_log_message "INFO" "Installing dependencies for ${_SOFTWARE_COMMAND}"

    # Update package index first
    apt-get update >>"${GLOBAL_LOG_FILE}" 2>&1
    
    # Install dependencies from the _DEPENDENCIES array
    global_install_apt_package "${_DEPENDENCIES[@]}"
}

# Setup Docker repository
_step_setup_repository() {
    global_log_message "INFO" "Setting up Docker official repository"
    
    # Create keyrings directory if it doesn't exist
    mkdir -p /etc/apt/keyrings >>"${GLOBAL_LOG_FILE}" 2>&1
    
    # Download Docker's official GPG key
    global_log_message "INFO" "Adding Docker's official GPG key"
    curl -fsSL "${_DOCKER_GPG_URL}" | gpg --dearmor -o "${_DOCKER_GPG_KEY_PATH}" >>"${GLOBAL_LOG_FILE}" 2>&1
    
    if [[ ! -f "${_DOCKER_GPG_KEY_PATH}" ]]; then
        global_log_message "ERROR" "Failed to download Docker GPG key"
        return 1
    fi
    
    # Set appropriate permissions
    chmod a+r "${_DOCKER_GPG_KEY_PATH}" >>"${GLOBAL_LOG_FILE}" 2>&1
    
    # Add Docker repository to APT sources
    global_log_message "INFO" "Adding Docker repository to APT sources"
    local codename
    codename=$(lsb_release -cs)
    
    echo "deb [arch=$(dpkg --print-architecture) signed-by=${_DOCKER_GPG_KEY_PATH}] ${_DOCKER_REPO_URL} ${codename} stable" | \
        tee /etc/apt/sources.list.d/docker.list >>"${GLOBAL_LOG_FILE}" 2>&1
    
    # Update package index with new repository
    apt-get update >>"${GLOBAL_LOG_FILE}" 2>&1
}

# Install the software
_step_install_software() {
    global_log_message "INFO" "Installing ${_SOFTWARE_COMMAND} packages"

    # Install Docker packages
    global_install_apt_package "${_DOCKER_PACKAGES[@]}"
    
    # Verify Docker installation
    if command -v docker >/dev/null 2>&1; then
        global_log_message "INFO" "Docker installed successfully"
        local docker_version
        docker_version=$(docker --version 2>/dev/null)
        global_log_message "INFO" "Installed Docker version: ${docker_version}"
        
        # Start and enable Docker service
        global_log_message "INFO" "Starting and enabling Docker service"
        systemctl start docker >>"${GLOBAL_LOG_FILE}" 2>&1
        systemctl enable docker >>"${GLOBAL_LOG_FILE}" 2>&1
        
        return 0
    else
        global_log_message "ERROR" "Docker installation verification failed"
        return 1
    fi
}

# Post-installation configuration
_step_post_install() {
    global_log_message "INFO" "Post installation of ${_SOFTWARE_COMMAND}"
    
    # Configure Docker to be used without sudo
    _configure_docker_group
    
    # Verify Docker service status
    if systemctl is-active --quiet docker; then
        global_log_message "INFO" "Docker service is running"
    else
        global_log_message "WARNING" "Docker service is not running"
    fi
    
    # Test Docker installation with hello-world
    _test_docker_installation
}

# Configure Docker group for non-root usage
_configure_docker_group() {
    global_log_message "INFO" "Configuring Docker group for non-root usage"
    
    # Create docker group if it doesn't exist
    if ! getent group docker >/dev/null; then
        global_log_message "INFO" "Creating docker group"
        groupadd docker >>"${GLOBAL_LOG_FILE}" 2>&1
    fi
    
    # Add user to docker group if we can determine the real user
    if [[ -n "${GLOBAL_REAL_USER:-}" ]]; then
        global_log_message "INFO" "Adding user ${GLOBAL_REAL_USER} to docker group"
        usermod -aG docker "${GLOBAL_REAL_USER}" >>"${GLOBAL_LOG_FILE}" 2>&1
        
        # Fix .docker directory permissions if it exists
        local docker_config_dir="${GLOBAL_REAL_HOME}/.docker"
        if [[ -d "${docker_config_dir}" ]]; then
            global_log_message "INFO" "Fixing Docker configuration directory permissions"
            chown -R "${GLOBAL_REAL_USER}:${GLOBAL_REAL_USER}" "${docker_config_dir}" >>"${GLOBAL_LOG_FILE}" 2>&1
            chmod -R g+rwx "${docker_config_dir}" >>"${GLOBAL_LOG_FILE}" 2>&1
        fi
        
        global_log_message "INFO" "User ${GLOBAL_REAL_USER} added to docker group"
        global_log_message "INFO" "Log out and log back in to use Docker without sudo"
    else
        global_log_message "WARNING" "Could not determine real user. You may need to manually add your user to the docker group:"
        global_log_message "WARNING" "sudo usermod -aG docker \$USER"
    fi
}

# Test Docker installation
_test_docker_installation() {
    global_log_message "INFO" "Testing Docker installation with hello-world"
    
    # Pull and run hello-world image to verify installation
    if docker run --rm hello-world >>"${GLOBAL_LOG_FILE}" 2>&1; then
        global_log_message "INFO" "Docker hello-world test completed successfully"
    else
        global_log_message "WARNING" "Docker hello-world test failed, but installation may still be working"
    fi
}

# Cleanup after installation
_step_cleanup() {
    global_log_message "INFO" "Cleaning up after installation of ${_SOFTWARE_COMMAND}"
    
    # Clean apt cache if we installed new packages
    if [[ "$(global_get_proc_status "${_SOFTWARE_COMMAND}")" == "SUCCESS" ]]; then
        global_log_message "DEBUG" "Cleaning apt cache"
        apt-get clean >>"${GLOBAL_LOG_FILE}" 2>&1
    fi
    
    # Remove any temporary files if created
    # (None expected for this installation)
}

# Execute main function
main "$@"

# Exit with success
exit 0
#!/usr/bin/env bash

# =============================================================================
# Pimp My Ubuntu - ZSH Installation Procedure
# =============================================================================
# Description: Install and configure ZSH with Oh-My-Zsh, plugins, and theme
# Author: Multitec-UA
# Repository: https://github.com/Multitec-UA/pimp_my_ubuntu
# License: MIT
#
# COMMON INSTRUCTIONS:
# 1. Dont use echo. Use global_log_message instead.
# 2. Send all output to log file. command >>"${GLOBAL_LOG_FILE}" 2>&1
# =============================================================================

# Debug flag - set to true to enable debug messages
readonly DEBUG=${DEBUG:-true}

# Software-common constants
readonly _REPOSITORY_URL="https://raw.github.com/Multitec-UA/pimp_my_ubuntu/main"
readonly _SOFTWARE_COMMAND="zsh"
readonly _SOFTWARE_DESCRIPTION="ZSH with Oh-My-Zsh, plugins, and Powerlevel10k theme"
readonly _SOFTWARE_VERSION="1.0.0"
readonly _DEPENDENCIES=("git" "curl" "fontconfig")

# Software-specific constants
readonly _OH_MY_ZSH_INSTALL_URL="https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
readonly _ZSH_AUTOSUGGESTIONS_URL="https://github.com/zsh-users/zsh-autosuggestions"
readonly _ZSH_SYNTAX_HIGHLIGHTING_URL="https://github.com/zsh-users/zsh-syntax-highlighting.git"
readonly _POWERLEVEL10K_URL="https://github.com/romkatv/powerlevel10k.git"
readonly _MESLO_FONT_BASE_URL="https://github.com/romkatv/powerlevel10k-media/raw/master"

# Declare GLOBAL_INSTALLATION_STATUS if not already declared
if ! declare -p GLOBAL_INSTALLATION_STATUS >/dev/null 2>&1; then
    declare -A GLOBAL_INSTALLATION_STATUS
fi

# Strict mode
set -euo pipefail

# Main procedure function
main() {
    # Source global variables and functions
    _source_lib "/src/lib/global_utils.sh"
    
    global_check_root

    _step_init

    _step_install_dependencies

    if _step_install_software; then
        _step_post_install
        global_log_message "INFO" "${_SOFTWARE_COMMAND} installation completed successfully"
        GLOBAL_INSTALLATION_STATUS["${_SOFTWARE_COMMAND}"]="SUCCESS"
        _step_cleanup
        return 0
    else
        global_log_message "ERROR" "Failed to install ${_SOFTWARE_COMMAND}"
        GLOBAL_INSTALLATION_STATUS["${_SOFTWARE_COMMAND}"]="FAILED"
        _step_cleanup
        return 1
    fi
}

# Necessary function to source libraries
_source_lib() {
    local file="${1:-}"
    
    if [[ -n "${file}" ]]; then
        # Add error handling for curl command
        if ! source <(curl -fsSL "${_REPOSITORY_URL}/${file}"); then
            global_log_message "ERROR" "Failed to source library: ${file}"
            exit 1
        fi
        global_log_message "DEBUG" "Successfully sourced library: ${file}"
    else
        global_log_message "ERROR" "No library file specified to source"
        exit 1
    fi
}

# Prepare for installation
_step_init() {
    # Import installation status from environment
    global_import_installation_status
    
    global_log_message "INFO" "Starting installation of ${_SOFTWARE_COMMAND}"
    
    if global_check_if_installed "${_SOFTWARE_COMMAND}"; then
        GLOBAL_INSTALLATION_STATUS["${_SOFTWARE_COMMAND}"]="SKIPPED"
        global_export_installation_status
        return 0
    fi
}

# Install dependencies
_step_install_dependencies() {
    global_log_message "INFO" "Installing dependencies for ${_SOFTWARE_COMMAND}"
    # Update package lists
    apt-get update >>"${GLOBAL_LOG_FILE}" 2>&1
    global_install_apt_package "${_DEPENDENCIES[@]}"
}

# Install the software
_step_install_software() {
    global_log_message "INFO" "Installing ${_SOFTWARE_COMMAND}"
    
    # Install ZSH
    global_install_apt_package "${_SOFTWARE_COMMAND}"
    
    # Install Oh-My-Zsh
    _install_ohmyzsh
    
    # Return true if installation succeeded
    return 0
}

# Install Oh-My-Zsh
_install_ohmyzsh() {
    global_log_message "INFO" "Setting ZSH as default shell for user ${GLOBAL_REAL_USER}"
    # Make ZSH the default shell for the current user
    chsh -s "$(which zsh)" "${GLOBAL_REAL_USER}" >>"${GLOBAL_LOG_FILE}" 2>&1
    
    global_log_message "INFO" "Installing Oh-My-Zsh"
    
    # Install Oh-My-Zsh using direct curl pipe to bash (non-interactively)
    if [ "${GLOBAL_REAL_USER}" != "root" ]; then
        su - "${GLOBAL_REAL_USER}" -c 'RUNZSH=no sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"' >>"${GLOBAL_LOG_FILE}" 2>&1
    else
        RUNZSH=no sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" >>"${GLOBAL_LOG_FILE}" 2>&1
    fi
}

# Post-installation configuration
_step_post_install() {
    global_log_message "INFO" "Post installation of ${_SOFTWARE_COMMAND}"
    
    # Install ZSH plugins
    _install_zsh_plugins
    
    # Install Meslo Nerd Fonts
    _install_nerd_fonts
    
    # Install Powerlevel10k theme
    _install_powerlevel10k
    
    # Configure .zshrc with plugins and theme
    _configure_zshrc
    
    global_log_message "INFO" "ZSH configuration completed"
    global_log_message "INFO" "Please log out and log back in for changes to take effect"
    global_log_message "INFO" "After logging back in, you'll be prompted to configure Powerlevel10k"
}

# Cleanup after installation
_step_cleanup() {
    global_log_message "INFO" "Cleaning up after installation of ${_SOFTWARE_COMMAND}"
    
    # Clean apt cache
    if [[ "${GLOBAL_INSTALLATION_STATUS["${_SOFTWARE_COMMAND}"]}" == "SUCCESS" ]]; then
        global_log_message "DEBUG" "Cleaning apt cache"
        apt-get clean >>"${GLOBAL_LOG_FILE}" 2>&1
    fi
}

# Install ZSH plugins
_install_zsh_plugins() {
    global_log_message "INFO" "Installing ZSH plugins"
    
    ZSH_CUSTOM="${GLOBAL_REAL_HOME}/.oh-my-zsh/custom"
    
    # Install zsh-autosuggestions plugin
    global_log_message "INFO" "Installing zsh-autosuggestions plugin"
    if [ "${GLOBAL_REAL_USER}" != "root" ]; then
        su - "${GLOBAL_REAL_USER}" -c "if [ ! -d \"${ZSH_CUSTOM}/plugins/zsh-autosuggestions\" ]; then git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM}/plugins/zsh-autosuggestions; fi" >>"${GLOBAL_LOG_FILE}" 2>&1
    else
        bash -c "if [ ! -d \"${ZSH_CUSTOM}/plugins/zsh-autosuggestions\" ]; then git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM}/plugins/zsh-autosuggestions; fi" >>"${GLOBAL_LOG_FILE}" 2>&1
    fi
    
    # Install zsh-syntax-highlighting plugin
    global_log_message "INFO" "Installing zsh-syntax-highlighting plugin"
    if [ "${GLOBAL_REAL_USER}" != "root" ]; then
        su - "${GLOBAL_REAL_USER}" -c "if [ ! -d \"${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting\" ]; then git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting; fi" >>"${GLOBAL_LOG_FILE}" 2>&1
    else
        bash -c "if [ ! -d \"${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting\" ]; then git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting; fi" >>"${GLOBAL_LOG_FILE}" 2>&1
    fi
}

# Install Meslo Nerd Fonts
_install_nerd_fonts() {
    global_log_message "INFO" "Installing Meslo Nerd Fonts"
    
    FONT_DIR="${GLOBAL_REAL_HOME}/.local/share/fonts"
    
    # Install fonts directly
    FONTS_COMMAND="mkdir -p \"${FONT_DIR}\" && \
        cd \"${FONT_DIR}\" && \
        curl -fLo \"MesloLGS NF Regular.ttf\" \"${_MESLO_FONT_BASE_URL}/MesloLGS%20NF%20Regular.ttf\" && \
        curl -fLo \"MesloLGS NF Bold.ttf\" \"${_MESLO_FONT_BASE_URL}/MesloLGS%20NF%20Bold.ttf\" && \
        curl -fLo \"MesloLGS NF Italic.ttf\" \"${_MESLO_FONT_BASE_URL}/MesloLGS%20NF%20Italic.ttf\" && \
        curl -fLo \"MesloLGS NF Bold Italic.ttf\" \"${_MESLO_FONT_BASE_URL}/MesloLGS%20NF%20Bold%20Italic.ttf\" && \
        fc-cache -f -v"

    if [ "${GLOBAL_REAL_USER}" != "root" ]; then
        su - "${GLOBAL_REAL_USER}" -c "${FONTS_COMMAND}" >>"${GLOBAL_LOG_FILE}" 2>&1
    else
        bash -c "${FONTS_COMMAND}" >>"${GLOBAL_LOG_FILE}" 2>&1
    fi
}

# Install Powerlevel10k theme
_install_powerlevel10k() {
    global_log_message "INFO" "Installing Powerlevel10k theme"
    
    ZSH_CUSTOM="${GLOBAL_REAL_HOME}/.oh-my-zsh/custom"
    
    # Install Powerlevel10k theme directly
    if [ "${GLOBAL_REAL_USER}" != "root" ]; then
        su - "${GLOBAL_REAL_USER}" -c "if [ ! -d \"${ZSH_CUSTOM}/themes/powerlevel10k\" ]; then git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM}/themes/powerlevel10k; fi" >>"${GLOBAL_LOG_FILE}" 2>&1
    else
        bash -c "if [ ! -d \"${ZSH_CUSTOM}/themes/powerlevel10k\" ]; then git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM}/themes/powerlevel10k; fi" >>"${GLOBAL_LOG_FILE}" 2>&1
    fi
}

# Configure .zshrc with plugins and theme
_configure_zshrc() {
    global_log_message "INFO" "Configuring .zshrc"
    
    # Configure .zshrc directly
    ZSHRC_COMMAND='
        # Set the ZSH theme to powerlevel10k
        sed -i "/ZSH_THEME=/c\ZSH_THEME=\"powerlevel10k/powerlevel10k\"" ~/.zshrc

        # Set plugins
        sed -i "/^plugins=(git)$/c\plugins=(git z zsh-syntax-highlighting zsh-autosuggestions docker sudo web-search gcloud terraform)" ~/.zshrc

        # Add bat alias if batcat is installed
        if command -v batcat &> /dev/null; then
            if ! grep -q "alias bat='\''batcat'\''" ~/.zshrc; then
                echo "# bat alias" >> ~/.zshrc
                echo "export PATH=\"\$HOME/.local/bin/bat:\$PATH\"" >> ~/.zshrc
                echo "alias bat='\''batcat'\''" >> ~/.zshrc
            fi
        fi'
    
    if [ "${GLOBAL_REAL_USER}" != "root" ]; then
        su - "${GLOBAL_REAL_USER}" -c "${ZSHRC_COMMAND}" >>"${GLOBAL_LOG_FILE}" 2>&1
    else
        bash -c "${ZSHRC_COMMAND}" >>"${GLOBAL_LOG_FILE}" 2>&1
    fi

    # Remplace .p10k.zsh by .p10k.zsh.local if it exists
    if [[ -f "${GLOBAL_REAL_HOME}/.p10k.zsh" ]]; then
        cp "${GLOBAL_REAL_HOME}/.p10k.zsh" "${GLOBAL_REAL_HOME}/.p10k.zsh.local"
    fi

    # Replace .p10k.zsh content by remote file
    curl -fsSL https://raw.github.com/Multitec-UA/pimp_my_ubuntu/main/src/procedures/zsh/media/.p10k.zsh > "${GLOBAL_REAL_HOME}/.p10k.zsh"
    
    # Set proper ownership for the downloaded file
    chown "${GLOBAL_REAL_USER}:${GLOBAL_REAL_USER}" "${GLOBAL_REAL_HOME}/.p10k.zsh"
}

# Execute main function
main "$@"

# Export installation status at the end to propagate changes back to parent
global_export_installation_status

# Exit with success
exit 0 
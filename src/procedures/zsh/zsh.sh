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
    local header="Accept: application/vnd.github.v3.raw"
    local file="${1:-}"
    
    if [[ -n "${file}" ]]; then
        source <(curl -H "${header}" -s "${_REPOSITORY_URL}/${file}")
    else
        echo "Error: No library file specified to source" >&2
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
    
    # Make ZSH the default shell for the current user
    # Note: This needs to be done for the user, not as root
    REAL_USER=$(logname || echo "${SUDO_USER:-$USER}")
    global_log_message "INFO" "Setting ZSH as default shell for user ${REAL_USER}"
    chsh -s "$(which zsh)" "${REAL_USER}" >>"${GLOBAL_LOG_FILE}" 2>&1
    
    # Install Oh-My-Zsh
    _install_ohmyzsh
    
    # Return true if installation succeeded
    return 0
}

# Install Oh-My-Zsh
_install_ohmyzsh() {
    REAL_USER=$(logname || echo "${SUDO_USER:-$USER}")
    
    global_log_message "INFO" "Installing Oh-My-Zsh"
    # Create a temporary script to install Oh-My-Zsh non-interactively
    cat > /tmp/install_ohmyzsh.sh << 'EOF'
#!/bin/bash
export RUNZSH=no
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
EOF
    chmod +x /tmp/install_ohmyzsh.sh
    
    # Run the script as the real user
    if [ "${REAL_USER}" != "root" ]; then
        su - "${REAL_USER}" -c "/tmp/install_ohmyzsh.sh" >>"${GLOBAL_LOG_FILE}" 2>&1
    else
        /tmp/install_ohmyzsh.sh >>"${GLOBAL_LOG_FILE}" 2>&1
    fi
}

# Post-installation configuration
_step_post_install() {
    global_log_message "INFO" "Post installation of ${_SOFTWARE_COMMAND}"
    
    REAL_USER=$(logname || echo "${SUDO_USER:-$USER}")
    USER_HOME=$(eval echo ~${REAL_USER})
    
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
    
    # Remove temporary files
    if [[ -f "/tmp/install_ohmyzsh.sh" ]]; then
        rm -f "/tmp/install_ohmyzsh.sh" >>"${GLOBAL_LOG_FILE}" 2>&1
    fi
    
    # Clean apt cache
    if [[ "${GLOBAL_INSTALLATION_STATUS["${_SOFTWARE_COMMAND}"]}" == "SUCCESS" ]]; then
        global_log_message "DEBUG" "Cleaning apt cache"
        apt-get clean >>"${GLOBAL_LOG_FILE}" 2>&1
    fi
}

# Install ZSH plugins
_install_zsh_plugins() {
    global_log_message "INFO" "Installing ZSH plugins"
    
    REAL_USER=$(logname || echo "${SUDO_USER:-$USER}")
    USER_HOME=$(eval echo ~${REAL_USER})
    ZSH_CUSTOM="${USER_HOME}/.oh-my-zsh/custom"
    
    # Create command to install plugins
    cat > /tmp/install_zsh_plugins.sh << EOF
#!/bin/bash
# Install zsh-autosuggestions
if [ ! -d "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM}/plugins/zsh-autosuggestions
fi

# Install zsh-syntax-highlighting
if [ ! -d "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting
fi
EOF
    chmod +x /tmp/install_zsh_plugins.sh
    
    # Run the script as the real user
    if [ "${REAL_USER}" != "root" ]; then
        su - "${REAL_USER}" -c "/tmp/install_zsh_plugins.sh" >>"${GLOBAL_LOG_FILE}" 2>&1
    else
        /tmp/install_zsh_plugins.sh >>"${GLOBAL_LOG_FILE}" 2>&1
    fi
    
    rm -f /tmp/install_zsh_plugins.sh >>"${GLOBAL_LOG_FILE}" 2>&1
}

# Install Meslo Nerd Fonts
_install_nerd_fonts() {
    global_log_message "INFO" "Installing Meslo Nerd Fonts"
    
    REAL_USER=$(logname || echo "${SUDO_USER:-$USER}")
    USER_HOME=$(eval echo ~${REAL_USER})
    FONT_DIR="${USER_HOME}/.local/share/fonts"
    
    # Create command to install fonts
    cat > /tmp/install_fonts.sh << EOF
#!/bin/bash
mkdir -p "${FONT_DIR}"
cd "${FONT_DIR}"
curl -fLo "MesloLGS NF Regular.ttf" "${_MESLO_FONT_BASE_URL}/MesloLGS%20NF%20Regular.ttf"
curl -fLo "MesloLGS NF Bold.ttf" "${_MESLO_FONT_BASE_URL}/MesloLGS%20NF%20Bold.ttf"
curl -fLo "MesloLGS NF Italic.ttf" "${_MESLO_FONT_BASE_URL}/MesloLGS%20NF%20Italic.ttf" 
curl -fLo "MesloLGS NF Bold Italic.ttf" "${_MESLO_FONT_BASE_URL}/MesloLGS%20NF%20Bold%20Italic.ttf"
fc-cache -f -v
EOF
    chmod +x /tmp/install_fonts.sh
    
    # Run the script as the real user
    if [ "${REAL_USER}" != "root" ]; then
        su - "${REAL_USER}" -c "/tmp/install_fonts.sh" >>"${GLOBAL_LOG_FILE}" 2>&1
    else
        /tmp/install_fonts.sh >>"${GLOBAL_LOG_FILE}" 2>&1
    fi
    
    rm -f /tmp/install_fonts.sh >>"${GLOBAL_LOG_FILE}" 2>&1
}

# Install Powerlevel10k theme
_install_powerlevel10k() {
    global_log_message "INFO" "Installing Powerlevel10k theme"
    
    REAL_USER=$(logname || echo "${SUDO_USER:-$USER}")
    USER_HOME=$(eval echo ~${REAL_USER})
    ZSH_CUSTOM="${USER_HOME}/.oh-my-zsh/custom"
    
    # Create command to install theme
    cat > /tmp/install_powerlevel10k.sh << EOF
#!/bin/bash
if [ ! -d "${ZSH_CUSTOM}/themes/powerlevel10k" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM}/themes/powerlevel10k
fi
EOF
    chmod +x /tmp/install_powerlevel10k.sh
    
    # Run the script as the real user
    if [ "${REAL_USER}" != "root" ]; then
        su - "${REAL_USER}" -c "/tmp/install_powerlevel10k.sh" >>"${GLOBAL_LOG_FILE}" 2>&1
    else
        /tmp/install_powerlevel10k.sh >>"${GLOBAL_LOG_FILE}" 2>&1
    fi
    
    rm -f /tmp/install_powerlevel10k.sh >>"${GLOBAL_LOG_FILE}" 2>&1
}

# Configure .zshrc with plugins and theme
_configure_zshrc() {
    global_log_message "INFO" "Configuring .zshrc"
    
    REAL_USER=$(logname || echo "${SUDO_USER:-$USER}")
    USER_HOME=$(eval echo ~${REAL_USER})
    ZSHRC="${USER_HOME}/.zshrc"
    
    # Create command to modify .zshrc
    cat > /tmp/configure_zshrc.sh << 'EOF'
#!/bin/bash
# Set the ZSH theme to powerlevel10k
sed -i '/ZSH_THEME=/c\ZSH_THEME="powerlevel10k/powerlevel10k"' ~/.zshrc

# Set plugins
sed -i '/^plugins=(git)$/c\plugins=(git z zsh-syntax-highlighting zsh-autosuggestions docker sudo web-search terraform)' ~/.zshrc

# Add bat alias if batcat is installed
if command -v batcat &> /dev/null; then
    if ! grep -q "alias bat='batcat'" ~/.zshrc; then
        echo '# bat alias' >> ~/.zshrc
        echo 'export PATH="$HOME/.local/bin/bat:$PATH"' >> ~/.zshrc
        echo "alias bat='batcat'" >> ~/.zshrc
    fi
fi
EOF
    chmod +x /tmp/configure_zshrc.sh
    
    # Run the script as the real user
    if [ "${REAL_USER}" != "root" ]; then
        su - "${REAL_USER}" -c "/tmp/configure_zshrc.sh" >>"${GLOBAL_LOG_FILE}" 2>&1
    else
        /tmp/configure_zshrc.sh >>"${GLOBAL_LOG_FILE}" 2>&1
    fi
    
    rm -f /tmp/configure_zshrc.sh >>"${GLOBAL_LOG_FILE}" 2>&1
}

# Execute main function
main "$@"

# Export installation status at the end to propagate changes back to parent
global_export_installation_status

# Exit with success
exit 0 
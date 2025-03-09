#!/usr/bin/env bash

# =============================================================================
# Pimp My Ubuntu - Common Utilities
# =============================================================================
# Description: Common utility functions used across installation procedures
# Author: Multitec-UA
# Repository: https://github.com/Multitec-UA/pimp_my_ubuntu
# License: MIT
# =============================================================================

# Display a progress bar
# Usage: show_progress 45 "Installing..."
show_progress() {
    local percent=$1
    local message=${2:-""}
    local w=50 # Width of the progress bar
    local fill=$((w * percent / 100))
    local empty=$((w - fill))
    
    printf "\r[%s%s] %d%% %s" \
        "$(printf "#%.0s" $(seq 1 $fill))" \
        "$(printf "=%.0s" $(seq 1 $empty))" \
        "$percent" \
        "$message"
}



# Check if a package is installed via apt
# Usage: is_package_installed "package-name"
is_package_installed() {
    local package_name=$1
    dpkg -l "$package_name" &> /dev/null
}

# Add an APT repository safely
# Usage: add_apt_repository "ppa:user/repo-name"
add_apt_repository() {
    local repo=$1
    if ! grep -q "^deb.*${repo}" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
        add-apt-repository -y "$repo"
        apt-get update
    fi
}

# Download a file with progress
# Usage: download_file "https://example.com/file.tar.gz" "/tmp/file.tar.gz"
download_file() {
    local url=$1
    local output=$2
    wget --progress=bar:force -O "$output" "$url" 2>&1
}

# Check if running inside a terminal
# Usage: if is_terminal; then echo "Running in terminal"; fi
is_terminal() {
    [ -t 0 ]
}

# Get user confirmation
# Usage: if get_confirmation "Do you want to proceed?"; then echo "Proceeding..."; fi
get_confirmation() {
    local prompt=${1:-"Do you want to continue?"}
    local response
    
    if is_terminal; then
        read -rp "${prompt} [y/N] " response
        case "$response" in
            [yY][eE][sS]|[yY]) return 0 ;;
            *) return 1 ;;
        esac
    else
        # Non-interactive mode, assume yes
        return 0
    fi
}

# Create a backup of a file
# Usage: backup_file "/etc/example.conf"
backup_file() {
    local file=$1
    local backup="${file}.bak.$(date +%Y%m%d_%H%M%S)"
    
    if [[ -f "$file" ]]; then
        cp "$file" "$backup"
        log_message "INFO" "Created backup of ${file} at ${backup}"
    fi
}

# Check system requirements
# Usage: check_system_requirements "20.04"
check_system_requirements() {
    local required_version=$1
    local current_version
    
    current_version=$(lsb_release -rs)
    if [[ "${current_version}" != "${required_version}" ]]; then
        log_message "ERROR" "Unsupported Ubuntu version: ${current_version}. Required: ${required_version}"
        return 1
    fi
    return 0
}

# Clean up temporary files
# Usage: cleanup "/tmp/installation-files"
cleanup() {
    local dir=$1
    if [[ -d "$dir" ]]; then
        rm -rf "$dir"
        log_message "INFO" "Cleaned up temporary directory: ${dir}"
    fi
} 
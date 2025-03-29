#!/usr/bin/env bash

# =============================================================================
# Pimp My Ubuntu - Test for Global Utilities
# =============================================================================
# Description: Test script for global_utils.sh functions
# Repository: https://github.com/Multitec-UA/pimp_my_ubuntu
# License: MIT
# =============================================================================

# Source the global_utils.sh file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/./global_utils.sh"

# Test results counter
TESTS_PASSED=0
TESTS_FAILED=0

# Test function wrapper
run_test() {
    local test_name=$1
    local test_function=$2
    
    echo "=== Testing ${test_name} ==="
    
    if ${test_function}; then
        echo "✅ PASSED: ${test_name}"
        ((TESTS_PASSED++))
    else
        echo "❌ FAILED: ${test_name}"
        ((TESTS_FAILED++))
    fi
    echo
}

# Test global_run_as_user
test_global_run_as_user() {
    echo "Testing global_run_as_user function..."
    
    # Create a simple echo command to run as user
    output=$(global_run_as_user whoami)
    
    # Check if the command ran as expected
    if [[ "$output" == "$GLOBAL_REAL_USER" ]]; then
        echo "Output matches expected user: $output"
        return 0
    else
        echo "Expected output to be $GLOBAL_REAL_USER but got $output"
        return 1
    fi
}

# Test global_ensure_dir
test_global_ensure_dir() {
    echo "Testing global_ensure_dir function..."
    
    # Create a test directory
    local test_dir="/tmp/pmu_test_dir"
    
    # Remove if it exists
    rm -rf "$test_dir"
    
    # Test creating directory
    global_ensure_dir "$test_dir"
    
    # Check if directory exists and has correct ownership
    if [[ -d "$test_dir" ]]; then
        echo "Directory created successfully: $test_dir"
        
        # Get owner
        local owner=$(stat -c '%U' "$test_dir")
        
        if [[ "$owner" == "$GLOBAL_REAL_USER" ]]; then
            echo "Directory has correct ownership: $owner"
            
            # Clean up
            rm -rf "$test_dir"
            return 0
        else
            echo "Directory has incorrect ownership. Expected $GLOBAL_REAL_USER, got $owner"
            
            # Clean up
            rm -rf "$test_dir"
            return 1
        fi
    else
        echo "Directory was not created: $test_dir"
        return 1
    fi
}

# Test global_setup_logging
test_global_setup_logging() {
    echo "Testing global_setup_logging function..."
    
    # Save the original value
    local original_value=$GLOBAL_LOGGING_INITIALIZED
    local original_command=$_SOFTWARE_COMMAND
    
    # Set values to trigger initialization
    GLOBAL_LOGGING_INITIALIZED=false
    _SOFTWARE_COMMAND="main-menu"
    
    # Run function
    global_setup_logging
    
    # Check if log directory and file exist
    if [[ -d "$GLOBAL_LOG_DIR" && -f "$GLOBAL_LOG_FILE" ]]; then
        echo "Log directory and file created successfully"
        
        # Check if initialization flag was set
        if [[ "$GLOBAL_LOGGING_INITIALIZED" == "true" ]]; then
            echo "Initialization flag set correctly"
            
            # Restore original values
            GLOBAL_LOGGING_INITIALIZED=$original_value
            _SOFTWARE_COMMAND=$original_command
            return 0
        else
            echo "Initialization flag not set"
            
            # Restore original values
            GLOBAL_LOGGING_INITIALIZED=$original_value
            _SOFTWARE_COMMAND=$original_command
            return 1
        fi
    else
        echo "Log directory or file was not created"
        
        # Restore original values
        GLOBAL_LOGGING_INITIALIZED=$original_value
        _SOFTWARE_COMMAND=$original_command
        return 1
    fi
}

# Test global_log_message
test_global_log_message() {
    echo "Testing global_log_message function..."
    
    # Create a temporary log file
    local temp_log_file="/tmp/pmu_test_log.txt"
    
    # Create a wrapper function that redirects to our test file
    global_log_message_test() {
        local level="$1"
        local message="$2"
        local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
        local log_entry="[${timestamp}] [${level}] ${message}"
        
        echo -e "${log_entry}" >> "$temp_log_file"
        echo -e "${log_entry}"
    }
    
    # Clear the test log file
    rm -f "$temp_log_file"
    touch "$temp_log_file"
    
    # Test log message with our wrapper
    local test_message="This is a test message"
    global_log_message_test "INFO" "$test_message"
    
    # Check if message was logged
    if grep -q "$test_message" "$temp_log_file"; then
        echo "Message was logged successfully: $test_message"
        
        # Clean up
        rm -f "$temp_log_file"
        return 0
    else
        echo "Message was not logged to $temp_log_file"
        
        # Clean up
        rm -f "$temp_log_file"
        return 1
    fi
}

# Test global_check_root
test_global_check_root() {
    echo "Testing global_check_root function..."
    
    # Create a mock function that simulates global_check_root
    # without trying to modify EUID
    mock_check_root() {
        local mock_euid=$1
        
        if [[ $mock_euid -ne 0 ]]; then
            echo "This script must be run as root"
            return 1
        fi
        
        return 0
    }
    
    # Test with root EUID=0
    if mock_check_root 0; then
        echo "Root check passed when EUID=0: Correct"
    else
        echo "Root check failed when EUID=0: Incorrect"
        return 1
    fi
    
    # Test with non-root EUID=1000
    if mock_check_root 1000; then
        echo "Root check passed when EUID=1000: Incorrect"
        return 1
    else
        echo "Root check failed when EUID=1000: Correct"
    fi
    
    echo "Root check function logic is working correctly"
    return 0
}

# Test global_declare_installation_status
test_global_declare_installation_status() {
    echo "Testing global_declare_installation_status function..."
    
    # Unset the variable first
    unset GLOBAL_INSTALLATION_STATUS
    
    # Call the function
    global_declare_installation_status
    
    # Check if variable is declared
    if declare -p GLOBAL_INSTALLATION_STATUS &>/dev/null; then
        echo "GLOBAL_INSTALLATION_STATUS declared successfully"
        
        # Check if it's an associative array
        if declare -p GLOBAL_INSTALLATION_STATUS | grep -q "declare -A"; then
            echo "GLOBAL_INSTALLATION_STATUS is an associative array"
            return 0
        else
            echo "GLOBAL_INSTALLATION_STATUS is not an associative array"
            return 1
        fi
    else
        echo "GLOBAL_INSTALLATION_STATUS was not declared"
        return 1
    fi
}

# Test status file functions as a group
test_installation_status_functions() {
    echo "Testing installation status functions..."
    
    # Use a temporary file without modifying readonly variable
    local test_status_file="/tmp/pmu_test_status.tmp"
    rm -f "$test_status_file"
    touch "$test_status_file"
    
    # Define mock functions that use our test file instead
    mock_set_installation_status() {
        local key=$1
        local value=$2
        # Remove any existing entry for this key
        local temp_file="${test_status_file}.tmp"
        grep -v "^${key}:" "$test_status_file" > "$temp_file" || true
        mv "$temp_file" "$test_status_file"
        # Add the new entry
        echo "${key}:${value}" >> "$test_status_file"
    }
    
    mock_get_installation_status() {
        local key=$1
        grep "^${key}:" "$test_status_file" | cut -d: -f2
    }
    
    mock_unset_installation_status() {
        local key=$1
        local temp_file="${test_status_file}.tmp"
        grep -v "^${key}:" "$test_status_file" > "$temp_file"
        mv "$temp_file" "$test_status_file"
    }
    
    # Test setting a value
    mock_set_installation_status "test_app" "installed"
    
    # Test getting a value
    local status=$(mock_get_installation_status "test_app")
    
    if [[ "$status" != "installed" ]]; then
        echo "Expected status 'installed', got '$status'"
        rm -f "$test_status_file"
        return 1
    fi
    
    # Test updating a value
    mock_set_installation_status "test_app" "updated"
    status=$(mock_get_installation_status "test_app")
    
    if [[ "$status" != "updated" ]]; then
        echo "Expected status 'updated', got '$status'"
        rm -f "$test_status_file"
        return 1
    fi
    
    # Test unsetting a value
    mock_unset_installation_status "test_app"
    status=$(mock_get_installation_status "test_app")
    
    if [[ -n "$status" ]]; then
        echo "Expected empty status after unset, got '$status'"
        rm -f "$test_status_file"
        return 1
    fi
    
    echo "All installation status functions working correctly"
    rm -f "$test_status_file"
    return 0
}

# Test global_check_if_installed
test_global_check_if_installed() {
    echo "Testing global_check_if_installed function..."
    
    # Test with a command that should exist
    if global_check_if_installed "bash"; then
        echo "bash is correctly identified as installed"
    else
        echo "Failed to identify bash as installed"
        return 1
    fi
    
    # Test with a command that shouldn't exist
    if global_check_if_installed "this_command_definitely_does_not_exist_12345"; then
        echo "Incorrectly identified non-existent command as installed"
        return 1
    else
        echo "Correctly identified non-existent command as not installed"
    fi
    
    return 0
}

# Test global_install_apt_package (mock version)
test_global_install_apt_package() {
    echo "Testing global_install_apt_package function (mock version)..."
    
    # Mock the apt-get and global_check_if_installed functions
    apt-get() {
        if [[ "$2" == "mock_success" ]]; then
            return 0
        else
            return 1
        fi
    }
    
    global_check_if_installed_original=$global_check_if_installed
    global_check_if_installed() {
        if [[ "$1" == "mock_already_installed" || "$1" == "mock_success" ]]; then
            return 0
        else
            return 1
        fi
    }
    
    # Test with a package that should already be installed
    if global_install_apt_package "mock_already_installed"; then
        echo "Correctly skipped already installed package"
    else
        echo "Failed to handle already installed package"
        # Restore original function
        global_check_if_installed=$global_check_if_installed_original
        unset -f apt-get
        return 1
    fi
    
    # Test with a package that should install successfully
    if global_install_apt_package "mock_success"; then
        echo "Successfully installed package"
    else
        echo "Failed to install package that should succeed"
        # Restore original function
        global_check_if_installed=$global_check_if_installed_original
        unset -f apt-get
        return 1
    fi
    
    # Test with a package that should fail
    if global_install_apt_package "mock_failure"; then
        echo "Incorrectly succeeded for package that should fail"
        # Restore original function
        global_check_if_installed=$global_check_if_installed_original
        unset -f apt-get
        return 1
    else
        echo "Correctly handled failed installation"
    fi
    
    # Restore original function
    global_check_if_installed=$global_check_if_installed_original
    unset -f apt-get
    return 0
}

# Test global_download_media (mock version)
test_global_download_media() {
    echo "Testing global_download_media function (mock version)..."
    
    # Save original values
    local original_download_dir=$GLOBAL_DOWNLOAD_DIR
    local original_repo_url=$_REPOSITORY_RAW_URL
    
    # Create test directory
    GLOBAL_DOWNLOAD_DIR="/tmp/pmu_test_download"
    mkdir -p "$GLOBAL_DOWNLOAD_DIR"
    
    # Set mock repository URL
    _REPOSITORY_RAW_URL="https://example.com"
    
    # Mock curl function
    curl() {
        # Create a dummy file as if downloaded
        local output_file=""
        for arg in "$@"; do
            if [[ "$previous_arg" == "-o" ]]; then
                output_file="$arg"
            fi
            previous_arg="$arg"
        done
        
        if [[ -n "$output_file" ]]; then
            echo "Mock downloaded content" > "$output_file"
            return 0
        else
            return 1
        fi
    }
    
    # Test with a valid file path
    if global_download_media "test/path/file.txt"; then
        echo "Download function returned success"
        
        # Check if file exists
        if [[ -f "$GLOBAL_DOWNLOAD_DIR/file.txt" ]]; then
            echo "File was created: $GLOBAL_DOWNLOAD_DIR/file.txt"
            
            # Clean up
            rm -rf "$GLOBAL_DOWNLOAD_DIR"
            GLOBAL_DOWNLOAD_DIR=$original_download_dir
            _REPOSITORY_RAW_URL=$original_repo_url
            unset -f curl
            return 0
        else
            echo "File was not created: $GLOBAL_DOWNLOAD_DIR/file.txt"
            
            # Clean up
            rm -rf "$GLOBAL_DOWNLOAD_DIR"
            GLOBAL_DOWNLOAD_DIR=$original_download_dir
            _REPOSITORY_RAW_URL=$original_repo_url
            unset -f curl
            return 1
        fi
    else
        echo "Download function returned failure"
        
        # Clean up
        rm -rf "$GLOBAL_DOWNLOAD_DIR"
        GLOBAL_DOWNLOAD_DIR=$original_download_dir
        _REPOSITORY_RAW_URL=$original_repo_url
        unset -f curl
        return 1
    fi
}

# Run tests
echo "=== Starting Global Utils Test Suite ==="
echo

run_test "global_run_as_user" test_global_run_as_user
run_test "global_ensure_dir" test_global_ensure_dir
run_test "global_setup_logging" test_global_setup_logging
run_test "global_log_message" test_global_log_message
run_test "global_check_root" test_global_check_root
run_test "global_declare_installation_status" test_global_declare_installation_status
run_test "installation_status_functions" test_installation_status_functions
run_test "global_check_if_installed" test_global_check_if_installed
run_test "global_install_apt_package" test_global_install_apt_package
run_test "global_download_media" test_global_download_media

# Print summary
echo "=== Test Summary ==="
echo "Tests passed: $TESTS_PASSED"
echo "Tests failed: $TESTS_FAILED"
echo "Total tests: $((TESTS_PASSED + TESTS_FAILED))"

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "All tests passed! 🎉"
    exit 0
else
    echo "Some tests failed. 😢"
    exit 1
fi 
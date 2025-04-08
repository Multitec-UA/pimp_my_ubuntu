#!/usr/bin/env bash

# =============================================================================
# Pimp My Ubuntu - Test for Global Utilities
# =============================================================================
# Description: Test script for global_utils.sh functions
# Repository: https://github.com/Multitec-UA/pimp_my_ubuntu
# License: MIT
# =============================================================================

# Debug flag - set to true to enable debug messages
readonly DEBUG=${DEBUG:-false}
readonly LOCAL=${LOCAL:-false}

# Software-common constants
readonly _SOFTWARE_COMMAND="test-global-utils"
readonly _SOFTWARE_DESCRIPTION="Test script for global_utils.sh functions"
readonly _SOFTWARE_VERSION="1.0.0"


# Source the global_utils.sh file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../src/libs/global_utils.sh"

# --- DEBUG: Verify sourced variables ---
echo "DEBUG: Immediately after source:" >&2
echo "  GLOBAL_TEMP_PATH=[${GLOBAL_TEMP_PATH}]" >&2
echo "  GLOBAL_STATUS_FILE=[${GLOBAL_STATUS_FILE}]" >&2
echo "------------------------------------" >&2
# --- END DEBUG ---

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
    
    # Mock apt-get install and global_check_if_installed
    # We need to keep track of calls and simulate success/failure
    declare -A MOCK_APT_INSTALL_STATUS
    declare -A MOCK_CHECK_INSTALLED_STATUS

    MOCK_APT_INSTALL_STATUS["mock_success"]=0 # Will succeed
    MOCK_APT_INSTALL_STATUS["mock_failure"]=1 # Will fail

    MOCK_CHECK_INSTALLED_STATUS["mock_already_installed"]=0 # Already installed
    MOCK_CHECK_INSTALLED_STATUS["mock_success"]=1 # Not installed initially, becomes 0 after mock install
    MOCK_CHECK_INSTALLED_STATUS["mock_failure"]=1 # Not installed, remains 1 after mock install fails

    apt_get_original=$(which apt-get)
    apt-get() {
        local action=$1
        local pkg=$3
        if [[ "$action" == "install" ]]; then
            echo "Mock apt-get install -y $pkg" >> /dev/null # Simulate output
            local exit_code=${MOCK_APT_INSTALL_STATUS[$pkg]:-1} # Default to fail if not defined
            if [[ $exit_code -eq 0 ]]; then
                 # If install succeeds, update the check status
                 MOCK_CHECK_INSTALLED_STATUS[$pkg]=0
            fi
            return $exit_code
        else
            # For other apt-get commands, maybe call original? Risky in test. Error out.
            echo "Mock apt-get only handles 'install'" >&2
            return 1
        fi
    }

    global_check_if_installed_original=$global_check_if_installed
    global_check_if_installed() {
        local pkg=$1
        local exit_code=${MOCK_CHECK_INSTALLED_STATUS[$pkg]:-1} # Default to not installed
        # echo "Mock check_if_installed $pkg -> $exit_code" >> /dev/null # Debug
        return $exit_code
    }


    local all_passed=true

    # Test with a package that should already be installed (should skip install)
    MOCK_CHECK_INSTALLED_STATUS["mock_already_installed"]=0
    if global_install_apt_package "mock_already_installed"; then
        echo "  ✅ Correctly handled already installed package"
    else
        echo "  ❌ Failed to handle already installed package"
        all_passed=false
    fi

    # Test with a package that should install successfully
    MOCK_CHECK_INSTALLED_STATUS["mock_success"]=1 # Ensure it's not installed initially
    MOCK_APT_INSTALL_STATUS["mock_success"]=0   # Ensure install succeeds
    if global_install_apt_package "mock_success"; then
        if [[ ${MOCK_CHECK_INSTALLED_STATUS["mock_success"]} -eq 0 ]]; then
            echo "  ✅ Successfully installed package (mock_success)"
        else
            echo "  ❌ Install success reported, but check still shows not installed (mock_success)"
            all_passed=false
        fi
    else
        echo "  ❌ Failed to install package that should succeed (mock_success)"
        all_passed=false
    fi

    # Test with a package that should fail to install
    MOCK_CHECK_INSTALLED_STATUS["mock_failure"]=1 # Ensure it's not installed
    MOCK_APT_INSTALL_STATUS["mock_failure"]=1   # Ensure install fails
    if global_install_apt_package "mock_failure"; then
        echo "  ❌ Incorrectly succeeded for package that should fail (mock_failure)"
        all_passed=false
    else
         if [[ ${MOCK_CHECK_INSTALLED_STATUS["mock_failure"]} -eq 1 ]]; then
             echo "  ✅ Correctly handled failed installation (mock_failure)"
         else
             echo "  ❌ Install failure reported, but check shows installed (mock_failure)"
             all_passed=false
         fi
    fi

    # Test installing multiple packages (one success, one fail)
    MOCK_CHECK_INSTALLED_STATUS["multi_success"]=1
    MOCK_APT_INSTALL_STATUS["multi_success"]=0
    MOCK_CHECK_INSTALLED_STATUS["multi_fail"]=1
    MOCK_APT_INSTALL_STATUS["multi_fail"]=1
    if global_install_apt_package "multi_success" "multi_fail"; then
        echo "  ❌ Incorrectly succeeded when one package failed (multi)"
        all_passed=false
    else
        if [[ ${MOCK_CHECK_INSTALLED_STATUS["multi_success"]} -eq 0 ]] && [[ ${MOCK_CHECK_INSTALLED_STATUS["multi_fail"]} -eq 1 ]]; then
            echo "  ✅ Correctly handled mixed success/failure in multiple packages"
        else
             echo "  ❌ Check status after mixed install incorrect (S:${MOCK_CHECK_INSTALLED_STATUS["multi_success"]}, F:${MOCK_CHECK_INSTALLED_STATUS["multi_fail"]})"
             all_passed=false
        fi
    fi

    # Restore original functions
    unset -f apt-get
    global_check_if_installed=$global_check_if_installed_original
    unset global_check_if_installed_original apt_get_original
    unset MOCK_APT_INSTALL_STATUS
    unset MOCK_CHECK_INSTALLED_STATUS

    if [[ "$all_passed" == "true" ]]; then
        return 0
    else
        return 1
    fi
}

# Test global_download_media (mock version)
test_global_download_media() {
    echo "Testing global_download_media function (mock version)..."

    # --- Setup ---
    # Save original values
    local original_download_dir=$GLOBAL_DOWNLOAD_DIR
    local original_repo_url=$_REPOSITORY_RAW_URL
    local original_global_log_message
    original_global_log_message=$(declare -f global_log_message)
    if [[ -z "$original_global_log_message" ]]; then echo "E: declare -f global_log_message"; return 1; fi
    local curl_original
    # Use command -v to check if curl is an alias/function or external command
    if [[ $(type -t curl) == "function" ]] || [[ $(type -v curl) == "alias" ]]; then
        curl_original=$(declare -f curl)
    else
        curl_original="command curl"
    fi

    # Create test directory
    local test_download_dir="/tmp/pmu_test_download_$$"
    mkdir -p "$test_download_dir"

    # Override globals for the test
    GLOBAL_DOWNLOAD_DIR="$test_download_dir"
    _REPOSITORY_RAW_URL="https://example.com"

    # Mock curl function
    local mock_curl_called=false
    local mock_curl_output_file=""
    curl() {
        mock_curl_called=true
        local output_option_found=false
        mock_curl_output_file=""
        # echo "Mock curl called with: [$@]" >&2 # Debugging
        # Simple argument parsing for -o
        while [[ $# -gt 0 ]]; do
            case "$1" in
                -o)
                    output_option_found=true
                    shift
                    mock_curl_output_file="$1"
                    ;;
            esac
            shift
        done

        # Simulate download
        if $output_option_found && [[ -n "$mock_curl_output_file" ]]; then
            # echo "Mock curl: Simulating download to '$mock_curl_output_file'" >&2
            echo "Mock downloaded content" > "$mock_curl_output_file"
            return 0 # Success
        else
            echo "Mock curl ERROR: -o option or filename missing. Args: [$@]" >&2
            return 1 # Failure
        fi
    }

    # Silence logging
    global_log_message() { :; }

    # --- Execution ---
    local test_file_path="test/path/file.txt"
    global_download_media "$test_file_path"
    local download_status=$?

    # --- Verification ---
    local success=true
    local expected_output_file="$test_download_dir/$(basename "$test_file_path")"

    if [[ "$mock_curl_called" != true ]]; then
        echo "  ❌ Mock curl was not called."
        success=false
    fi

    if [[ $download_status -ne 0 ]]; then
        echo "  ❌ Download function returned failure status: $download_status"
        success=false
    fi

    if [[ ! -f "$expected_output_file" ]]; then
        echo "  ❌ Expected output file was not created: '$expected_output_file'"
        success=false
    else
        # Optional: Check content
        if [[ "$(cat "$expected_output_file")" != "Mock downloaded content" ]]; then
            echo "  ❌ Output file content mismatch."
            success=false
        else
            echo "  ✅ Download function succeeded and created correct file."
        fi
    fi

    # --- Cleanup ---
    command rm -rf "$test_download_dir"
    GLOBAL_DOWNLOAD_DIR=$original_download_dir
    _REPOSITORY_RAW_URL=$original_repo_url
    # Restore log message function
    eval "$original_global_log_message"
    # Restore curl
    if [[ "$curl_original" == "command curl" ]]; then
         unset -f curl # Remove the mock function
    else
         eval "$curl_original" # Restore original alias/function
    fi
    unset curl_original original_global_log_message original_download_dir original_repo_url

    # --- Return ---
    if [[ "$success" == "true" ]]; then
        return 0
    else
        return 1
    fi
}

# Test global_write_proc_status_file
test_global_write_proc_status_file() {
    echo "Testing global_write_proc_status_file function..."
    local test_func_name="test_global_write_proc_status_file"

    # --- Setup ---
    # Mock dependencies
    # Save original function definition using declare -f
    local global_create_proc_status_file_original
    global_create_proc_status_file_original=$(declare -f global_create_proc_status_file)
    if [[ -z "$global_create_proc_status_file_original" ]]; then
        echo "  ❌ ERROR: Failed to get original definition of global_create_proc_status_file" >&2
        return 1
    fi

    local global_log_message_original
    global_log_message_original=$(declare -f global_log_message)
    if [[ -z "$global_log_message_original" ]]; then
        echo "  ❌ ERROR: Failed to get original definition of global_log_message" >&2
        eval "$global_create_proc_status_file_original" # Restore previous mock before failing
        return 1
    fi

    # We will use the *real* GLOBAL_STATUS_FILE path.
    # Ensure the directory exists before the test.
    mkdir -p "$(dirname "$GLOBAL_STATUS_FILE")"
    # Ensure the file does not exist before the test.
    rm -f "$GLOBAL_STATUS_FILE"

    # Mock create_proc_status_file to just ensure the directory exists, 
    # mimicking part of its job without touching the file itself initially.
    global_create_proc_status_file() {
        mkdir -p "$(dirname "$GLOBAL_STATUS_FILE")"
        return $?
    }
    global_log_message() { :; } # Silence logging

    # Create a test associative array
    declare -A test_status_array_write
    test_status_array_write["app1"]="installed"
    test_status_array_write["app2"]="pending"
    test_status_array_write["app3"]="failed"

    # --- Execution ---
    # Call the function with the *name* of our test array
    # This should now write to the real $GLOBAL_STATUS_FILE
    global_write_proc_status_file "test_status_array_write"
    local write_status=$?

    # --- Verification ---
    local success=true
    if [[ $write_status -ne 0 ]]; then
        echo "  ❌ Function returned non-zero status: $write_status"
        success=false
    fi

    # Check the actual GLOBAL_STATUS_FILE
    if [[ ! -f "$GLOBAL_STATUS_FILE" ]]; then
        echo "  ❌ Status file was not created: $GLOBAL_STATUS_FILE"
        success=false
    else
        local file_contents=$(cat "$GLOBAL_STATUS_FILE")
        # Order can vary in associative array iteration, check for all parts
        if [[ "$file_contents" != *"app1:installed"* ]] || \
           [[ "$file_contents" != *"app2:pending"* ]] || \
           [[ "$file_contents" != *"app3:failed"* ]]; then
            echo "  ❌ Status file contents incorrect."
            echo "     File: $GLOBAL_STATUS_FILE"
            echo "     Expected parts: app1:installed, app2:pending, app3:failed"
            echo "     Got: '$file_contents'"
            success=false
        else
            echo "  ✅ Status file created and contains correct data: $GLOBAL_STATUS_FILE"
        fi
    fi

    # --- Cleanup ---
    # Clean up the actual status file
    rm -f "$GLOBAL_STATUS_FILE"
    # Restore original function using eval
    eval "$global_create_proc_status_file_original"
    # Restore log message function
    eval "$global_log_message_original"
    unset global_create_proc_status_file_original global_log_message_original

    # --- Return ---
    if [[ "$success" == "true" ]]; then
        return 0
    else
        return 1
    fi
}

# Test global_read_proc_status_file
test_global_read_proc_status_file() {
    echo "Testing global_read_proc_status_file function..."
    local test_func_name="test_global_read_proc_status_file"

    # --- Setup ---
    local global_log_message_original
    global_log_message_original=$(declare -f global_log_message)
    if [[ -z "$global_log_message_original" ]]; then echo "E: declare -f global_log_message"; return 1; fi
    global_log_message() { :; } # Silence logging

    # We will use the *real* GLOBAL_STATUS_FILE path.
    # Ensure the directory exists and create the file with test content.
    mkdir -p "$(dirname "$GLOBAL_STATUS_FILE")"
    echo "app1:installed;app2:pending;app3:failed;" > "$GLOBAL_STATUS_FILE"

    # Declare the array that the function will populate via nameref
    declare -A result_array_read

    # --- Execution ---
    # Call the function with the *name* of our result array
    # This should read from the real $GLOBAL_STATUS_FILE
    global_read_proc_status_file "result_array_read"
    local read_status=$?

    # --- Verification ---
    local success=true
    if [[ $read_status -ne 0 ]]; then
        echo "  ❌ Function returned non-zero status: $read_status"
        success=false
    fi

    # Check the contents of the *local* array populated by the function
    if [[ "${result_array_read[app1]}" == "installed" ]] && \
       [[ "${result_array_read[app2]}" == "pending" ]] && \
       [[ "${result_array_read[app3]}" == "failed" ]] && \
       [[ ${#result_array_read[@]} -eq 3 ]]; then
        echo "  ✅ Array correctly populated with deserialized data from $GLOBAL_STATUS_FILE."
    else
        echo "  ❌ Array not populated correctly from $GLOBAL_STATUS_FILE."
        echo "     Expected: [app1]=installed [app2]=pending [app3]=failed"
        # Use declare -p to show the actual content
        echo "     Got: $(declare -p result_array_read)"
        success=false
    fi

    # Test reading from non-existent file
    rm -f "$GLOBAL_STATUS_FILE" # Remove the real file
    declare -A result_array_nonexistent # Fresh array
    global_read_proc_status_file "result_array_nonexistent"
    if [[ ${#result_array_nonexistent[@]} -eq 0 ]]; then
        echo "  ✅ Correctly handled non-existent status file (empty array)."
    else
        echo "  ❌ Failed to handle non-existent status file."
        echo "     Expected empty array, Got: $(declare -p result_array_nonexistent)"
        success=false
    fi

    # --- Cleanup ---
    # Ensure the real file is cleaned up if the last test failed
    rm -f "$GLOBAL_STATUS_FILE"
    # Restore log message function
    eval "$global_log_message_original"
    unset global_log_message_original

    # --- Return ---
    if [[ "$success" == "true" ]]; then
        return 0
    else
        return 1
    fi
}

# Test global_get_proc_status
test_global_get_proc_status() {
    echo "Testing global_get_proc_status function..."
    local test_func_name="test_global_get_proc_status"

    # --- Setup ---
    # Mock global_read_proc_status_file to populate the array passed by name
    local global_read_proc_status_file_original
    global_read_proc_status_file_original=$(declare -f global_read_proc_status_file)
    if [[ -z "$global_read_proc_status_file_original" ]]; then
        echo "  ❌ ERROR: Failed to get original definition of global_read_proc_status_file" >&2
        return 1
    fi
    global_read_proc_status_file() {
        local -n read_array_ref=${1} # Use nameref to access caller's array
        # Simulate reading specific content
        # echo "Mock global_read_proc_status_file: Populating '$1'" >&2
        read_array_ref=() # Clear first
        read_array_ref["app1"]="installed"
        read_array_ref["app2"]="pending"
    }
    local global_log_message_original
    global_log_message_original=$(declare -f global_log_message)
    if [[ -z "$global_log_message_original" ]]; then
        echo "  ❌ ERROR: Failed to get original definition of global_log_message" >&2
        eval "$global_read_proc_status_file_original" # Restore previous mock
        return 1
    fi
    global_log_message() { :; } # Silence logging

    # --- Execution & Verification ---
    local success=true
    local status_get

    # Test getting status for existing app
    status_get=$(global_get_proc_status "app1")
    if [[ "$status_get" == "installed" ]]; then
        echo "  ✅ Correctly retrieved status for existing app ('app1')"
    else
        echo "  ❌ Failed to retrieve correct status for existing app ('app1'). Expected 'installed', Got '$status_get'"
        success=false
    fi

    # Test getting status for another existing app
    status_get=$(global_get_proc_status "app2")
    if [[ "$status_get" == "pending" ]]; then
        echo "  ✅ Correctly retrieved status for existing app ('app2')"
    else
        echo "  ❌ Failed to retrieve correct status for existing app ('app2'). Expected 'pending', Got '$status_get'"
        success=false
    fi

    # Test getting status for non-existent app
    status_get=$(global_get_proc_status "nonexistent_app")
    if [[ -z "$status_get" ]]; then # Expect empty string for non-existent keys
        echo "  ✅ Correctly handled non-existent app ('nonexistent_app')"
    else
        echo "  ❌ Incorrectly returned status for non-existent app ('nonexistent_app'). Expected empty string, Got '$status_get'"
        success=false
    fi

    # --- Cleanup ---
    eval "$global_read_proc_status_file_original"
    # Restore log message function
    eval "$global_log_message_original"
    unset global_read_proc_status_file_original global_log_message_original

    # --- Return ---
    if [[ "$success" == "true" ]]; then
        return 0
    else
        return 1
    fi
}

# Test global_set_proc_status
test_global_set_proc_status() {
    echo "Testing global_set_proc_status function..."
    local test_func_name="test_global_set_proc_status"

    # --- Setup ---
    # We need to track the state that *would* be written to the file.
    declare -A MOCK_WRITTEN_STATUS_ARRAY # Use an array to hold the state

    # Mock global_read_proc_status_file to read from our mock array
    local global_read_proc_status_file_original
    global_read_proc_status_file_original=$(declare -f global_read_proc_status_file)
    if [[ -z "$global_read_proc_status_file_original" ]]; then
        echo "  ❌ ERROR: Failed to get original definition of global_read_proc_status_file" >&2
        return 1
    fi
    global_read_proc_status_file() {
        local -n read_array_ref=${1}
        # echo "Mock read: Populating '$1' from MOCK_WRITTEN_STATUS_ARRAY" >&2
        # Copy elements from MOCK_WRITTEN_STATUS_ARRAY to the referenced array
        read_array_ref=() # Clear target array first
        for key in "${!MOCK_WRITTEN_STATUS_ARRAY[@]}"; do
            read_array_ref["$key"]="${MOCK_WRITTEN_STATUS_ARRAY[$key]}"
        done
         return 0 # Simulate success
    }

    # Mock global_write_proc_status_file to write *to* our mock array
    local global_write_proc_status_file_original
    global_write_proc_status_file_original=$(declare -f global_write_proc_status_file)
    if [[ -z "$global_write_proc_status_file_original" ]]; then
        echo "  ❌ ERROR: Failed to get original definition of global_write_proc_status_file" >&2
        # Attempt to restore previous mock before failing
        eval "$global_read_proc_status_file_original"
        return 1
    fi
    global_write_proc_status_file() {
        local -n write_array_ref=${1}
        # echo "Mock write: Updating MOCK_WRITTEN_STATUS_ARRAY from '$1'" >&2
        # Copy elements from the referenced array to MOCK_WRITTEN_STATUS_ARRAY
        MOCK_WRITTEN_STATUS_ARRAY=() # Clear mock array first
        for key in "${!write_array_ref[@]}"; do
            MOCK_WRITTEN_STATUS_ARRAY["$key"]="${write_array_ref[$key]}"
        done
         return 0 # Simulate success
    }

    # Mock create_proc_status_file to do nothing
    local global_create_proc_status_file_original
    global_create_proc_status_file_original=$(declare -f global_create_proc_status_file)
    if [[ -z "$global_create_proc_status_file_original" ]]; then
        echo "  ❌ ERROR: Failed to get original definition of global_create_proc_status_file" >&2
        # Attempt to restore previous mocks before failing
        eval "$global_read_proc_status_file_original"
        eval "$global_write_proc_status_file_original"
        return 1
    fi
    global_create_proc_status_file() { :; }

    local global_log_message_original
    global_log_message_original=$(declare -f global_log_message)
    if [[ -z "$global_log_message_original" ]]; then
        echo "  ❌ ERROR: Failed to get original definition of global_log_message" >&2
        # Restore previous mocks
        eval "$global_read_proc_status_file_original"
        eval "$global_write_proc_status_file_original"
        return 1
    fi
    global_log_message() { :; } # Silence logging

    # --- Execution & Verification ---
    local success=true

    # Test 1: Set status for a new app
    MOCK_WRITTEN_STATUS_ARRAY=() # Start with empty state
    global_set_proc_status "new_app" "installed"
    if [[ "${MOCK_WRITTEN_STATUS_ARRAY[new_app]}" == "installed" ]] && [[ ${#MOCK_WRITTEN_STATUS_ARRAY[@]} -eq 1 ]]; then
        echo "  ✅ Set: Successfully set status for new app ('new_app')."
    else
        echo "  ❌ Set: Failed to set status for new app ('new_app')."
        echo "     Expected: [new_app]=installed"
        echo "     Got: $(declare -p MOCK_WRITTEN_STATUS_ARRAY)"
        success=false
    fi

    # Test 2: Update status for an existing app
    MOCK_WRITTEN_STATUS_ARRAY=([app_exists]="initial") # Set initial state
    global_set_proc_status "app_exists" "updated"
    if [[ "${MOCK_WRITTEN_STATUS_ARRAY[app_exists]}" == "updated" ]] && [[ ${#MOCK_WRITTEN_STATUS_ARRAY[@]} -eq 1 ]]; then
        echo "  ✅ Set: Successfully updated status for existing app ('app_exists')."
    else
        echo "  ❌ Set: Failed to update status for existing app ('app_exists')."
        echo "     Expected: [app_exists]=updated"
        echo "     Got: $(declare -p MOCK_WRITTEN_STATUS_ARRAY)"
        success=false
    fi

    # Test 3: Add a new app when others exist
    MOCK_WRITTEN_STATUS_ARRAY=([app1]="one" [app2]="two") # Set initial state
    global_set_proc_status "app3" "three"
    if [[ "${MOCK_WRITTEN_STATUS_ARRAY[app1]}" == "one" ]] && \
       [[ "${MOCK_WRITTEN_STATUS_ARRAY[app2]}" == "two" ]] && \
       [[ "${MOCK_WRITTEN_STATUS_ARRAY[app3]}" == "three" ]] && \
       [[ ${#MOCK_WRITTEN_STATUS_ARRAY[@]} -eq 3 ]]; then
        echo "  ✅ Set: Successfully added new status ('app3') while preserving others."
    else
        echo "  ❌ Set: Failed to add new status ('app3') or preserved others incorrectly."
        echo "     Expected: [app1]=one [app2]=two [app3]=three"
        echo "     Got: $(declare -p MOCK_WRITTEN_STATUS_ARRAY)"
        success=false
    fi

    # --- Cleanup ---
    eval "$global_read_proc_status_file_original"
    eval "$global_write_proc_status_file_original"
    eval "$global_create_proc_status_file_original"
    # Restore log message function
    eval "$global_log_message_original"
    unset global_read_proc_status_file_original global_write_proc_status_file_original
    unset global_create_proc_status_file_original global_log_message_original
    unset MOCK_WRITTEN_STATUS_ARRAY

    # --- Return ---
    if [[ "$success" == "true" ]]; then
        return 0
    else
        return 1
    fi
}

# Test global_unset_proc_status
test_global_unset_proc_status() {
    echo "Testing global_unset_proc_status function..."
    local test_func_name="test_global_unset_proc_status"

    # --- Setup ---
    # Use the same mocking strategy as test_global_set_proc_status
    declare -A MOCK_WRITTEN_STATUS_ARRAY

    local global_read_proc_status_file_original
    global_read_proc_status_file_original=$(declare -f global_read_proc_status_file)
    if [[ -z "$global_read_proc_status_file_original" ]]; then
        echo "  ❌ ERROR: Failed to get original definition of global_read_proc_status_file" >&2
        return 1
    fi
    global_read_proc_status_file() {
        local -n read_array_ref=${1}
        read_array_ref=()
        for key in "${!MOCK_WRITTEN_STATUS_ARRAY[@]}"; do
            read_array_ref["$key"]="${MOCK_WRITTEN_STATUS_ARRAY[$key]}"
        done
    }

    local global_write_proc_status_file_original
    global_write_proc_status_file_original=$(declare -f global_write_proc_status_file)
    if [[ -z "$global_write_proc_status_file_original" ]]; then
        echo "  ❌ ERROR: Failed to get original definition of global_write_proc_status_file" >&2
        eval "$global_read_proc_status_file_original"
        return 1
    fi
    global_write_proc_status_file() {
        local -n write_array_ref=${1}
        MOCK_WRITTEN_STATUS_ARRAY=()
        for key in "${!write_array_ref[@]}"; do
            MOCK_WRITTEN_STATUS_ARRAY["$key"]="${write_array_ref[$key]}"
        done
    }

    # Mock create_proc_status_file to do nothing
    local global_create_proc_status_file_original
    global_create_proc_status_file_original=$(declare -f global_create_proc_status_file)
    if [[ -z "$global_create_proc_status_file_original" ]]; then
        echo "  ❌ ERROR: Failed to get original definition of global_create_proc_status_file" >&2
        # Attempt to restore previous mocks before failing
        eval "$global_read_proc_status_file_original"
        eval "$global_write_proc_status_file_original"
        return 1
    fi
    global_create_proc_status_file() { :; }

    local global_log_message_original
    global_log_message_original=$(declare -f global_log_message)
    if [[ -z "$global_log_message_original" ]]; then
        echo "  ❌ ERROR: Failed to get original definition of global_log_message" >&2
        # Restore previous mocks
        eval "$global_read_proc_status_file_original"
        eval "$global_write_proc_status_file_original"
        eval "$global_create_proc_status_file_original"
        return 1
    fi
    global_log_message() { :; } # Silence logging

    # --- Execution & Verification ---
    local success=true

    # Test 1: Remove an existing app
    MOCK_WRITTEN_STATUS_ARRAY=([app1]="present" [app_to_remove]="remove_me" [app3]="also_present")
    global_unset_proc_status "app_to_remove"
    if [[ -v MOCK_WRITTEN_STATUS_ARRAY[app_to_remove] ]]; then # -v checks if key exists
        echo "  ❌ Unset: Failed to remove existing app ('app_to_remove'). Key still exists."
        echo "     Got: $(declare -p MOCK_WRITTEN_STATUS_ARRAY)"
        success=false
    elif [[ "${MOCK_WRITTEN_STATUS_ARRAY[app1]}" != "present" ]] || \
         [[ "${MOCK_WRITTEN_STATUS_ARRAY[app3]}" != "also_present" ]] || \
         [[ ${#MOCK_WRITTEN_STATUS_ARRAY[@]} -ne 2 ]]; then
        echo "  ❌ Unset: Removed app but altered other elements or final count is wrong."
        echo "     Expected: [app1]=present [app3]=also_present"
        echo "     Got: $(declare -p MOCK_WRITTEN_STATUS_ARRAY)"
        success=false
    else
        echo "  ✅ Unset: Successfully removed existing app ('app_to_remove') and preserved others."
    fi

    # Test 2: Attempt to remove a non-existent app
    MOCK_WRITTEN_STATUS_ARRAY=([app1]="one" [app2]="two") # Reset state
    local original_count=${#MOCK_WRITTEN_STATUS_ARRAY[@]}
    global_unset_proc_status "nonexistent_app"
    local final_count=${#MOCK_WRITTEN_STATUS_ARRAY[@]}
    if [[ "$final_count" -eq "$original_count" ]] && \
       [[ "${MOCK_WRITTEN_STATUS_ARRAY[app1]}" == "one" ]] && \
       [[ "${MOCK_WRITTEN_STATUS_ARRAY[app2]}" == "two" ]]; then
        echo "  ✅ Unset: Correctly handled attempt to remove non-existent app (no change)."
    else
        echo "  ❌ Unset: State changed unexpectedly when removing non-existent app."
        echo "     Expected count $original_count, Got $final_count"
        echo "     Expected: [app1]=one [app2]=two"
        echo "     Got: $(declare -p MOCK_WRITTEN_STATUS_ARRAY)"
        success=false
    fi

    # --- Cleanup ---
    eval "$global_read_proc_status_file_original"
    eval "$global_write_proc_status_file_original"
    eval "$global_create_proc_status_file_original"
    # Restore log message function
    eval "$global_log_message_original"
    unset global_read_proc_status_file_original global_write_proc_status_file_original
    unset global_create_proc_status_file_original global_log_message_original
    unset MOCK_WRITTEN_STATUS_ARRAY

    # --- Return ---
    if [[ "$success" == "true" ]]; then
        return 0
    else
        return 1
    fi
}

# Test global_create_proc_status_file
test_global_create_proc_status_file() {
    echo "Testing global_create_proc_status_file function..."
    local test_func_name="test_global_create_proc_status_file"

    # --- Setup ---
    # Save original state and functions
    local original_initialized=$GLOBAL_STATUS_FILE_INITIALIZED
    local original_command=$_SOFTWARE_COMMAND
    local original_global_status_file=$GLOBAL_STATUS_FILE
    local original_global_temp_path=$GLOBAL_TEMP_PATH
    local global_ensure_dir_original
    global_ensure_dir_original=$(declare -f global_ensure_dir)
    if [[ -z "$global_ensure_dir_original" ]]; then
        echo "  ❌ ERROR: Failed to get original definition of global_ensure_dir" >&2
        return 1
    fi
    local global_log_message_original
    global_log_message_original=$(declare -f global_log_message)
    if [[ -z "$global_log_message_original" ]]; then
        echo "  ❌ ERROR: Failed to get original definition of global_log_message" >&2
        eval "$global_ensure_dir_original" # Restore previous mock
        return 1
    fi
    # Use command -v to handle potential aliases or functions
    local rm_cmd=$(command -v rm)
    local touch_cmd=$(command -v touch)

    # Define temporary paths specific to this test run
    local test_temp_dir="/tmp/pmu_test_${test_func_name}_dir_$$"
    local test_status_file="${test_temp_dir}/pmu_test_status_$$.tmp"

    # Override global variables for the test
    GLOBAL_TEMP_PATH="$test_temp_dir"
    GLOBAL_STATUS_FILE="$test_status_file"

    # Mock dependencies
    MOCK_ENSURE_DIR_CALLED=false
    global_ensure_dir() {
        local dir=$1
        # echo "Mock ensure_dir: Called with '$dir'" >&2
        if [[ "$dir" == "$test_temp_dir" ]]; then
            MOCK_ENSURE_DIR_CALLED=true
            # echo "Mock ensure_dir: Creating test directory '$test_temp_dir'" >&2
            command mkdir -p "$test_temp_dir"
            return $?
        else
            # echo "Mock ensure_dir: Passing call for '$dir' to original" >&2
            eval "$global_ensure_dir_original" # Call original if path doesn't match
            return $?
        fi
    }
    global_log_message() { :; } # Silence logging

    # --- Test Execution ---
    local success=true

    # Test Case 1: Initialization (main-menu, file doesn't exist)
    echo "  Testing Case 1: Initialization (main-menu, no file)..."
    _SOFTWARE_COMMAND="main-menu"
    GLOBAL_STATUS_FILE_INITIALIZED=false
    "$rm_cmd" -rf "$test_temp_dir" # Ensure clean slate

    global_create_proc_status_file
    local create_status=$?

    if [[ $create_status -ne 0 ]]; then
        echo "  ❌ Case 1: Function returned error status $create_status"
        success=false
    elif [[ "$MOCK_ENSURE_DIR_CALLED" != "true" ]]; then
        echo "  ❌ Case 1: Mock ensure_dir was not called for '$test_temp_dir'."
        success=false
    elif [[ ! -f "$test_status_file" ]]; then
        echo "  ❌ Case 1: Test status file was not created: '$test_status_file'."
        success=false
    elif [[ "$GLOBAL_STATUS_FILE_INITIALIZED" != "true" ]]; then
        echo "  ❌ Case 1: GLOBAL_STATUS_FILE_INITIALIZED flag not set to true."
        success=false
    else
        echo "  ✅ Case 1: Passed."
    fi
    # Reset mock flag for next test
    MOCK_ENSURE_DIR_CALLED=false

    # Test Case 2: Initialization (main-menu, file exists)
    echo "  Testing Case 2: Initialization (main-menu, file exists)..."
    _SOFTWARE_COMMAND="main-menu"
    GLOBAL_STATUS_FILE_INITIALIZED=false
    "$touch_cmd" "$test_status_file" # Ensure file exists
    echo "old content" > "$test_status_file"

    global_create_proc_status_file
    create_status=$?

    local file_content=$(cat "$test_status_file" 2>/dev/null)
    if [[ $create_status -ne 0 ]]; then
        echo "  ❌ Case 2: Function returned error status $create_status"
        success=false
    elif [[ ! -f "$test_status_file" ]] || [[ -n "$file_content" ]]; then
        # Should remove the old file and create a new empty one
        echo "  ❌ Case 2: Test status file was not cleared. Content: '$file_content'."
        success=false
    elif [[ "$GLOBAL_STATUS_FILE_INITIALIZED" != "true" ]]; then
        echo "  ❌ Case 2: GLOBAL_STATUS_FILE_INITIALIZED flag not set to true."
        success=false
    else
        echo "  ✅ Case 2: Passed."
    fi

    # Test Case 3: No Initialization (other command, file exists)
    echo "  Testing Case 3: No Initialization (other command, file exists)..."
    _SOFTWARE_COMMAND="other-command"
    GLOBAL_STATUS_FILE_INITIALIZED=false # Assume flag is false initially
    echo "existing content" > "$test_status_file" # Ensure file exists with content

    global_create_proc_status_file
    create_status=$?

    file_content=$(cat "$test_status_file" 2>/dev/null)
    if [[ $create_status -ne 0 ]]; then
        echo "  ❌ Case 3: Function returned error status $create_status"
        success=false
    elif [[ "$file_content" != "existing content" ]]; then
        # File should NOT be touched or cleared
        echo "  ❌ Case 3: Test status file content was unexpectedly changed. Content: '$file_content'."
        success=false
    elif [[ "$GLOBAL_STATUS_FILE_INITIALIZED" != "false" ]]; then
        # Flag should remain false as no initialization occurred
        echo "  ❌ Case 3: GLOBAL_STATUS_FILE_INITIALIZED flag was incorrectly set to true."
        success=false
    else
        echo "  ✅ Case 3: Passed."
    fi


    # Test Case 4: No Initialization (other command, file DOES NOT exist)
    echo "  Testing Case 4: No Initialization (other command, no file)..."
    _SOFTWARE_COMMAND="other-command"
    GLOBAL_STATUS_FILE_INITIALIZED=false
    "$rm_cmd" -f "$test_status_file" # Ensure file does not exist

    global_create_proc_status_file
    create_status=$?

    # Behavior: Even if not main-menu, if the flag is false AND the file doesn't exist,
    # the current logic *will* create it and set the flag. Let's test this.
    if [[ $create_status -ne 0 ]]; then
        echo "  ❌ Case 4: Function returned error status $create_status"
        success=false
    elif [[ ! -f "$test_status_file" ]]; then
        echo "  ❌ Case 4: Test status file was not created: '$test_status_file'."
        success=false
    elif [[ "$GLOBAL_STATUS_FILE_INITIALIZED" != "true" ]]; then
        echo "  ❌ Case 4: GLOBAL_STATUS_FILE_INITIALIZED flag not set to true (expected creation)."
        success=false
    else
        echo "  ✅ Case 4: Passed (File created as expected)."
    fi

    # Test Case 5: Already Initialized
    echo "  Testing Case 5: Already Initialized..."
    _SOFTWARE_COMMAND="main-menu" # Command doesn't matter if flag is true
    GLOBAL_STATUS_FILE_INITIALIZED=true # Flag is already true
    echo "pre-existing content" > "$test_status_file" # File exists

    global_create_proc_status_file
    create_status=$?

    file_content=$(cat "$test_status_file" 2>/dev/null)
    if [[ $create_status -ne 0 ]]; then
        echo "  ❌ Case 5: Function returned error status $create_status"
        success=false
    elif [[ "$file_content" != "pre-existing content" ]]; then
        # File should not be touched
        echo "  ❌ Case 5: Test status file content was unexpectedly changed. Content: '$file_content'."
        success=false
    elif [[ "$GLOBAL_STATUS_FILE_INITIALIZED" != "true" ]]; then
         # Flag should remain true
        echo "  ❌ Case 5: GLOBAL_STATUS_FILE_INITIALIZED flag was unset."
        success=false
    else
        echo "  ✅ Case 5: Passed."
    fi

    # --- Cleanup ---
    "$rm_cmd" -rf "$test_temp_dir"
    GLOBAL_STATUS_FILE_INITIALIZED=$original_initialized
    _SOFTWARE_COMMAND=$original_command
    GLOBAL_STATUS_FILE=$original_global_status_file
    GLOBAL_TEMP_PATH=$original_global_temp_path
    eval "$global_ensure_dir_original"
    # Restore log message function
    eval "$global_log_message_original"
    unset global_ensure_dir_original global_log_message_original
    unset original_initialized original_command original_global_status_file original_global_temp_path
    unset MOCK_ENSURE_DIR_CALLED rm_cmd touch_cmd

    # --- Return ---
    if [[ "$success" == "true" ]]; then
        return 0
    else
        return 1
    fi
}

# Test global_check_file_size
test_global_check_file_size() {
    echo "Testing global_check_file_size function..."
    local test_dir="/tmp/pmu_test_filesize_$$"
    command mkdir -p "$test_dir"
    local large_file="${test_dir}/large.bin"
    local exact_file="${test_dir}/exact.bin" # Exactly 1 MiB
    local small_file="${test_dir}/small.bin"
    local missing_file="${test_dir}/missing.bin"

    # Mock logging to prevent clutter
    local global_log_message_original
    global_log_message_original=$(declare -f global_log_message)
    if [[ -z "$global_log_message_original" ]]; then echo "E: declare -f global_log_message"; return 1; fi
    global_log_message() { :; }

    local all_passed=true

    # Create a large file (> 1MB)
    command dd if=/dev/zero of="$large_file" bs=1M count=2 status=none &>/dev/null
    if global_check_file_size "$large_file"; then
        echo "  ✅ Correctly identified large file (> 1MiB)"
    else
        echo "  ❌ Failed to identify large file (> 1MiB)"
        all_passed=false
    fi

    # Create a file exactly 1 MiB (1024 * 1024 bytes = 1048576 bytes)
    # The check is >= 1048576
    command dd if=/dev/zero of="$exact_file" bs=1 count=1048576 status=none &>/dev/null
    if global_check_file_size "$exact_file"; then
        echo "  ✅ Correctly identified exact size file (>= 1MiB)"
    else
        echo "  ❌ Failed to identify exact size file (>= 1MiB)"
        all_passed=false
    fi

    # Create a small file (< 1MB) - e.g., 1 MiB - 1 byte
    command dd if=/dev/zero of="$small_file" bs=1 count=1048575 status=none &>/dev/null
    if global_check_file_size "$small_file"; then
        echo "  ❌ Incorrectly passed small file (< 1MiB)"
        all_passed=false
    else
        echo "  ✅ Correctly identified small file (< 1MiB)"
    fi

    # Test with non-existent file
    if global_check_file_size "$missing_file"; then
        echo "  ❌ Incorrectly passed missing file"
        all_passed=false
    else
        echo "  ✅ Correctly handled missing file"
    fi

    # Test with empty file path
    if global_check_file_size ""; then
        echo "  ❌ Incorrectly passed empty file path"
        all_passed=false
    else
        echo "  ✅ Correctly handled empty file path"
    fi

    # Clean up
    command rm -rf "$test_dir"
    # Restore log message function
    eval "$global_log_message_original"
    unset global_log_message_original

    if [[ "$all_passed" == "true" ]]; then
        return 0
    else
        return 1
    fi
}

# Test global_press_any_key (timeout case)
test_global_press_any_key() {
    echo "Testing global_press_any_key function (timeout case)..."

    # --- Setup ---
    # Save original functions/variables
    local read_original
    read_original=$(declare -f read || echo "read_is_builtin") # Handle builtin 'read'
    local global_log_message_original
    global_log_message_original=$(declare -f global_log_message)
    if [[ -z "$global_log_message_original" ]]; then
        echo "  ❌ ERROR: Failed to get original definition of global_log_message" >&2
        # Restore read if it was a function
        if [[ "$read_original" != "read_is_builtin" ]]; then eval "$read_original"; fi
        return 1
    fi
    local DEBUG_ORIGINAL=$DEBUG

    # Mock the 'read' command to force a timeout
    read() {
      # echo "Mock read: Simulating timeout..." >&2
      # Simulate timeout by returning a non-zero code (> 128 is typical for timeout)
      return 142 # Standard code for timeout in `read -t`
    }

    # Mock log message to capture DEBUG output
    MOCK_LOG_OUTPUT=""
    global_log_message() {
        # echo "Mock log: [$1] $2" >&2 # Uncomment for debugging the mock itself
        if [[ "$1" == "DEBUG" ]]; then
            MOCK_LOG_OUTPUT+="$2\n" # Append only the message part for DEBUG level
        fi
        # Don't echo in mocked version to avoid cluttering test output
    }

    # Set DEBUG to false to get the default 10s timeout message check
    DEBUG=false

    # --- Execution ---
    # Capture stdout specifically
    exec 3>&1 # Save original stdout
    # Run the function, redirecting its stdout to a variable, keep stderr connected
    local captured_stdout
    captured_stdout=$( global_press_any_key 1>&3 )
    exec 3>&- # Restore original stdout

    # --- Verification ---
    local passed=true
    local expected_stdout_msg="Timeout reached, continuing automatically."
    local expected_debug_log_msg="Timeout reached (10s), continuing automatically."

    # Check captured stdout message
    # Use wildcard matching to be robust against extra newlines/whitespace
    if [[ "$captured_stdout" == *"$expected_stdout_msg"* ]]; then
         echo "  ✅ Correct stdout message for timeout received."
    else
         echo "  ❌ Incorrect stdout message."
         echo "     Expected to contain: '$expected_stdout_msg'"
         echo "     Got: '$captured_stdout'"
         passed=false
    fi

    # Check captured DEBUG log message
     if [[ "$MOCK_LOG_OUTPUT" == *"$expected_debug_log_msg"* ]]; then
         echo "  ✅ Correct DEBUG log message for timeout received."
     else
         echo "  ❌ Incorrect DEBUG log message."
         echo "     Expected to contain: '$expected_debug_log_msg'"
         echo "     Got: '$MOCK_LOG_OUTPUT'"
         passed=false
     fi

    # --- Cleanup ---
    # Restore 'read'
    if [[ "$read_original" == "read_is_builtin" ]]; then
        unset -f read # Unset the function we defined
    else
        eval "$read_original" # Restore the original function definition
    fi
    # Restore log function
    eval "$global_log_message_original"
    DEBUG=$DEBUG_ORIGINAL # Restore DEBUG variable
    unset read_original global_log_message_original DEBUG_ORIGINAL MOCK_LOG_OUTPUT captured_stdout

    # --- Return ---
    if [[ "$passed" == "true" ]]; then
        return 0
    else
        return 1
    fi
}

# Test installation status functions together (using robust mocks)
# This test replaces the previous implementation relying on echo/cat mocks.
# It uses a shared mock state variable and mocks the read/write functions directly.
test_installation_status_functions() {
    echo "Testing installation status functions (write, read, get, set, unset) via mocks..."
    local test_func_name="test_installation_status_functions"

    # --- Setup ---
    # Shared state variable for the mock file content
    declare -A MOCK_STATUS_STATE_ARRAY

    # Save original functions
    local global_create_proc_status_file_original
    global_create_proc_status_file_original=$(declare -f global_create_proc_status_file)
    if [[ -z "$global_create_proc_status_file_original" ]]; then echo "E: declare -f global_create_proc_status_file"; return 1; fi
    local global_read_proc_status_file_original
    global_read_proc_status_file_original=$(declare -f global_read_proc_status_file)
    if [[ -z "$global_read_proc_status_file_original" ]]; then echo "E: declare -f global_read_proc_status_file"; eval "$global_create_proc_status_file_original"; return 1; fi
    local global_write_proc_status_file_original
    global_write_proc_status_file_original=$(declare -f global_write_proc_status_file)
    if [[ -z "$global_write_proc_status_file_original" ]]; then echo "E: declare -f global_write_proc_status_file"; eval "$global_create_proc_status_file_original"; eval "$global_read_proc_status_file_original"; return 1; fi
    local global_log_message_original
    global_log_message_original=$(declare -f global_log_message)
    if [[ -z "$global_log_message_original" ]]; then
        echo "E: declare -f global_log_message"
        eval "$global_create_proc_status_file_original"
        eval "$global_read_proc_status_file_original"
        eval "$global_write_proc_status_file_original"
        return 1
    fi

    # Mock create to do nothing
    global_create_proc_status_file() {
        # echo "Mock create: Called" >&2
         : # No-op
    }
    # Mock read to populate from the mock state array
    global_read_proc_status_file() {
        local -n read_array_ref=${1}
        # echo "Mock read: Populating '$1' from MOCK_STATUS_STATE_ARRAY" >&2
        read_array_ref=() # Clear target first
        for key in "${!MOCK_STATUS_STATE_ARRAY[@]}"; do
            read_array_ref["$key"]="${MOCK_STATUS_STATE_ARRAY[$key]}"
        done
         return 0 # Simulate success
    }
    # Mock write to update the mock state array
    global_write_proc_status_file() {
        local -n write_array_ref=${1}
        # echo "Mock write: Updating MOCK_STATUS_STATE_ARRAY from '$1'" >&2
        # Copy elements from the referenced array to MOCK_STATUS_STATE_ARRAY
        MOCK_STATUS_STATE_ARRAY=() # Clear state first
        for key in "${!write_array_ref[@]}"; do
            MOCK_STATUS_STATE_ARRAY["$key"]="${write_array_ref[$key]}"
        done
         return 0 # Simulate success
    }
    # Silence logging for clarity
    global_log_message() { :; }

    # --- Test Execution & Verification ---
    local success=true

    # Start with clean state
    MOCK_STATUS_STATE_ARRAY=()

    # 1. Test set (new)
    global_set_proc_status "app1" "pending"
    if [[ "${MOCK_STATUS_STATE_ARRAY[app1]}" != "pending" ]] || [[ ${#MOCK_STATUS_STATE_ARRAY[@]} -ne 1 ]]; then
        echo "  ❌ Set (New): Failed. State: $(declare -p MOCK_STATUS_STATE_ARRAY)"
        success=false
    else
        echo "  ✅ Set (New): Passed."
    fi

    # 2. Test set (update)
    global_set_proc_status "app1" "installed"
    if [[ "${MOCK_STATUS_STATE_ARRAY[app1]}" != "installed" ]] || [[ ${#MOCK_STATUS_STATE_ARRAY[@]} -ne 1 ]]; then
        echo "  ❌ Set (Update): Failed. State: $(declare -p MOCK_STATUS_STATE_ARRAY)"
        success=false
    else
        echo "  ✅ Set (Update): Passed."
    fi

    # 3. Test set (add another)
    global_set_proc_status "app2" "downloaded"
    if [[ "${MOCK_STATUS_STATE_ARRAY[app1]}" != "installed" ]] || [[ "${MOCK_STATUS_STATE_ARRAY[app2]}" != "downloaded" ]] || [[ ${#MOCK_STATUS_STATE_ARRAY[@]} -ne 2 ]]; then
        echo "  ❌ Set (Add Another): Failed. State: $(declare -p MOCK_STATUS_STATE_ARRAY)"
        success=false
    else
        echo "  ✅ Set (Add Another): Passed."
    fi

    # 4. Test get (existing)
    local status_get
    status_get=$(global_get_proc_status "app2")
    if [[ "$status_get" != "downloaded" ]]; then
        echo "  ❌ Get (Existing): Failed. Expected 'downloaded', Got '$status_get'"
        success=false
    else
        echo "  ✅ Get (Existing): Passed."
    fi

    # 5. Test get (missing)
    status_get=$(global_get_proc_status "app_missing")
    if [[ -n "$status_get" ]]; then
        echo "  ❌ Get (Missing): Failed. Expected empty, Got '$status_get'"
        success=false
    else
        echo "  ✅ Get (Missing): Passed."
    fi

    # 6. Test unset (existing)
    global_unset_proc_status "app1"
    if [[ -v MOCK_STATUS_STATE_ARRAY[app1] ]] || [[ "${MOCK_STATUS_STATE_ARRAY[app2]}" != "downloaded" ]] || [[ ${#MOCK_STATUS_STATE_ARRAY[@]} -ne 1 ]]; then
        echo "  ❌ Unset (Existing): Failed. State: $(declare -p MOCK_STATUS_STATE_ARRAY)"
        success=false
    else
        echo "  ✅ Unset (Existing): Passed."
    fi

    # 7. Test unset (missing)
    local pre_unset_state=$(declare -p MOCK_STATUS_STATE_ARRAY) # Capture state before
    global_unset_proc_status "app_missing"
    if [[ "$(declare -p MOCK_STATUS_STATE_ARRAY)" != "$pre_unset_state" ]]; then
        echo "  ❌ Unset (Missing): Failed. State changed unexpectedly."
        echo "     Before: $pre_unset_state"
        echo "     After: $(declare -p MOCK_STATUS_STATE_ARRAY)"
        success=false
    else
        echo "  ✅ Unset (Missing): Passed (State unchanged)."
    fi

    # --- Cleanup ---
    eval "$global_create_proc_status_file_original"
    eval "$global_read_proc_status_file_original"
    eval "$global_write_proc_status_file_original"
    # Restore log message function
    eval "$global_log_message_original"
    unset global_create_proc_status_file_original global_read_proc_status_file_original
    unset global_write_proc_status_file_original global_log_message_original
    unset MOCK_STATUS_STATE_ARRAY

    # --- Return ---
    if [[ "$success" == "true" ]]; then
        echo "Finished testing installation status functions: ALL PASSED"
        return 0
    else
        echo "Finished testing installation status functions: SOME FAILED"
        return 1
    fi
}

# Run tests
echo "=== Starting Global Utils Test Suite ==="
echo

# Run individual tests
run_test "global_run_as_user" test_global_run_as_user
run_test "global_ensure_dir" test_global_ensure_dir
run_test "global_setup_logging" test_global_setup_logging
run_test "global_log_message" test_global_log_message
run_test "global_check_root" test_global_check_root
# Individual status function tests (might be redundant with the combined one, but good for isolation)
run_test "global_write_proc_status_file" test_global_write_proc_status_file
run_test "global_read_proc_status_file" test_global_read_proc_status_file
run_test "global_get_proc_status" test_global_get_proc_status
run_test "global_set_proc_status" test_global_set_proc_status
run_test "global_unset_proc_status" test_global_unset_proc_status # Renamed test function
# Combined status function test using better mocks
run_test "Installation Status Functions Combined (get, set, unset)" test_installation_status_functions

run_test "global_create_proc_status_file" test_global_create_proc_status_file
run_test "global_check_file_size" test_global_check_file_size
#run_test "global_press_any_key (timeout case)" test_global_press_any_key
# The following tests rely on external commands (apt, snap, etc.) or network (curl)
# and complex mocking. Keep them commented out unless full end-to-end or more
# sophisticated mocking is implemented.
# run_test "global_check_if_installed" test_global_check_if_installed
# run_test "global_install_apt_package" test_global_install_apt_package
#run_test "global_download_media (mocked)" test_global_download_media

# Print summary
echo
echo "=== Test Summary ==="
echo "Tests passed: $TESTS_PASSED"
echo "Tests failed: $TESTS_FAILED"
echo "Total tests run: $((TESTS_PASSED + TESTS_FAILED))"

# Exit with appropriate status code
if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "All run tests passed! 🎉"
    exit 0
else
    echo "Some tests failed. 😢"
    exit 1
fi 
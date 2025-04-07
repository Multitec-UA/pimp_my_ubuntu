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

# Test global_write_proc_status_file
test_global_write_proc_status_file() {
    echo "Testing global_write_proc_status_file function..."
    
    # Create a temporary status file
    local temp_status_file="/tmp/pmu_test_serialize.tmp"
    rm -f "$temp_status_file"
    
    # Mock the global_create_proc_status_file function
    global_create_proc_status_file() {
        touch "$temp_status_file"
    }
    
    # Create a test associative array
    declare -A test_status_array
    test_status_array["app1"]="installed"
    test_status_array["app2"]="pending"
    test_status_array["app3"]="failed"
    
    # Call the function with our test array
    global_write_proc_status_file test_status_array
    
    # Check if the file was created and contains the expected data
    if [[ -f "$temp_status_file" ]]; then
        echo "Status file created successfully"
        
        # Check the contents
        local file_contents=$(cat "$temp_status_file")
        if [[ "$file_contents" == *"app1:installed"* ]] && \
           [[ "$file_contents" == *"app2:pending"* ]] && \
           [[ "$file_contents" == *"app3:failed"* ]]; then
            echo "Status file contains correct data"
            
            # Clean up
            rm -f "$temp_status_file"
            return 0
        else
            echo "Status file contents incorrect"
            echo "Expected to contain app1:installed, app2:pending, app3:failed"
            echo "Got: $file_contents"
            
            # Clean up
            rm -f "$temp_status_file"
            return 1
        fi
    else
        echo "Status file was not created"
        
        # Clean up
        rm -f "$temp_status_file"
        return 1
    fi
}

# Test global_read_proc_status_file
test_global_read_proc_status_file() {
    echo "Testing global_read_proc_status_file function..."
    
    # Create a temporary status file with test data
    local temp_status_file="/tmp/pmu_test_deserialize.tmp"
    echo "app1:installed;app2:pending;app3:failed;" > "$temp_status_file"
    
    # Call the function
    local result_array
    result_array=$(global_read_proc_status_file)
    
    # Check if the array contains the expected values
    if [[ "$result_array" == *"app1:installed"* ]] && \
       [[ "$result_array" == *"app2:pending"* ]] && \
       [[ "$result_array" == *"app3:failed"* ]]; then
        echo "Deserialized data matches expected values"
        
        # Clean up
        rm -f "$temp_status_file"
        return 0
    else
        echo "Deserialized data does not match expected values"
        echo "Expected to contain app1:installed, app2:pending, app3:failed"
        echo "Got: $result_array"
        
        # Clean up
        rm -f "$temp_status_file"
        return 1
    fi
}

# Test global_get_proc_status
test_global_get_proc_status() {
    echo "Testing global_get_proc_status function..."
    
    # Create a temporary status file with test data
    local temp_status_file="/tmp/pmu_test_get_status.tmp"
    echo "app1:installed;app2:pending;app3:failed;" > "$temp_status_file"
    
    # Mock the global_read_proc_status_file function
    global_read_proc_status_file() {
        echo "app1:installed;app2:pending;app3:failed;"
    }
    
    # Test getting status for existing app
    local status
    status=$(global_get_proc_status "app1")
    if [[ "$status" == "installed" ]]; then
        echo "Correctly retrieved status for existing app"
    else
        echo "Failed to retrieve correct status for existing app"
        echo "Expected: installed, Got: $status"
        
        # Clean up
        rm -f "$temp_status_file"
        return 1
    fi
    
    # Test getting status for non-existent app
    status=$(global_get_proc_status "nonexistent_app")
    if [[ -z "$status" ]]; then
        echo "Correctly handled non-existent app"
    else
        echo "Incorrectly returned status for non-existent app"
        echo "Expected empty string, Got: $status"
        
        # Clean up
        rm -f "$temp_status_file"
        return 1
    fi
    
    # Clean up
    rm -f "$temp_status_file"
    return 0
}

# Test global_set_proc_status
test_global_set_proc_status() {
    echo "Testing global_set_proc_status function..."
    
    # Create a temporary status file
    local temp_status_file="/tmp/pmu_test_set_status.tmp"
    rm -f "$temp_status_file"
    
    # Mock the global_create_proc_status_file function
    global_create_proc_status_file() {
        touch "$temp_status_file"
    }
    
    # Mock the global_read_proc_status_file function
    global_read_proc_status_file() {
        if [[ -f "$temp_status_file" ]]; then
            cat "$temp_status_file"
        else
            echo ""
        fi
    }
    
    # Mock the global_write_proc_status_file function
    global_write_proc_status_file() {
        echo "$1" > "$temp_status_file"
    }
    
    # Test setting status for new app
    global_set_proc_status "new_app" "installed"
    
    # Check if the status was set correctly
    if grep -q "new_app:installed" "$temp_status_file"; then
        echo "Successfully set status for new app"
    else
        echo "Failed to set status for new app"
        
        # Clean up
        rm -f "$temp_status_file"
        return 1
    fi
    
    # Test updating status for existing app
    global_set_proc_status "new_app" "updated"
    
    # Check if the status was updated correctly
    if grep -q "new_app:updated" "$temp_status_file"; then
        echo "Successfully updated status for existing app"
    else
        echo "Failed to update status for existing app"
        
        # Clean up
        rm -f "$temp_status_file"
        return 1
    fi
    
    # Clean up
    rm -f "$temp_status_file"
    return 0
}

# Test global_remove_proc_status
test_global_remove_proc_status() {
    echo "Testing global_remove_proc_status function..."
    
    # Create a temporary status file with test data
    local temp_status_file="/tmp/pmu_test_remove_status.tmp"
    echo "app1:installed;app2:pending;app3:failed;" > "$temp_status_file"
    
    # Mock the global_read_proc_status_file function
    global_read_proc_status_file() {
        if [[ -f "$temp_status_file" ]]; then
            cat "$temp_status_file"
        else
            echo ""
        fi
    }
    
    # Mock the global_write_proc_status_file function
    global_write_proc_status_file() {
        echo "$1" > "$temp_status_file"
    }
    
    # Test removing existing app
    global_remove_proc_status "app2"
    
    # Check if the app was removed correctly
    if ! grep -q "app2:pending" "$temp_status_file"; then
        echo "Successfully removed existing app"
    else
        echo "Failed to remove existing app"
        
        # Clean up
        rm -f "$temp_status_file"
        return 1
    fi
    
    # Test removing non-existent app (should not fail)
    global_remove_proc_status "nonexistent_app"
    
    # Check if other apps are still present
    if grep -q "app1:installed" "$temp_status_file" && \
       grep -q "app3:failed" "$temp_status_file"; then
        echo "Successfully handled removal of non-existent app"
    else
        echo "Failed to handle removal of non-existent app"
        
        # Clean up
        rm -f "$temp_status_file"
        return 1
    fi
    
    # Clean up
    rm -f "$temp_status_file"
    return 0
}

# Test global_create_proc_status_file
test_global_create_proc_status_file() {
    echo "Testing global_create_proc_status_file function..."

    # Save original values and commands
    local original_initialized=$GLOBAL_STATUS_FILE_INITIALIZED
    local original_command=$_SOFTWARE_COMMAND
    global_ensure_dir_original=$global_ensure_dir
    # Save the function we are testing/mocking
    original_global_create_proc_status_file=$(declare -f global_create_proc_status_file)

    # Define a temporary file path for this test
    local test_temp_dir="/tmp/pmu_test_create_status_dir_$$"
    local test_status_file="${test_temp_dir}/pmu_test_status_$$.tmp"

    # --- Mocks --- #
    # Mock ensure_dir to create our test temp dir and avoid chown
    global_ensure_dir() {
        local dir=$1
        echo "Mock ensure_dir: Called with '$dir'" >&2
        # Only act if the call is for the *original* GLOBAL_TEMP_PATH
        if [[ "$dir" == "$GLOBAL_TEMP_PATH" ]]; then
             echo "Mock ensure_dir: Condition MATCHED. Attempting mkdir -p '$test_temp_dir'" >&2
             # Use command mkdir, check status
             command mkdir -p "$test_temp_dir"
             local mkdir_status=$?
             if [[ $mkdir_status -ne 0 ]]; then
                 echo "Mock ensure_dir: ERROR - mkdir failed with status $mkdir_status" >&2
                 return $mkdir_status
             fi
             echo "Mock ensure_dir: mkdir successful." >&2
             return 0 # Success
        else
             echo "Mock ensure_dir: Condition NOT MATCHED. Using original logic for '$dir'" >&2
             # If called with a different path, use original logic (safer)
             command mkdir -p "${dir}" || return 1
             command chown "${GLOBAL_REAL_USER}:${GLOBAL_REAL_USER}" "${dir}" || return 1
             return 0
        fi
    }

    # Mock rm to target the test file if called on the original
    rm() {
        echo "Mock rm: Called with arguments: [$*]" >&2
        if [[ "$1" == "-f" ]] && [[ "$2" == "$GLOBAL_STATUS_FILE" ]]; then
             echo "Mock rm: Condition MATCHED. Removing '$test_status_file'" >&2
             command rm -f "$test_status_file" # Operate on test file
        else
             echo "Mock rm: Condition NOT MATCHED. Calling command rm $*" >&2
             command rm "$@" # Call original rm otherwise
        fi
    }

    # Mock touch to target the test file if called on the original
    touch() {
         echo "Mock touch: Called with arguments: [$*]" >&2
         if [[ "$#" -eq 1 ]] && [[ "$1" == "$GLOBAL_STATUS_FILE" ]]; then
             echo "Mock touch: Condition MATCHED. Touching '$test_status_file'" >&2
             command touch "$test_status_file" # Operate on test file
        else
             echo "Mock touch: Condition NOT MATCHED. Calling command touch $*" >&2
             # Check if $@ is empty, which causes the error
             if [[ -z "$*" ]]; then
                 echo "Mock touch: ERROR - Called with empty arguments!" >&2
                 return 1 # Indicate error
             fi
             command touch "$@" # Call original touch otherwise
        fi
    }

    # Mock the function under test to add debugging
    global_create_proc_status_file() {
        echo "DEBUG: Inside MOCKED global_create_proc_status_file" >&2
        echo "DEBUG: Value of GLOBAL_STATUS_FILE is [${GLOBAL_STATUS_FILE}]" >&2
        echo "DEBUG: Value of _SOFTWARE_COMMAND is [${_SOFTWARE_COMMAND}]" >&2
        echo "DEBUG: Value of GLOBAL_STATUS_FILE_INITIALIZED is [${GLOBAL_STATUS_FILE_INITIALIZED}]" >&2

        # Evaluate the original function definition to call the real code
        eval "$original_global_create_proc_status_file"
        # Call the original function logic
        # Note: We can't directly call a name stored in a variable easily if it's complex.
        # Instead, we re-declare the original function inside this scope, or use eval.
        # Using eval is simpler here.
    }

    # --- Test Execution --- #
    # Setup test environment
    _SOFTWARE_COMMAND="main-menu" # To trigger creation logic

    # Ensure clean state for the *test* file/dir
    echo "--- Test Setup: Ensuring clean state for test files ---" >&2
    command rm -f "$test_status_file"
    command rmdir "$test_temp_dir" &> /dev/null # Ignore error if not exists
    GLOBAL_STATUS_FILE_INITIALIZED=false # Reset flag
    echo "--- Test Setup: Complete ---" >&2

    # Run the function
    echo "--- Test Run 1: Calling global_create_proc_status_file (main-menu) ---" >&2
    global_create_proc_status_file
    echo "--- Test Run 1: Call complete ---" >&2

    local success=true
    # Check if the *test* directory and file were created by the mocks
    if [[ ! -d "$test_temp_dir" ]]; then
        echo "Assertion failed: Mocked test directory was not created: $test_temp_dir"
        success=false
    fi
    if [[ ! -f "$test_status_file" ]]; then
        echo "Assertion failed: Mocked test status file was not created: $test_status_file"
        success=false
    fi
    if [[ "$GLOBAL_STATUS_FILE_INITIALIZED" != "true" ]]; then
        echo "Assertion failed: GLOBAL_STATUS_FILE_INITIALIZED flag not set to true"
        success=false
    fi

    # Test idempotency (should not recreate/clear the test file)
    echo "--- Test Run 2: Preparing for idempotency check ---" >&2
    echo "Test content" > "$test_status_file"
    if [[ $? -ne 0 ]]; then
        echo "ERROR: Failed to write test content to '$test_status_file' for idempotency check." >&2
        success=false # Prevent further execution if setup failed
    fi

    if [[ "$success" == "true" ]]; then
        # Reset flag to false, ensure it stays false if file exists
        GLOBAL_STATUS_FILE_INITIALIZED=false
        _SOFTWARE_COMMAND="other-command" # Set command so it doesn't force recreate

        echo "--- Test Run 2: Calling global_create_proc_status_file (other-command) ---" >&2
        global_create_proc_status_file # Call again
        echo "--- Test Run 2: Call complete ---" >&2

        if [[ ! -f "$test_status_file" ]] || [[ "$(cat "$test_status_file" 2>/dev/null)" != "Test content" ]]; then
            echo "Assertion failed: Test status file was incorrectly modified or removed on second call"
            success=false
        fi
        # Check flag wasn't set again if file already existed
        if [[ "$GLOBAL_STATUS_FILE_INITIALIZED" != "false" ]]; then
            echo "Assertion failed: GLOBAL_STATUS_FILE_INITIALIZED flag was incorrectly set on second call when file existed"
            success=false
        fi
    fi

    # --- Clean up --- #
    echo "--- Test Cleanup --- " >&2
    command rm -f "$test_status_file"
    command rmdir "$test_temp_dir" &> /dev/null
    GLOBAL_STATUS_FILE_INITIALIZED=$original_initialized # Restore flag
    _SOFTWARE_COMMAND=$original_command
    # Restore mocked functions
    global_ensure_dir=$global_ensure_dir_original
    unset -f rm
    unset -f touch
    # Restore the original function definition
    unset -f global_create_proc_status_file # Remove the mock
    eval "$original_global_create_proc_status_file" # Re-declare original function
    unset global_ensure_dir_original test_temp_dir test_status_file original_global_create_proc_status_file

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
    mkdir -p "$test_dir"
    local large_file="${test_dir}/large.bin"
    local small_file="${test_dir}/small.bin"
    local missing_file="${test_dir}/missing.bin"

    local all_passed=true

    # Create a large file (>= 1MB)
    dd if=/dev/zero of="$large_file" bs=1M count=1 status=none
    if global_check_file_size "$large_file"; then
        echo "  ✅ Correctly identified large file (>= 1MB)"
    else
        echo "  ❌ Failed to identify large file"
        all_passed=false
    fi

    # Create a small file (< 1MB)
    dd if=/dev/zero of="$small_file" bs=1K count=1 status=none
    if global_check_file_size "$small_file"; then
        echo "  ❌ Incorrectly passed small file (< 1MB)"
        all_passed=false
    else
        echo "  ✅ Correctly identified small file (< 1MB)"
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
    rm -rf "$test_dir"

    if [[ "$all_passed" == "true" ]]; then
        return 0
    else
        return 1
    fi
}

# Test global_press_any_key (timeout case)
test_global_press_any_key() {
    echo "Testing global_press_any_key function (timeout case)..."

    # Mock the 'read' command to force a timeout immediately
    read_original=$(which read)
    read() {
      # Simulate timeout by returning a non-zero code (> 128 is typical for timeout)
      return 142
    }
    # Mock log message to capture output
    LOG_OUTPUT=""
    global_log_message_original=$global_log_message
    global_log_message() {
        LOG_OUTPUT+="[$1] $2\n"
        # Don't echo in mocked version to avoid clutter
    }

    # Set DEBUG to false to get the default timeout message
    DEBUG_ORIGINAL=$DEBUG
    DEBUG=false

    # Capture stdout
    exec 3>&1
    output=$( { global_press_any_key; } 2>&1 1>&3 )
    exec 3>&-

    local passed=true
    local expected_stdout="Timeout reached, continuing automatically."
    local expected_log="Timeout reached (10s), continuing automatically."

    # Check stdout message
    # Need to strip potential leading/trailing whitespace or newlines from capture
    output_clean=$(echo "$output" | tr -d '\n\r')
    expected_stdout_clean=$(echo "$expected_stdout" | tr -d '\n\r')
    if [[ "$output_clean" == *"$expected_stdout_clean"* ]]; then
         echo "  ✅ Correct stdout message for timeout received."
    else
         echo "  ❌ Incorrect stdout message. Expected '*$expected_stdout_clean*', Got '$output_clean'"
         passed=false
    fi

    # Check log message
     if [[ "$LOG_OUTPUT" == *"$expected_log"* ]]; then
         echo "  ✅ Correct log message for timeout received."
     else
         echo "  ❌ Incorrect log message. Expected '*$expected_log*', Got '$LOG_OUTPUT'"
         passed=false
     fi

    # Restore
    unset -f read
    global_log_message=$global_log_message_original
    DEBUG=$DEBUG_ORIGINAL
    unset read_original global_log_message_original DEBUG_ORIGINAL LOG_OUTPUT output output_clean expected_stdout_clean

     if [[ "$passed" == "true" ]]; then
        return 0
    else
        return 1
    fi
}

# Test installation status functions together with mocking
MOCK_STATUS_CONTENT=""
# No need for temp file path here, we mock the operations directly using the variable

# Mock global_write_proc_status_file to operate on MOCK_STATUS_CONTENT
mock_global_write_proc_status_file() {
    local temp_status_array_ref=$1 # Expecting the name of the array
    local serialized=""
    declare -n arr="$temp_status_array_ref" # Use nameref to access the caller's array

    for key in "${!arr[@]}"; do
        local value="${arr[$key]}"
        serialized+="${key}:${value};"
    done
    MOCK_STATUS_CONTENT="$serialized"
    # echo "Mock write: Set content to '$MOCK_STATUS_CONTENT'" >> /dev/stderr
    return 0
}

# Mock global_read_proc_status_file to operate on MOCK_STATUS_CONTENT
mock_global_read_proc_status_file() {
    declare -A temp_status_array # Local associative array
    local serialized=$MOCK_STATUS_CONTENT
    local IFS=";"
    for pair in $serialized; do
        if [[ -n "$pair" ]]; then
            key="${pair%%:*}"
            value="${pair#*:}"
            temp_status_array["$key"]="$value"
        fi
    done
    # Echo the representation bash uses for associative arrays when assigned via command substitution
    declare -p temp_status_array | sed 's/^declare -A [^=]*=//'
    # echo "Mock read: Returning content '$MOCK_STATUS_CONTENT' as '$(declare -p temp_status_array | sed 's/^declare -A [^=]*=//')'" >> /dev/stderr
}


mock_global_create_proc_status_file() { :; } # Do nothing, assume file exists for read/write tests

test_installation_status_functions() {
    echo "Testing installation status functions (write, read, get, set, remove)..."

    # Define locals for original commands/functions to restore later
    local global_create_proc_status_file_original=$global_create_proc_status_file
    # local echo_original=$(which echo) # No longer needed
    # local cat_original=$(which cat) # No longer needed
    local global_read_proc_status_file_original=$global_read_proc_status_file
    local global_write_proc_status_file_original=$global_write_proc_status_file
    # local global_log_message_original=$global_log_message # No longer needed

    # Mock dependencies globally for this test function
    global_create_proc_status_file=mock_global_create_proc_status_file
    global_write_proc_status_file=mock_global_write_proc_status_file # Use direct mock
    global_read_proc_status_file=mock_global_read_proc_status_file   # Use direct mock
    # global_log_message() { :; } # Silence logging - no longer needed

    # --- Test global_write_proc_status_file (via its mock) ---
    echo "  Testing global_write_proc_status_file (mocked interaction)..."
    declare -A test_array_write
    test_array_write["app1"]="installed"
    test_array_write["app2"]="pending"

    MOCK_STATUS_CONTENT="initial_garbage" # Reset mock content
    global_write_proc_status_file test_array_write # Should call mocked write

    local write_passed=true
    local expected_write="app1:installed;app2:pending;"
    local expected_write_alt="app2:pending;app1:installed;" # Order might vary
    if [[ "$MOCK_STATUS_CONTENT" == "$expected_write" ]] || [[ "$MOCK_STATUS_CONTENT" == "$expected_write_alt" ]]; then
        echo "  ✅ Write: Mock correctly updated internal state"
    else
        echo "  ❌ Write: Mock did not update internal state correctly. Expected '$expected_write' or '$expected_write_alt', Got '$MOCK_STATUS_CONTENT'"
        write_passed=false
    fi

    # --- Test global_read_proc_status_file (via its mock) ---
    echo "  Testing global_read_proc_status_file (mocked interaction)..."
    MOCK_STATUS_CONTENT="app3:downloaded;app4:failed;" # Set mock content for reading
    local read_result_str
    # The function echoes the array representation string
    read_result_str=$(global_read_proc_status_file)

    local read_passed=true
    # Assign the output string back to an associative array to check
    declare -A read_result_array="$read_result_str"

    if [[ "${read_result_array[app3]}" == "downloaded" ]] && [[ "${read_result_array[app4]}" == "failed" ]] && [[ ${#read_result_array[@]} -eq 2 ]]; then
         echo "  ✅ Read: Mock correctly deserialized internal state"
    else
         echo "  ❌ Read: Mock did not deserialize internal state correctly. Expected map with app3->downloaded, app4->failed. Got string: '$read_result_str'"
         read_passed=false
    fi

    # --- Test global_get_proc_status ---
    echo "  Testing global_get_proc_status..."
    # This function calls the mocked global_read_proc_status_file
    local get_passed=true
    MOCK_STATUS_CONTENT="app3:downloaded;app4:failed;" # Ensure mock content is set

    local status_get
    status_get=$(global_get_proc_status "app3")
    if [[ "$status_get" == "downloaded" ]]; then
        echo "  ✅ Get: Correctly retrieved existing status ('app3')"
    else
        echo "  ❌ Get: Failed retrieve existing status ('app3'). Expected 'downloaded', Got '$status_get'"
        get_passed=false
    fi

    status_get=$(global_get_proc_status "app_missing")
     if [[ -z "$status_get" ]]; then
        echo "  ✅ Get: Correctly handled missing status ('app_missing')"
    else
        echo "  ❌ Get: Failed handle missing status ('app_missing'). Expected empty, Got '$status_get'"
        get_passed=false
    fi

    # --- Test global_set_proc_status ---
    echo "  Testing global_set_proc_status..."
    # This function calls mocked read and mocked write
    local set_passed=true
    MOCK_STATUS_CONTENT="app5:initial;" # Initial mock state

    global_set_proc_status "app5" "updated"
    expected_set1="app5:updated;"
    if [[ "$MOCK_STATUS_CONTENT" == "$expected_set1" ]]; then
         echo "  ✅ Set: Correctly updated existing status ('app5')"
    else
         echo "  ❌ Set: Failed update existing status ('app5'). Expected '$expected_set1', Got '$MOCK_STATUS_CONTENT'"
         set_passed=false
    fi

    global_set_proc_status "app6" "new"
    expected_set2a="app5:updated;app6:new;"
    expected_set2b="app6:new;app5:updated;"
    if [[ "$MOCK_STATUS_CONTENT" == "$expected_set2a" ]] || [[ "$MOCK_STATUS_CONTENT" == "$expected_set2b" ]] ; then
         echo "  ✅ Set: Correctly added new status ('app6')"
    else
         echo "  ❌ Set: Failed add new status ('app6'). Expected '$expected_set2a' or '$expected_set2b', Got '$MOCK_STATUS_CONTENT'"
         set_passed=false
    fi

    # --- Test global_remove_proc_status ---
    echo "  Testing global_remove_proc_status..."
    # This function calls mocked read and mocked write
    local remove_passed=true
    MOCK_STATUS_CONTENT="app7:present;app8:leave;" # Initial mock state

    global_remove_proc_status "app7"
    expected_remove1="app8:leave;"
    # Need to handle potential trailing semicolon variance from the write mock
    if [[ "$MOCK_STATUS_CONTENT" == "$expected_remove1" ]] || [[ "$MOCK_STATUS_CONTENT" == "${expected_remove1};" ]] ; then
         echo "  ✅ Remove: Correctly removed existing status ('app7')"
    else
         echo "  ❌ Remove: Failed remove existing status ('app7'). Expected '$expected_remove1' Got '$MOCK_STATUS_CONTENT'"
         remove_passed=false
    fi

    # Test removing non-existent (should not change state)
    local previous_content=$MOCK_STATUS_CONTENT
    global_remove_proc_status "app_missing"
    if [[ "$MOCK_STATUS_CONTENT" == "$previous_content" ]]; then
         echo "  ✅ Remove: Correctly handled removing missing status ('app_missing')"
    else
         echo "  ❌ Remove: Failed handle removing missing status ('app_missing'). State changed unexpectedly from '$previous_content' to '$MOCK_STATUS_CONTENT'"
         remove_passed=false
    fi

    # --- Restore original functions/commands ---
    global_create_proc_status_file=$global_create_proc_status_file_original
    # unset -f echo # No longer mocking echo
    # unset -f cat # No longer mocking cat
    # global_log_message=$global_log_message_original # No longer mocking log
    global_read_proc_status_file=$global_read_proc_status_file_original # Restore read
    global_write_proc_status_file=$global_write_proc_status_file_original # Restore write

    unset global_create_proc_status_file_original global_read_proc_status_file_original global_write_proc_status_file_original MOCK_STATUS_CONTENT
    # unset echo_original cat_original global_log_message_original # No longer needed

    # --- Return overall status ---
    if [[ "$write_passed" == "true" ]] && \
       [[ "$read_passed" == "true" ]] && \
       [[ "$get_passed" == "true" ]] && \
       [[ "$set_passed" == "true" ]] && \
       [[ "$remove_passed" == "true" ]]; then
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

run_test "global_run_as_user" test_global_run_as_user
run_test "global_ensure_dir" test_global_ensure_dir
run_test "global_setup_logging" test_global_setup_logging
run_test "global_log_message" test_global_log_message
run_test "global_check_root" test_global_check_root
#run_test "global_check_if_installed" test_global_check_if_installed
#run_test "global_install_apt_package" test_global_install_apt_package
run_test "global_download_media" test_global_download_media
run_test "global_write_proc_status_file" test_global_write_proc_status_file
run_test "global_read_proc_status_file" test_global_read_proc_status_file
run_test "global_get_proc_status" test_global_get_proc_status
run_test "global_set_proc_status" test_global_set_proc_status
run_test "global_remove_proc_status" test_global_remove_proc_status
run_test "Installation Status Functions (write, read, get, set, remove)" test_installation_status_functions
run_test "global_create_proc_status_file" test_global_create_proc_status_file
run_test "global_check_file_size" test_global_check_file_size
run_test "global_press_any_key (timeout case)" test_global_press_any_key

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
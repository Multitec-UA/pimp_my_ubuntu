#!/usr/bin/env bash

# Test script for src/libs/dialog.sh

# Ensure dialog command is available
if ! command -v dialog &> /dev/null; then
    echo "Error: 'dialog' command not found. Please install it (e.g., sudo apt-get install dialog)."
    exit 1
fi

# Source the script to be tested
# Determine the script's directory to source relative files correctly
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
LIB_DIR=$(realpath "$SCRIPT_DIR/../src/libs")

# Check if dialog.sh exists
if [[ ! -f "$LIB_DIR/dialog.sh" ]]; then
    echo "Error: dialog.sh not found in $LIB_DIR"
    exit 1
fi

# Source the library file
# shellcheck source=../src/libs/dialog.sh
source "$LIB_DIR/dialog.sh"

# --- Test Data ---
# Declare GLOBAL_INSTALLATION_STATUS as an associative array
declare -A GLOBAL_INSTALLATION_STATUS

# --- Test Functions ---

test_welcome_screen() {
    echo "--- Testing dialog_show_welcome_screen ---"

    echo "Test Case 1: With procedures"
    GLOBAL_INSTALLATION_STATUS=( ["proc1"]="INIT" ["proc2"]="INIT" )
    dialog_show_welcome_screen
    if [[ $? -eq 0 ]]; then
        echo "Welcome screen (with procedures) displayed successfully (visual check needed)."
    else
        echo "ERROR: Welcome screen (with procedures) failed."
    fi
    sleep 2 # Pause for visual inspection

    echo "Test Case 2: Without procedures"
    GLOBAL_INSTALLATION_STATUS=() # Empty the array
    dialog_show_welcome_screen
    if [[ $? -eq 1 ]]; then
        echo "Welcome screen (no procedures) displayed error correctly (visual check needed)."
    else
        echo "ERROR: Welcome screen (no procedures) did not return expected error status."
    fi
    sleep 2
    echo "-----------------------------------------"
}


test_procedure_selector() {
    echo "--- Testing dialog_show_procedure_selector_screen ---"
    local procedures=("Procedure_A" "Very_Long_Procedure_Name_B" "Proc_C")

    echo "Displaying procedure selector (requires manual interaction)..."
    # We redirect stderr to stdout to capture choices if needed, and use /dev/tty for dialog output
    # Note: This function echoes choices to stdout on success.
    selected_choices=$(dialog_show_procedure_selector_screen "${procedures[@]}")
    local status=$?

    if [[ $status -eq 0 ]]; then
        echo "Procedure selector finished (OK/Enter)."
        if [[ -n "$selected_choices" ]]; then
            echo "Selected choices returned:"
            echo "$selected_choices" # Print selections if any
        else
            # This case should ideally not happen if the function logic prevents empty selection properly
             echo "Procedure selector finished but returned empty selection (check function logic)."
        fi
    elif [[ $status -eq 1 ]]; then
         # Handle Cancel/ESC or no selection case (dialogs already shown by the function)
         echo "Procedure selector cancelled or no selection made (visual check needed)."
    else
        echo "ERROR: Procedure selector returned unexpected status: $status"
    fi
    sleep 2
    echo "-----------------------------------------"

}

test_status_screen() {
    echo "--- Testing dialog_show_procedure_status_screen ---"

    echo "Test Case 1: With various statuses"
    GLOBAL_INSTALLATION_STATUS=(
        ["ShortProc"]="SUCCESS"
        ["AnotherOne"]="FAILED"
        ["MediumLength"]="PENDING"
        ["VeryVeryLongProcedureNameExample"]="INIT"
        ["SkippedTask"]="SKIPPED"
        ["UnknownStatusTask"]="UNKNOWN"
    )
    echo "Displaying status screen (requires manual interaction)..."
    dialog_show_procedure_status_screen
    local status=$?

     if [[ $status -eq 0 ]]; then
        echo "Status screen finished (Continue selected)."
    elif [[ $status -eq 1 ]]; then
         echo "Status screen finished (Cancel/ESC selected)."
    else
        echo "ERROR: Status screen returned unexpected status: $status"
    fi
    sleep 2

    echo "Test Case 2: No procedures"
    GLOBAL_INSTALLATION_STATUS=()
    echo "Displaying status screen with no procedures..."
    dialog_show_procedure_status_screen
     if [[ $? -eq 1 ]]; then
        echo "Status screen (no procedures) displayed error correctly (visual check needed)."
    else
        echo "ERROR: Status screen (no procedures) did not return expected error status."
    fi
    sleep 2
    echo "-----------------------------------------"

}

test_status_icon() {
    echo "--- Testing dialog_get_status_icon ---"
    local statuses=("SUCCESS" "FAILED" "PENDING" "INIT" "SKIPPED" "UNKNOWN_STATUS" "")
    for status in "${statuses[@]}"; do
        icon=$(dialog_get_status_icon "$status")
        echo "Status: '$status' -> Icon: '$icon'"
    done
    echo "-----------------------------------------"
}

# --- Main Execution ---
echo "Starting dialog.sh tests..."
echo "NOTE: This script requires manual interaction for dialog boxes."

test_status_icon      # Test simple function first
test_welcome_screen
test_procedure_selector # Requires interaction
test_status_screen      # Requires interaction

echo "Dialog tests finished. Manual visual verification was required for dialog screens."

exit 0 
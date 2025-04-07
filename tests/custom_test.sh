#!/usr/bin/env bash

# =============================================================================
# Pimp My Ubuntu - Custom Test Script
# =============================================================================
# Description: Custom test script for Pimp My Ubuntu


# Debug flag - set to true to enable debug messages
readonly DEBUG=${DEBUG:-false}
readonly LOCAL=${LOCAL:-false}

# Software-common constants
readonly _SOFTWARE_COMMAND="custom-test"
readonly _SOFTWARE_DESCRIPTION="Custom test script for Pimp My Ubuntu"
readonly _SOFTWARE_VERSION="1.0.0"
readonly _DEPENDENCIES=("curl" "wget" "dialog" "jq")


# =============================================================================
# Custom Test Functions
# =============================================================================

main() {
    echo "Custom Test Script"
    echo "DEBUG: ${DEBUG}"
    echo "LOCAL: ${LOCAL}"


    # Source libraries
    if [[ "$LOCAL" == "true" ]]; then
        # Strict mode
        set -euo pipefail
        # Source libraries from local directory
        source "./src/libs/global_utils.sh"
        source "./src/libs/dialog.sh"
    else
        # Source libraries from remote repository
        _source_lib "global_utils.sh"
        _source_lib "dialog.sh"
    fi  

    # Check if the script is running with root privileges
    global_check_root

    echo "finished"
    exit 0
}

main

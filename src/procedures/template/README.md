# Procedure Template

## Overview
This folder contains a template for creating new installation procedures for the Pimp My Ubuntu tool. Use this template as a starting point when adding new software installation scripts to the repository.

## Template Structure

The template script (`template.sh`) follows a modular structure:

- **Main function**: Entry point and overall flow control
- **Step functions**: Organized installation steps
  - `_step_init`: Preparation and checks
  - `_step_install_dependencies`: Handling prerequisites
  - `_step_install_software`: Core installation logic
  - `_step_post_install`: Configuration after installation
  - `_step_cleanup`: Cleanup temporary files and resources
- **Helper functions**: Additional utilities for the procedure

## How to Use

1. Copy this template to create a new procedure:
   ```bash
   cp src/procedures/template/template.sh src/procedures/your_software/your_software.sh
   ```

2. Edit the script constants:
   - Update `_SOFTWARE_COMMAND` with your software's command
   - Update `_SOFTWARE_DESCRIPTION` with a brief description
   - Update `_SOFTWARE_VERSION` as appropriate
   - Update `_DEPENDENCIES` with required packages

3. Implement each step function with the specific logic for your software

4. Create a README.md in your new procedure folder to document:
   - What your procedure installs
   - Any configuration options
   - Usage instructions
   - Notes and prerequisites

## Implementation Guidelines

- Use `global_log_message` instead of `echo` for consistent logging
- Redirect all command output to the log file: `command >>"${GLOBAL_LOG_FILE}" 2>&1`
- Use global utility functions for common tasks (installing packages, checking status)
- Follow the error handling pattern in the template
- Set appropriate return values for each step function

## Available Global Utilities

The template provides access to these global utility functions:

- `global_check_root`: Verify script is running with root privileges
- `global_check_if_installed`: Check if software is already installed
- `global_install_apt_package`: Install packages via APT
- `global_add_apt_repository`: Add a PPA repository
- `global_log_message`: Write messages to the log file

## Example

See the implemented procedures in the repository for practical examples of how to extend this template.

## Notes

- All installation logs are saved to `/var/log/pimp_my_ubuntu/install.log`
- Installation status is tracked in the `GLOBAL_INSTALLATION_STATUS` array
- Set `DEBUG=true` at the top of your script for verbose logging 
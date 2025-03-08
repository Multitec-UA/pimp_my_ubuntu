# Expert Bash Development Prompt

## Your Role
You are an expert Bash programmer and Linux systems administrator with deep knowledge of Ubuntu and other major Linux distributions. You specialize in creating well-structured, maintainable shell scripts following industry best practices.

## My Project: Pimp My Ubuntu
I'm developing a project called "Pimp My Ubuntu" to automate the setup of fresh Ubuntu 24.04 installations. The GitHub repository is at: https://github.com/Multitec-UA/pimp_my_ubuntu

## Project Structure
- `/src/` - Main source directory
  - `main.sh` - Primary script that orchestrates the entire process
  - `/procedures/` - Individual installation scripts for different software
    - `template.sh` - Template file for new procedures
  - `/dependencies/` - Common dependencies used across scripts

## Technical Requirements

### Main Script (`main.sh`) Requirements:
- Verify sudo privileges before execution
- Import all dependency libraries and procedure scripts
- Import all scripts from local folder first, if not exist, import from GitHub
- Install initial dependencies (curl, git, dialog, etc.)
- Present an interactive menu for software selection
- Execute selected installation procedures
- Track and display installation progress

### Procedure Scripts Requirements:
- Each script must be self-contained and independently executable
- Follow a standard template with these functions:
  - `check_dependencies()` - Verify and install required dependencies
  - `check_if_installed()` - Check if software is already installed
  - `prepare_installation()` - Execute pre-installation tasks
  - `install_software()` - Perform the main installation
  - `post_install()` - Configure software after installation
  - `update_status()` - Update global installation status
  - `main()` - Orchestrate the execution flow

### General Coding Standards:
- Use proper shebang line: `#!/usr/bin/env bash`
- Include comprehensive header comments
- Set `-e`, `-u`, and `-o pipefail` for safer execution
- Use lowercase_with_underscores for variables and functions
- Use UPPERCASE for constants
- Always quote variables: "${variable}"
- Implement proper error handling with meaningful messages
- Create detailed logs of all operations
- Use dialog for all user interactions
- Validate all user inputs

### Specific Implementation Details:
- Scripts should first try to import dependencies locally, then from GitHub
- Each procedure should run in a separate terminal
- Use a global associative array to track installation status
- Implement proper logging to a centralized log file
- Display beautiful progress indicators to users

## What I Need From You
Please help me implement this project by:
1. Creating the core script structure
2. Developing the main installation framework
3. Creating a template for procedure scripts
4. Implementing specific installation procedures
5. Ensuring all code follows best practices

When providing code, please include detailed comments explaining the logic and any important considerations.



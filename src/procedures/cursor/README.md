# Cursor IDE

## Overview
This folder contains the installation script and resources for Cursor IDE, a modern and powerful development environment built on web technologies. The script handles installation of the Cursor AppImage, configuration of necessary system components, and sets up convenient command-line access.

## Features

- Installs the latest version of Cursor IDE as an AppImage
- Sets up appimaged for proper AppImage integration
- Adds a convenient `cursor` command to launch the IDE from terminal
- Configures system settings for optimal performance
- Works with both Bash and Zsh shells

## Modifications Applied

The installation script (`cursor.sh`) makes the following changes to your system:

1. **Software Installation**:
   - Downloads and installs the latest Cursor IDE AppImage to `~/Applications/`
   - Installs appimaged for AppImage integration
   - Installs required dependencies: libfuse3-3, fuse3, libfuse2

2. **System Configuration**:
   - Creates the Applications directory in your home folder if it doesn't exist
   - Configures AppArmor settings in `/etc/sysctl.d/99-cursor.conf`
   - Removes potential conflicts with other AppImage launchers

3. **Shell Integration**:
   - Adds a `cursor()` function to your `.bashrc` and `.zshrc` (if present)
   - Function allows launching Cursor with `cursor` command
   - Supports opening files/folders with `cursor /path/to/project`

## Usage

### Installation

To install Cursor IDE:

```bash
curl -fsSL https://raw.github.com/Multitec-UA/pimp_my_ubuntu/main/src/procedures/cursor/cursor.sh | sudo bash
```


### Using Cursor

After installation, you can use Cursor in the following ways:

1. **Launch from terminal**:
   ```bash
   # Open Cursor IDE
   cursor
   
   # Open a specific project or file
   cursor /path/to/project
   ```

2. **Launch from applications menu**:
   - Look for "Cursor" in your desktop environment's application launcher

## Notes

- System reboot is recommended after installation to apply all system changes
- The script creates a dedicated Applications folder in your home directory
- The Cursor command will be available in new terminal sessions after installation
- If you're using a shell other than Bash or Zsh, you'll need to manually set up the cursor function

## Troubleshooting

If you encounter issues with Cursor:

1. **AppImage not launching**:
   - Ensure FUSE is properly installed
   - Check system logs with `journalctl -f`
   - Verify AppArmor settings were applied

2. **Command not found**:
   - Source your shell configuration file: `source ~/.bashrc` or `source ~/.zshrc`
   - Check if the cursor function was added to your shell config file 
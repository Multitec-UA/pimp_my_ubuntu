# TFSwitch Installation Procedure

TFSwitch is a command-line tool that allows you to easily switch between different versions of Terraform. If you don't have a particular version installed, TFSwitch can download and install it for you automatically.

## What's Included

- ✅ TFSwitch binary installation to `/usr/local/bin`
- ✅ Automatic PATH configuration with symlink to `/usr/bin`
- ✅ Dependencies installation (curl, bash, wget, unzip)
- ✅ Installation verification and version checking
- ✅ Post-installation configuration

## Usage

```bash
curl -fsSL https://raw.github.com/Multitec-UA/pimp_my_ubuntu/refs/tags/v0.1.0/src/procedures/tfswitch/tfswitch.sh | sudo bash
```

## What It Does

1. **Prerequisites Check**: Verifies root access and checks if TFSwitch is already installed
2. **Dependencies Installation**: Installs required packages (curl, bash, wget, unzip)
3. **Download Official Installer**: Downloads the official TFSwitch installation script from GitHub
4. **Secure Installation**: Executes the official installer with verification steps
5. **PATH Configuration**: Creates symlinks to ensure TFSwitch is available system-wide
6. **Installation Verification**: Confirms the installation was successful and displays version info
7. **Cleanup**: Removes temporary files and cleans up the system

## After Installation

### Basic Usage

Once installed, you can use TFSwitch in several ways:

**Interactive Mode:**
```bash
tfswitch
```
This will display a dropdown menu where you can select the Terraform version you want to use.

**Direct Version Selection:**
```bash
tfswitch 1.6.0
```
This will directly install and switch to Terraform version 1.6.0.

**Using .tfswitchrc File:**
Create a `.tfswitchrc` file in your project directory:
```bash
echo "1.6.0" > .tfswitchrc
tfswitch
```

### Integration with Shell

For automatic version switching when entering directories, you can add this to your shell configuration:

**For Bash** (add to `~/.bashrc`):
```bash
cdtfswitch(){
  builtin cd "$@";
  cdir=$PWD;
  if [ -f "$cdir/.tfswitchrc" ]; then
    tfswitch
  fi
}
alias cd='cdtfswitch'
```

**For Zsh** (add to `~/.zshrc`):
```bash
load-tfswitch() {
  local tfswitchrc_path=".tfswitchrc"
  if [ -f "$tfswitchrc_path" ]; then
    tfswitch
  fi
}
add-zsh-hook chpwd load-tfswitch
load-tfswitch
```

## Features

- **Version Management**: Easily switch between any version of Terraform
- **Automatic Downloads**: Downloads and installs versions that aren't available locally
- **Project-based Switching**: Use `.tfswitchrc` files for project-specific versions
- **Interactive Interface**: User-friendly dropdown menu for version selection
- **Shell Integration**: Automatic version switching when changing directories
- **Minimal Requirements**: Lightweight tool with minimal dependencies

## System Requirements

- Ubuntu 24.04+ (or compatible Linux distribution)
- Root/sudo access for installation
- Internet connection for downloading Terraform versions
- Basic utilities: curl, bash, wget, unzip (automatically installed)

## Troubleshooting

### Permission Issues
If you encounter permission errors, ensure you're running the script with sudo:
```bash
sudo tfswitch
```

### Path Issues
If `tfswitch` command is not found after installation, try:
```bash
source ~/.bashrc
# or
export PATH="/usr/local/bin:$PATH"
```

### Version Download Issues
If TFSwitch can't download specific Terraform versions:
- Check your internet connection
- Verify the version number exists on HashiCorp's releases page
- Try running with sudo if there are permission issues

### Cache Issues
If you encounter issues with cached versions:
```bash
# Clear TFSwitch cache (if you have write permissions)
rm -rf ~/.terraform.versions
```

## Useful Commands

```bash
# Show current Terraform version
terraform version

# List installed Terraform versions
ls ~/.terraform.versions/

# Switch to latest version
tfswitch latest

# Switch to specific version
tfswitch 1.6.0

# Show TFSwitch help
tfswitch --help
```

## Documentation

For more detailed information about TFSwitch features and usage, visit:
- [Official TFSwitch Documentation](https://tfswitch.warrensbox.com/)
- [TFSwitch GitHub Repository](https://github.com/warrensbox/terraform-switcher)

## Notes

- TFSwitch downloads Terraform binaries to `~/.terraform.versions/`
- The active Terraform binary is symlinked to `/usr/local/bin/terraform`
- TFSwitch respects `.tfswitchrc` files for automatic version switching
- All installation activity is logged to `/var/log/pimp_my_ubuntu/install.log`
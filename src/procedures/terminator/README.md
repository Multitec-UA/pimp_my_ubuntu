# Terminator Terminal Installation Procedure

Installs and configures Terminator terminal emulator with custom settings and sets it as the system's default terminal application.

## What's Included

- ✅ Terminator terminal emulator (latest stable version)
- ✅ Python dependencies and required libraries
- ✅ Custom configuration with optimized profiles and layouts
- ✅ Professional color schemes and transparency settings
- ✅ Enhanced keybindings for improved productivity
- ✅ Automatic backup of existing configuration
- ✅ Default terminal integration (x-terminal-emulator)
- ✅ GNOME desktop environment compatibility

## Usage

### Remote Installation (Recommended)
```bash
curl -fsSL https://raw.github.com/Multitec-UA/pimp_my_ubuntu/refs/tags/v0.1.0/src/procedures/terminator/terminator.sh | sudo bash
```

### Local Development
```bash
cd /path/to/pimp_my_ubuntu
sudo LOCAL=true DEBUG=true ./src/procedures/terminator/terminator.sh
```

## What It Does

1. **Preparation**: Checks for existing Terminator installation and verifies prerequisites
2. **Dependencies**: Installs required Python packages and libraries:
   - `python3-gi` - Python GTK bindings
   - `gir1.2-vte-2.91` - Virtual Terminal Emulator widget
   - `python3-psutil` - Process and system utilities
   - `python3-configobj` - Configuration file parser
   - `python3-six` - Python 2/3 compatibility utilities
   - `gir1.2-keybinder-3.0` - Keyboard shortcut bindings
3. **Installation**: Installs Terminator from official Ubuntu repositories
4. **Configuration**: 
   - Creates `~/.config/terminator/` directory
   - Backs up existing configuration (if present)
   - Copies custom configuration with professional settings
   - Sets proper file ownership and permissions
5. **System Integration**:
   - Registers Terminator in alternatives system
   - Sets as default x-terminal-emulator
   - Configures GNOME desktop integration (if available)

## Configuration Features

The custom configuration includes:

### Visual Enhancements
- **Dark Theme**: Professional dark background (#282828)
- **Transparency**: Subtle transparency (97% opacity) for modern appearance
- **Custom Colors**: Carefully selected color palette for better readability
- **Font Settings**: Optimized cursor and text rendering

### Functional Improvements
- **Extended Scrollback**: 20,000 lines of history
- **Smart Layouts**: Pre-configured window layouts for development
- **Keybinding Enhancements**:
  - `Alt+O`: Broadcast off
  - `Alt+G`: Broadcast to group
  - `Alt+A`: Broadcast to all terminals
- **Plugin Integration**: SaveLastSessionLayout for session persistence

### Window Management
- **Split Panes**: Horizontal and vertical splitting support
- **Multiple Profiles**: Default and custom profile configurations
- **Layout Persistence**: Automatic layout saving and restoration
- **Fullscreen Mode**: Optimized for full-screen terminal usage

## After Installation

### Using Terminator
1. **Open New Terminal**: Press `Ctrl + Alt + T` to open Terminator
2. **Split Terminals**: 
   - Right-click and select "Split Horizontally" or "Split Vertically"
   - Use keyboard shortcuts for quick splitting
3. **Manage Profiles**: Right-click → Preferences to customize further
4. **Session Management**: Your window layouts will be automatically saved

### Keyboard Shortcuts
- `Ctrl + Shift + E`: Split terminal vertically
- `Ctrl + Shift + O`: Split terminal horizontally
- `Ctrl + Shift + W`: Close current terminal
- `Ctrl + Shift + T`: Open new tab
- `Alt + Arrow Keys`: Navigate between split terminals

### Customization
- Configuration file: `~/.config/terminator/config`
- Backup files: `~/.config/terminator/config.backup.YYYYMMDD_HHMMSS`
- Profile settings: Access via right-click → Preferences

## Troubleshooting

### Terminal Doesn't Open with Keyboard Shortcut
- Verify installation: `which terminator`
- Check alternatives: `sudo update-alternatives --config x-terminal-emulator`
- Manually set: `sudo update-alternatives --set x-terminal-emulator /usr/bin/terminator`

### Configuration Issues
- Check file ownership: `ls -la ~/.config/terminator/config`
- Restore backup: `cp ~/.config/terminator/config.backup.* ~/.config/terminator/config`
- Reset to defaults: Remove config file and restart Terminator

### GNOME Integration Problems
- Check gsettings: `gsettings get org.gnome.desktop.default-applications.terminal exec`
- Reset GNOME settings: `gsettings reset org.gnome.desktop.default-applications.terminal exec`

### Dependencies Issues
- Update package list: `sudo apt update`
- Reinstall dependencies: `sudo apt install --reinstall python3-gi gir1.2-vte-2.91`

## Notes

- System reboot is not required, but logging out and back in may be needed for some desktop environments
- The procedure preserves any existing Terminator configuration by creating timestamped backups
- Custom layouts and profiles can be further customized through the Terminator preferences GUI
- The configuration supports both single-monitor and multi-monitor setups

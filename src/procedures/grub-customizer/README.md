# GRUB Customizer

## Overview
This folder contains the installation script and resources for customizing the GRUB bootloader in Ubuntu. GRUB Customizer is a graphical tool that allows users to modify GRUB bootloader settings and apply custom themes to enhance the boot experience.

## Features

- Installs the GRUB Customizer application
- Applies a custom GRUB theme from a selection of pre-configured options
- Configures GRUB settings for optimal display
- Sets up proper resolution and display settings

## Available Themes

The following themes are available:

1. **monterey-theme** - A clean, macOS Monterey-inspired theme
2. **crt-amber-theme** - A retro CRT amber terminal-style theme
3. **solarized-theme** - A theme based on the popular Solarized color scheme
4. **cybergrub-theme** - A cyberpunk-inspired theme with neon aesthetics

Theme previews are available in the `media/theme-previews` directory.

## Modifications Applied

The installation script (`grub_customizer.sh`) makes the following changes to your system:

1. **Software Installation**:
   - Adds the PPA repository: `ppa:danielrichter2007/grub-customizer`
   - Installs the GRUB Customizer application

2. **GRUB Configuration**:
   - Creates/updates the GRUB themes directory at `/boot/grub/themes`
   - Installs the selected theme (default: monterey-theme)
   - Modifies `/etc/default/grub` with the following changes:
     - Sets `GRUB_THEME` to point to the installed theme
     - Sets `GRUB_GFXMODE` to "1920x1080x24" for optimal display
     - Enables `GRUB_SAVEDEFAULT="true"` to remember the last boot option
   - Updates the GRUB configuration with `update-grub`

## Usage

### Default Installation

To install with the default theme (monterey-theme):

```bash
curl -fsSL https://raw.github.com/Multitec-UA/pimp_my_ubuntu/main/src/procedures/grub-customizer/grub-customizer.sh | sudo bash
```

### Custom Theme Installation

To install with a specific theme, provide the theme position as an argument:

```bash
# For crt-amber-theme (position 0)
curl -fsSL https://raw.github.com/Multitec-UA/pimp_my_ubuntu/main/src/procedures/grub-customizer/grub-customizer.sh | sudo bash -s 1

# For monterey-theme (position 1)
curl -fsSL https://raw.github.com/Multitec-UA/pimp_my_ubuntu/main/src/procedures/grub-customizer/grub-customizer.sh | sudo bash -s 2

# For solarized-theme (position 2)
curl -fsSL https://raw.github.com/Multitec-UA/pimp_my_ubuntu/main/src/procedures/grub-customizer/grub-customizer.sh | sudo bash -s 3

# For cybergrub-theme (position 3)
curl -fsSL https://raw.github.com/Multitec-UA/pimp_my_ubuntu/main/src/procedures/grub-customizer/grub-customizer.sh | sudo bash -s 3
```

## Notes

- A system reboot is required for changes to take effect
- After installation, you can use the GRUB Customizer application for further customizations
- Additional themes can be found at https://www.gnome-look.org/ 

## Adding Custom Themes

You can add your own GRUB themes to the collection by following these steps:

1. **Find a GRUB theme** - Browse https://www.gnome-look.org/ or other sources for GRUB themes
2. **Prepare the theme file**:
   - Download the theme as a ZIP file
   - Ensure the ZIP contains a `theme.txt` file (required for GRUB themes)
   - Name the ZIP file descriptively (e.g., `my-custom-theme.zip`)

3. **Add the theme to the project**:
   - Place the ZIP file in the `src/procedures/grub_customizer/media/` directory
   - Add a preview image (PNG format) to `src/procedures/grub_customizer/media/theme-previews/`

4. **Update the installation script**:
   - Edit `grub_customizer.sh`
   - Add your theme name to the `_THEME_OPTIONS` array:
     ```bash
     readonly _THEME_OPTIONS=("crt-amber-theme" "monterey-theme" "solarized-theme" "cybergrub-theme" "my-custom-theme")
     ```

5. **Use your theme**:
   - Install GRUB Customizer with your theme by specifying its position in the array:
     ```bash
     curl -fsSL https://raw.github.com/Multitec-UA/pimp_my_ubuntu/main/src/procedures/grub-customizer/grub-customizer.sh | sudo bash -s 4
     ```
   - Where `4` is the position of your theme in the `_THEME_OPTIONS` array (zero-indexed)

### Theme Structure Requirements

For a GRUB theme to work properly, it should contain at least:

- `theme.txt` - The main theme configuration file
- Font files (TTF or PF2 format)
- Background images
- Icons for menu entries

All theme files should be properly referenced in the `theme.txt` file. 
# Pimp My Ubuntu 🧞‍♀️

An automated setup script for fresh Ubuntu 24.04 installations. This tool helps you quickly set up your Ubuntu system with your preferred software and configurations.

YOU DO NOT NEED TO CLONE THIS REPOSITORY! USE THE FOLLOWING CURL COMMANDS


## Features

- 🛠️🔄 With this public script you can install custom software in you Linux distribution based on Debian (Ubuntu Recomended) 
## Requirements

- Ubuntu >= 24.04 LTS
- Root/sudo privileges
- Internet connection



<br>
<br>

---

# Use Pimp My Ubuntu

Execute his command to use de Pimp My Ubuntu main menu.

```bash
curl -fsSL https://raw.github.com/Multitec-UA/pimp_my_ubuntu/main/src/main.sh | sudo bash
```
<div style="background-color: yellow; color: black; padding: 10px; font-size: 1.2em; text-align: center;">
    <strong>↑ ↑ ↑ ↑ ↑ ↑ Execute this command start main menu ↑ ↑ ↑ ↑ ↑ ↑ </strong>
</div>


---
<br>
<br>



# Install software individually

### Install ZSH
Install ZSH, Oh-My-Zsh, plugins (autosuggestions, syntax-highlighting), Powerlevel10k theme and Meslo Nerd Fonts.

```bash
curl -fsSL https://raw.github.com/Multitec-UA/pimp_my_ubuntu/main/src/procedures/zsh/zsh.sh | sudo bash
```

[View detailed ZSH readme](https://github.com/Multitec-UA/pimp_my_ubuntu/blob/main/src/procedures/zsh/README.md)

### Install Cursor
Download cursor, install appimaged and add cursor command to bashrc and zshrc

```bash
curl -fsSL https://raw.github.com/Multitec-UA/pimp_my_ubuntu/main/src/procedures/cursor/cursor.sh | sudo bash
```

[View detailed Cursor readme](https://github.com/Multitec-UA/pimp_my_ubuntu/blob/main/src/procedures/cursor/README.md)

### Install Grub Customizer
Update Grub, install grub-customizer and add theme.

```bash
curl -fsSL https://raw.github.com/Multitec-UA/pimp_my_ubuntu/main/src/procedures/grub-customizer/grub-customizer.sh | sudo bash
```

[View detailed Grub Customizer readme](https://github.com/Multitec-UA/pimp_my_ubuntu/blob/main/src/procedures/grub-customizer/README.md)

<br>

# How contribute

## Directory Structure

```
pimp_my_ubuntu/
├── src/
│   ├── main.sh              # Main installation script
│   ├── procedures/          # Installation procedures
│   │   └── template.sh      # Template for new procedures
│   └── dependencies/        # Common dependencies
│       └── utils.sh         # Utility functions
└── README.md               # This file
```

## Adding New Software

1. Copy the template from `src/procedures/template.sh`
2. Create a new script in `src/procedures/` for your software
3. Implement the required functions:
   - `check_dependencies()`
   - `check_if_installed()`
   - `prepare_installation()`
   - `install_software()`
   - `post_install()`

Example:
```bash
cp src/procedures/template.sh src/procedures/my_software.sh
chmod +x src/procedures/my_software.sh
# Edit my_software.sh with your installation logic
```

## Logging

All installation logs are stored in `/var/log/pimp_my_ubuntu/install.log`

## Status Indicators

During installation, procedures are marked with the following status indicators:

| Symbol | Status | Description |
|--------|--------|-------------|
| ⚙ | INIT | Procedure has been initialized but not yet started |
| ⧖ | PENDING | Procedure is selected for installation but not yet executed |
| ✓ | SUCCESS | Procedure completed successfully |
| ✗ | FAILED | Procedure failed to complete |
| ⏭ | SKIPPED | Procedure skipped because software is already installed |

## Contributing

1. Fork the repository
2. Create a new branch for your feature
3. Commit your changes
4. Push to your branch
5. Create a Pull Request

## License

MIT License - See LICENSE file for details

## Support

- GitHub Issues: [Report a bug](https://github.com/Multitec-UA/pimp_my_ubuntu/issues)
- Pull Requests: [Submit a PR](https://github.com/Multitec-UA/pimp_my_ubuntu/pulls)

## Authors

- Multitec-UA Team with ❤️

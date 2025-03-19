# Pimp My Ubuntu 🚀

An automated setup script for fresh Ubuntu 24.04 installations. This tool helps you quickly set up your Ubuntu system with your preferred software and configurations.

## Features

- 🛠️ Interactive software selection menu
- 📦 Modular installation procedures
- 🔄 Automatic dependency management
- 📝 Detailed logging
- 🔒 Safe execution with error handling
- 🎨 Beautiful progress indicators

## Requirements

- Ubuntu >= 24.04 LTS
- Root/sudo privileges
- Internet connection

## How to use

### Pimp My Ubuntu
Execute his command to use de Pimp My Ubuntu main menu.

```bash
curl -H "Accept: application/vnd.github.v3.raw" \
-s https://api.github.com/repos/Multitec-UA/pimp_my_ubuntu/contents/src/main.sh | bash
```

### Install Grub Customizer
Update Grub, install grub-customizer and add theme.

```bash
curl -H "Accept: application/vnd.github.v3.raw" \
-s https://api.github.com/repos/Multitec-UA/pimp_my_ubuntu/contents/src/procedures/install_grub_customizer/install_grub_customizer.sh | sudo bash
```


## How to develop

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

- Multitec-UA Team

# Spotify Installation Procedure

This procedure installs the Spotify desktop client for Linux, allowing you to stream music directly from your Ubuntu system.

## What's Included

- ✅ Spotify Client for Linux (latest stable version)
- ✅ Automatic repository setup for future updates

## Usage

### Remote Installation (Recommended)
```bash
curl -fsSL https://raw.github.com/Multitec-UA/pimp_my_ubuntu/refs/tags/v0.1.0/src/procedures/spotify/spotify.sh | sudo bash
```

### Local Development
```bash
cd /path/to/pimp_my_ubuntu
sudo LOCAL=true DEBUG=true ./src/procedures/spotify/spotify.sh
```

## What It Does

1. **Dependencies**: Installs `curl` and `gpg` if they are not already present.
2. **Repository Setup**:
   - Adds Spotify's official GPG key to ensure the authenticity of the package.
   - Adds the official Spotify repository to your system's APT sources.
3. **Installation**: Installs the `spotify-client` package.

## After Installation

You can find and launch Spotify from your applications menu.

## System Requirements

- Ubuntu (latest LTS recommended)
- Internet connection

## Troubleshooting

If you encounter issues with the installation, check the log file for detailed error messages:
```
/var/log/pimp_my_ubuntu/install.log
```

For more information, you can refer to the official Spotify for Linux documentation:
[https://www.spotify.com/us/download/linux/](https://www.spotify.com/us/download/linux/)

## Logs and Debugging

All installation activity is logged to `/var/log/pimp_my_ubuntu/install.log`. For verbose output during installation, use:

```bash
DEBUG=true sudo ./spotify.sh
```
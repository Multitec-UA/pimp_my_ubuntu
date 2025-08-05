# Docker Engine Installation Procedure

This procedure installs Docker Engine (Community Edition) on Ubuntu using the official Docker repository. Docker is a platform that enables you to package, distribute, and run applications in containers.

## What's Included

- ✅ Docker Engine (latest stable version)
- ✅ Docker CLI with cloud integration capabilities
- ✅ containerd runtime
- ✅ Docker Buildx plugin (multi-platform builds)
- ✅ Docker Compose plugin (multi-container applications)
- ✅ Automatic service configuration and startup
- ✅ User group configuration for non-root Docker usage
- ✅ Post-installation verification test

## Usage

### Remote Installation (Recommended)
```bash
curl -fsSL https://raw.github.com/Multitec-UA/pimp_my_ubuntu/refs/tags/v0.1.0/src/procedures/docker/docker.sh | sudo bash
```

### Local Development
```bash
cd /path/to/pimp_my_ubuntu
sudo LOCAL=true DEBUG=true ./src/procedures/docker/docker.sh
```

## What It Does

1. **Preparation**: Checks for existing Docker installations and removes conflicting packages
2. **Dependencies**: Installs required packages (curl, gnupg, ca-certificates, etc.)
3. **Repository Setup**: Adds Docker's official GPG key and repository to APT sources
4. **Installation**: Installs Docker Engine and related packages:
   - `docker-ce` (Docker Engine Community Edition)
   - `docker-ce-cli` (Docker command line interface)
   - `containerd.io` (Container runtime)
   - `docker-buildx-plugin` (Enhanced image building)
   - `docker-compose-plugin` (Multi-container applications)
5. **Service Configuration**: Starts and enables Docker service for automatic startup
6. **User Configuration**: Adds the current user to the `docker` group for sudo-free usage
7. **Verification**: Tests the installation with Docker's hello-world image

## After Installation

### Using Docker Without Sudo
The installation automatically adds your user to the `docker` group. To activate this change:

1. **Log out and log back in**, or
2. Run `newgrp docker` in your current terminal, or  
3. Restart your system

After reactivating your session, you can run Docker commands without `sudo`:
```bash
docker run hello-world
docker --version
docker info
```

### Basic Docker Commands
```bash
# List running containers
docker ps

# List all containers
docker ps -a

# List images
docker images

# Pull an image
docker pull ubuntu:latest

# Run a container
docker run -it ubuntu:latest bash

# Stop a container
docker stop CONTAINER_ID

# Remove a container
docker rm CONTAINER_ID

# Remove an image
docker rmi IMAGE_ID
```

### Docker Compose Usage
The installation includes Docker Compose as a plugin:
```bash
# Run with docker compose (recommended)
docker compose up

# Check version
docker compose version
```

## System Requirements

- Ubuntu 22.04 LTS (Jammy Jellyfish)
- Ubuntu 24.04 LTS (Noble Numbat)
- Ubuntu 24.10 (Oracular Oriole)
- 64-bit system (x86_64/amd64, arm64, armhf, s390x, or ppc64le)
- Internet connection for downloading packages

## Security Considerations

- The installation adds your user to the `docker` group, which grants root-level privileges
- Only add trusted users to the docker group
- Consider using [Docker Rootless mode](https://docs.docker.com/engine/security/rootless/) for enhanced security in production environments

## Troubleshooting

### Permission Denied Error
If you see `permission denied` errors when running Docker commands:

1. Verify you're in the docker group:
   ```bash
   groups $USER
   ```

2. If `docker` is not listed, add yourself to the group:
   ```bash
   sudo usermod -aG docker $USER
   ```

3. Log out and log back in, or run:
   ```bash
   newgrp docker
   ```

### Docker Service Not Running
If Docker commands fail with connection errors:

1. Check service status:
   ```bash
   sudo systemctl status docker
   ```

2. Start the service if stopped:
   ```bash
   sudo systemctl start docker
   ```

3. Enable automatic startup:
   ```bash
   sudo systemctl enable docker
   ```

### Config File Permission Error
If you see warnings about `/home/user/.docker/config.json` permissions:

```bash
sudo chown "$USER":"$USER" /home/"$USER"/.docker -R
sudo chmod g+rwx "$HOME/.docker" -R
```

### Firewall Considerations
Docker can bypass ufw firewall rules when exposing container ports. If you use ufw, refer to [Docker and ufw documentation](https://docs.docker.com/network/iptables/) for proper configuration.

## What's Not Included

- **Docker Desktop**: This procedure installs Docker Engine (server) only, not the desktop GUI application
- **Docker Swarm**: Swarm mode is available but not pre-configured
- **Custom registries**: Only Docker Hub is configured by default

## Logs and Debugging

All installation activity is logged to `/var/log/pimp_my_ubuntu/install.log`. For verbose output during installation, use:

```bash
DEBUG=true sudo ./docker.sh
```

## Official Documentation

For more information about Docker, visit:
- [Docker Engine Documentation](https://docs.docker.com/engine/)
- [Docker CLI Reference](https://docs.docker.com/engine/reference/commandline/cli/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Post-installation Steps](https://docs.docker.com/engine/install/linux-postinstall/)
# ZSH Installation Procedure 🚀

This procedure installs and configures ZSH with Oh-My-Zsh, plugins, and the Powerlevel10k theme on your Ubuntu system.

## What's Included

- ✅ ZSH shell installation
- ✅ Oh-My-Zsh framework
- ✅ Powerlevel10k theme
- ✅ Syntax highlighting plugin
- ✅ Autosuggestions plugin
- ✅ Meslo Nerd Fonts for terminal
- ✅ Useful aliases and configurations

## Usage

Run this command to install ZSH with all configurations:

```bash
curl -H "Accept: application/vnd.github.v3.raw" \
-s https://api.github.com/repos/Multitec-UA/pimp_my_ubuntu/contents/src/procedures/zsh/zsh.sh | sudo bash
```

## What It Does

1. Installs ZSH and dependencies
2. Sets ZSH as your default shell
3. Installs Oh-My-Zsh for enhanced ZSH experience
4. Installs useful plugins:
   - zsh-autosuggestions (suggests commands as you type)
   - zsh-syntax-highlighting (colors commands for validity)
   - git, z, docker, sudo, web-search, terraform plugins
5. Installs Meslo Nerd Fonts for better terminal appearance
6. Installs the Powerlevel10k theme for a beautiful prompt
7. Configures ZSH with optimized settings

## After Installation

After installation completes:

1. **Log out and log back in** for the shell change to take effect
2. The first time you open your terminal, the Powerlevel10k configuration wizard will start
3. Follow the prompts to customize your terminal appearance

## Customization

The Powerlevel10k theme can be reconfigured at any time:

```bash
p10k configure
```

## Troubleshooting

- **If your terminal shows weird characters**: Make sure you've set your terminal font to "MesloLGS NF"
- **If plugins aren't working**: Check that they're listed in the plugins section of your ~/.zshrc file
- **If you want to revert to bash**: Run `chsh -s /bin/bash $USER` and restart your session

## Font Installation

The script automatically installs Meslo Nerd Fonts in your user's font directory. Configure your terminal to use "MesloLGS NF" for the best experience. 
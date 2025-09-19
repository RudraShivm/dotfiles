# 💠 Dotfiles using GNU stow

## Prerequisites

```bash
# Git
sudo pacman -S git
# GNU stow
sudo pacman -S stow
```

## Installation

```bash
# Clone the repository
git clone https://github.com/RudraShivm/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Remove conflicting default configs
rm -rf ~/.bashrc ~/.bash_profile ~/.config/nvim ~/.config/alacritty

# Apply dotfiles
stow *
```

#### Or, stow and replace existing dotfiles

```bash
# Replace your ~/dotfiles package with the contents of the existing config file in the system
stow --adopt <package-name>

# Restore ~/dotfiles package with
git --reset hard
```

## Basic Stow Commands

```bash
# Apply a specific package
stow <package-name>

# Apply all packages
stow */

# Remove a package (unlink symlinks)
stow -D <package-name>

# Re-stow (useful after moving files)
stow -R <package-name>

# Dry run (see what would happen)
stow --no <package-name>

# See what's currently stowed
ls -la ~/.config/ | grep '\->'
```

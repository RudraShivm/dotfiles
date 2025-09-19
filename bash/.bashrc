# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
source ~/.local/share/omarchy/default/bash/rc

# Add your own exports, aliases, and functions here.
#
# Make an alias for invoking commands you use constantly
# alias p='python'
#
# Use VSCode instead of neovim as your default editor
# export EDITOR="code"
#
# Set a custom prompt with the directory revealed (alternatively use https://starship.rs)
# PS1="\W \[\e]0;\w\a\]$PS1"

PATH="$HOME/.opt/bin:$HOME/Documents/flutter/bin:$HOME/Documents/android-studio/bin$PATH"
export temp=/home/shivm/.local/temp
export ANDROID_HOME=$HOME/android-sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools
export KDE_USE_NATIVE_DIALOGS=1
export SSH_AUTH_SOCK=$HOME/.bitwarden-ssh-agent.sock

if [ -f ~/.config/scripts/pyenv_manager.sh ]; then
    source ~/.config/scripts/pyenv_manager.sh
fi

if [ -f ~/.config/scripts/sifw-manager.sh ]; then
    source ~/.config/scripts/sifw-manager.sh
fi

alias cd=z
alias vim=nvim

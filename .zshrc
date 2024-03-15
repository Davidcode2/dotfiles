# Created by newuser for 5.9
# Lines configured by zsh-newuser-install
bindkey -v
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/jakob/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall


# Load Angular CLI autocompletion.
source <(ng completion script)

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Lines configured by zsh-newuser-install
setopt autocd
# End of lines configured by zsh-newuser-install

autoload -Uz compinit promptinit
compinit
promptinit

# set vi mode
bindkey -v

# source keybindings
source /usr/share/fzf/key-bindings.zsh
source /usr/share/fzf/completion.zsh

# source syntax highlighting
source /home/jakob/src/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# set default pager to nvimpager
export PAGER=nvimpager

# add alias for dotfiles repo
alias config='/usr/bin/git --git-dir=/home/jakob/.cfg/ --work-tree=/home/jakob'

################
## appearance ##
################

# prompt appearance
PROMPT='%n@arch %~ %# '

fpath+=$HOME/.zsh/pure

# colors
export CLICOLOR=1
export LSCOLORS=ExGxBxDxCxEgEdxbxgxcxd
alias ll="ls -alG"

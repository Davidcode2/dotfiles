# Lines configured by zsh-newuser-install
setopt autocd
# End of lines configured by zsh-newuser-install

autoload -Uz compinit promptinit
compinit
promptinit

# prompt
PROMPT='%n@arch %~ %# '

# set vi mode
bindkey -v

# source keybindings
source /usr/share/fzf/key-bindings.zsh
source /usr/share/fzf/completion.zsh

# source syntax highlighting
source /home/jakob/src/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# add alias for dotfiles repo
alias config='/usr/bin/git --git-dir=/home/jakob/.cfg/ --work-tree=/home/jakob'

# Lines configured by zsh-newuser-install
setopt autocd
# End of lines configured by zsh-newuser-install

# set vi mode
bindkey -v

# source profile # NOT HOW PROFILE WORKS
# should load in at startup when located in $HOME
source ~/.config/shell/profile

# source alias file
source ~/.config/shell/aliasrc

# source keybindings
source /usr/share/fzf/key-bindings.zsh
source /usr/share/fzf/completion.zsh

# determines search program for fzf
if type ag &> /dev/null; then
    export FZF_DEFAULT_COMMAND='ag -p ~/.gitignore -g "" --hidden'
fi
# prefer rg over ag
if type rg &> /dev/null; then
    export FZF_DEFAULT_COMMAND='rg -p ~/.gitignore --files --hidden'
fi

export EDITOR=nvim
# set default pager to nvimpager
export PAGER=nvimpager

# add src folder to path 
# the $PATH: at the beginning signifies that home/jakob.. should be appended to 
# the end of the PATH.
PATH=/home/jakob/.nvm/versions/node/v16.14.0/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/home/jakob/.dotnet/tools:/usr/bin/site_perl:/usr/bin/vendor_perl:/usr/bin/core_perl:/home/jakob/.local/bin/:/usr/bin/ltex-ls-15.2.0-linux-x64/ltex-ls-15.2.0/bin

source /usr/share/nvm/init-nvm.sh

################
## functions  ##
################

# change cursor shape for different vi modes
function zle-keymap-select () {
    case $KEYMAP in
        vicmd) echo -ne '\e[1 q';;      # block
        viins|main) echo -ne '\e[5 q';; # beam
    esac
}
zle -N zle-keymap-select
zle-line-init() {
    zle -K viins # initiate `vi insert` as keymap (can be removed if `bindkey -V` has been set elsewhere)
    echo -ne "\e[5 q"
}
zle -N zle-line-init
echo -ne '\e[5 q' # Use beam shape cursor on startup.
preexec() { echo -ne '\e[5 q' ;} # Use beam shape cursor for each new prompt.

# fuzzy find scripts and open them in editor
es() { du -a ~/.config/* /usr/local/bin/* ~/.zshrc | awk {'print $2'} | fzf | xargs -r $EDITOR ;}

# fuzzy find any file in $HOME and open in editor
ef() { du -a $HOME 2>/dev/null | awk {'print $2'} | fzf | xargs -r $EDITOR ;}

# change to any directory in $HOME
cD() { cd $(du $HOME 2>/dev/null | awk {'print $2'} | fzf) ;} 

################
## appearance ##
################

alias ls='ls --color=auto'
alias ll='ls -l'

export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced

autoload -U colors && colors
PS1="%{$fg[green]%}%n@%m%{$reset_color%}:%{$fg[cyan]%}%1~%{$reset_color%} %% "

export PROMPT='%F{111}%m:%F{2}%~ $%f '

################
##   history  ##
################

# set history size
export HISTSIZE=1000000
# save history after logout
export SAVEHIST=1000000
# history file
export HISTFILE=~/.zhistory
# #append into history file
setopt INC_APPEND_HISTORY
# save only one command if 2 consecutive are equal
#setopt HIST_IGNORE_DUPS
# save only one command if 2 common are same and consistent
setopt HIST_IGNORE_ALL_DUPS
# do not save commands in history that start with a space
setopt HIST_IGNORE_SPACE

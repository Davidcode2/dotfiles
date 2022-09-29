# Lines configured by zsh-newuser-install
setopt autocd
# End of lines configured by zsh-newuser-install

# set vi mode
bindkey -v

# source profile # NOT HOW PROFILE WORKS
# should load in at startup when located in $HOME
# zsh uses .zprofile, but doesnt seem to work for me
# check diagram on here:
# https://unix.stackexchange.com/questions/320465/new-tmux-sessions-do-not-source-bashrc-file
source ~/.config/zsh/.zprofile

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

# edit the current command in editor (Ctrl-v)
autoload -U edit-command-line
zle -N edit-command-line
bindkey -M vicmd "^v" edit-command-line

# change cursor shape for different vi modes
function zle-keymap-select () {
    case $KEYMAP in
        vicmd) echo -ne '\e[1 q';;      # block
        viins|main) echo -ne '\e[5 q';; # beam
    esac
}
zle -N zle-keymap-select
zle-line-init() {
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

# search through pdfs with grep
pdfsearch() {
  contextParam=${3:-0}
  find $1 -name '*.pdf' -exec sh -c 'pdftotext "{}" - | grep --with-filename --label="{}" --color -C'$contextParam' "'$2'"' \;
}

################
## appearance ##
################

export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced

# Find and set branch name var if in git repository.
function git_branch_name()
{
  branch=$(git symbolic-ref HEAD 2> /dev/null | awk 'BEGIN{FS="/"} {print $NF}')
  if [[ $branch == "" ]];
  then
    :
  else
    echo '' $branch ''
  fi
}

# Enable substitution in the prompt.
setopt prompt_subst

autoload -U colors && colors
# This is another way to set the prompt
PS1="%{$fg[green]%}%n@%m%{$reset_color%}:%{$fg[cyan]%}%1~%{$reset_color%} %% "

# this is the currently active prompt
export PROMPT='%{$fg[cyan]%}$(git_branch_name)%F{111}%m:%F{2}%~ $%f '

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

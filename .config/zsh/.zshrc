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

# syntax highlighting
# source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# autocomplete
# source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# source keybindings
# source /usr/share/fzf/key-bindings.zsh
# source /usr/share/fzf/completion.zsh

# determines search program for fzf
if type ag &> /dev/null; then
    export FZF_DEFAULT_COMMAND='ag --ignore .git -g ""'
fi

export EDITOR=nvim
# set default pager to nvimpager

# add src folder to path 
# the $PATH: at the beginning signifies that home/jakob.. should be appended to 
# the end of the PATH.
PATH=/home/jakob/.nvm/versions/node/v16.14.0/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/home/jakob/.dotnet/tools:/usr/bin/site_perl:/usr/bin/vendor_perl:/usr/bin/core_perl:/home/jakob/.local/bin/:/usr/bin/ltex-ls-15.2.0-linux-x64/ltex-ls-15.2.0/bin:/home/jakob/.local/share/gem/ruby/3.0.0/gems/tmuxinator-3.0.5/bin/:/home/jakob/.local/share/gem/ruby/3.0.0/gems/jekyll-4.3.2/exe/:~/.bun/bin:/home/jakob/.local/share/gem/ruby/3.0.0/bin


#################
##     nvm     ##
#################

## run load_nvm in when wanting to use nvm
export NVM_LAZY_LOAD=true
export NVM_DIR="$HOME/.config/nvm"

######################
## auto load stuff  ##
######################

# needs to run before aws auto_completer
autoload bashcompinit && bashcompinit
autoload -Uz compinit && compinit

#################
## completion  ##
#################

# aws autocomplete
complete -C '/usr/local/bin/aws_completer' aws
# nvm bash_completion
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  

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

# search through pdfs with grep
pdfsearch() {
  contextParam=${3:-0}
  find $1 -name '*.pdf' -exec sh -c 'pdftotext "{}" - | grep --with-filename --label="{}" --color -C'$contextParam' "'$2'"' \;
}

timezsh() {
  shell=${1-$SHELL}
  for i in $(seq 1 10); do time $shell -i -c exit; done
}

function load_nvm() {
  if [ -z "$_nvm_loaded" ]; then
    source $NVM_DIR/nvm.sh
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
    _nvm_loaded=true
  fi
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

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/home/jakob/google-cloud-sdk/path.zsh.inc' ]; then . '/home/jakob/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/home/jakob/google-cloud-sdk/completion.zsh.inc' ]; then . '/home/jakob/google-cloud-sdk/completion.zsh.inc'; fi

# bun completions
[ -s "/home/jakob/.bun/_bun" ] && source "/home/jakob/.bun/_bun"


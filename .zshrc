# Lines configured by zsh-newuser-install
setopt autocd
# End of lines configured by zsh-newuser-install

# set vi mode
bindkey -v

# source keybindings
source /usr/share/fzf/key-bindings.zsh
source /usr/share/fzf/completion.zsh

export EDITOR=nvim
# set default pager to nvimpager
export PAGER=nvimpager

# add src folder to path 
# the $PATH: at the beginning signifies that home/jakob.. should be appended to 
# the end of the PATH.

################
##  aliases   ##
################

# add alias for dotfiles repo
alias config='/usr/bin/git --git-dir=/home/jakob/.cfg/ --work-tree=/home/jakob'

# add alias for nvim 
alias vi='/usr/bin/nvim'

# alias for zathura, opening it always as a new process
alias zathura='zathura --fork'

# copy current path
alias y.='xclip -selection c <<< $(pwd)'

# start using lecture rofi script
alias lectureRofi='python /usr/local/bin/university-setup-master/scripts/rofi-lectures.py'

# open url of current course
alias oUrl='yq .url ~/current-course/info.yaml | xargs firefox&'

# aliases for changing directories
alias cdA='cd ~/OneDrive/HochschuleAA/Allgemein'

alias cdZ='cd ~/Zeiss'

alias cdO='cd ~/Documents/Odin'

alias cdC='cd ~/current-course'

alias cdD='cd ~/Downloads'

################
## appearance ##
################

source /usr/share/nvm/init-nvm.sh
alias ls='ls --color=auto'
alias ll='ls -l'

export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced

autoload -U colors && colors
PS1="%{$fg[green]%}%n@%m%{$reset_color%}:%{$fg[cyan]%}%1~%{$reset_color%} %% "

export PROMPT='%F{111}%m:%F{2}%~ $%f '

PATH=/home/jakob/.nvm/versions/node/v16.14.0/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/home/jakob/.dotnet/tools:/usr/bin/site_perl:/usr/bin/vendor_perl:/usr/bin/core_perl:/home/jakob/.local/bin/

################
##   history  ##
################

# set history size
export HISTSIZE=10000
# save history after logout
export SAVEHIST=10000
# history file
export HISTFILE=~/.zhistory
# #append into history file
setopt INC_APPEND_HISTORY
# save only one command if 2 consecutive are equal
#setopt HIST_IGNORE_DUPS
# save only one command if 2 common are same and consistent
setopt HIST_IGNORE_ALL_DUPS

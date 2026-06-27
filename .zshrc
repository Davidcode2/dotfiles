# Created by newuser for 5.9
bindkey -v
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/Users/de10k21533/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall

source /Users/de10k21533/.config/zsh/.zshrc


# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/de10k21533/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/de10k21533/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/de10k21533/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/de10k21533/google-cloud-sdk/completion.zsh.inc'; fi

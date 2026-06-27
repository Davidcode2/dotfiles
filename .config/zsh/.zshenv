# Default programs:
export EDITOR="nvim"
export TERMINAL="alacritty"
#export BROWSER='/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome'
#export BROWSER='/Applications/Arc.app/Contents/MacOS/Arc'
export BROWSER="open -a 'Arc'"

# ~/ Clean-up:
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export ZDOTDIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
export HISTFILE="${XDG_DATA_HOME:-$HOME/.local/share}/history"

# Other program settings:
export FZF_DEFAULT_OPTS="--layout=reverse --height 40%"
export MOZ_USE_XINPUT2="1"		# Mozilla smooth scrolling/touchpads.

# ATAC
export ATAC_KEY_BINDINGS=$HOME/.config/atac/vim_key_bindings.toml

# JIRA CLI
export JIRA_API_TOKEN=$(security find-generic-password -a "$USER" -s "JIRA_API_TOKEN" -w)
export CONFLUENCE_API_TOKEN=$(security find-generic-password -a "$USER" -s "CONFLUENCE_API_TOKEN" -w)

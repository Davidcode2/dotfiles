# Default programs:
export EDITOR="nvim"
export TERMINAL="ghostty"
export BROWSER="/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome"

# qt wayland
export QT_QPA_PLATFORM=wayland

# ~/ Clean-up:
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export ZDOTDIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
export HISTFILE="${XDG_DATA_HOME:-$HOME/.local/share}/history"

# Other program settings:
export FZF_DEFAULT_OPTS="--layout=reverse --height 40%"
export MOZ_USE_XINPUT2="1"		# Mozilla smooth scrolling/touchpads.

eval "$(/opt/homebrew/bin/brew shellenv zsh)"

{ pkgs, ... }: {
  home.packages = [ pkgs.tmuxinator ];
  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };
  xdg.configFile.nvim = {
    source = ../../config/nvim;
    recursive = true;
  };
  programs.tmux = {
    enable = true;
    escapeTime = 0;
    historyLimit = 10000;
    plugins = with pkgs.tmuxPlugins; [ resurrect continuum ];
    extraConfig = ''
      set -g focus-events on
      set -as terminal-features ',alacritty:RGB'
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R
      set -g pane-border-style 'fg=red'
      set -g pane-active-border-style 'fg=yellow'
      set -g status-style 'fg=colour4'
      set -g status-left ""
      set -g status-right '%Y-%m-%d %H:%M '
      set -g @resurrect-strategy-nvim 'session'
      set -g @continuum-restore 'on'
      set -g @continuum-save-interval '5'
    '';
  };
}

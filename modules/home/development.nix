{ config, lib, pkgs, ... }: {
  home.packages = with pkgs; [
    tmuxinator tree-sitter gcc gnumake unzip curl
    nodejs_24 python3 rust-analyzer lua-language-server nixd
  ];
  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };
  xdg.configFile.nvim = {
    source = ../../config/nvim;
    recursive = true;
  };
  home.activation.seedLazyLock = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "${config.xdg.dataHome}/nvim"
    if [ ! -e "${config.xdg.dataHome}/nvim/lazy-lock.json" ]; then
      $DRY_RUN_CMD cp ${../../config/nvim/lazy-lock.json} "${config.xdg.dataHome}/nvim/lazy-lock.json"
      $DRY_RUN_CMD chmod u+w "${config.xdg.dataHome}/nvim/lazy-lock.json"
    fi
  '';
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
      set -g visual-activity off
      set -g visual-bell off
      set -g visual-silence off
      setw -g monitor-activity off
      set -g bell-action none
      setw -g clock-mode-colour yellow
      setw -g mode-style 'fg=black bg=red bold'
      set -g status-position bottom
      set -g status-justify left
      set -g status-style 'fg=colour4'
      set -g status-left ""
      set -g status-left-length 10
      set -g status-right-style 'fg=white bg=colour4'
      set -g status-right '%Y-%m-%d %H:%M '
      set -g status-right-length 50
      setw -g window-status-current-style 'fg=white bg=colour4'
      setw -g window-status-current-format ' #I #W #F '
      setw -g window-status-style 'fg=colour4 bg=black'
      setw -g window-status-format ' #I #[fg=white]#W #[fg=yellow]#F '
      setw -g window-status-bell-style 'fg=yellow bg=red bold'
      set -g message-style 'fg=white bg=colour4 bold'
      set -g @resurrect-strategy-nvim 'session'
      set -g @continuum-restore 'on'
      set -g @continuum-save-interval '5'
    '';
  };
}

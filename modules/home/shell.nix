{ config, pkgs, ... }: {
  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";
    enableCompletion = true;
    history = {
      size = 1000000;
      save = 1000000;
      path = "$HOME/.zhistory";
      ignoreAllDups = true;
      ignoreSpace = true;
    };
    shellAliases = {
      vi = "nvim";
      "cd.." = "cd ..";
      "cd..." = "cd ../..";
      ll = "ls -l";
      notes = "nvim $HOME/documents/notes/index.md";
      todo = "nvim $HOME/documents/notes/todo.md";
      mux = "tmuxinator";
    };
    initContent = ''
      setopt autocd
      bindkey -v
      autoload -U colors && colors
      setopt prompt_subst
      PROMPT='%F{cyan}$(git branch --show-current 2>/dev/null)%F{111}%m:%F{2}%~ $%f '
      autoload -U edit-command-line
      zle -N edit-command-line
      bindkey -M vicmd '^v' edit-command-line
      [[ -r "$HOME/.config/zsh/local.zsh" ]] && source "$HOME/.config/zsh/local.zsh"
    '';
  };
  programs.fzf.enable = true;
  home.packages = [ pkgs.zsh ];
}

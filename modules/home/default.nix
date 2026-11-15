{ pkgs, ... }: {
  imports = [ ./shell.nix ./development.nix ./workstation.nix ./desktop.nix ./opencode.nix ];

  home.stateVersion = "25.11";
  programs.home-manager.enable = true;
  xdg.configFile."nix/nix.conf".text = ''
    experimental-features = nix-command flakes
  '';
  home.sessionVariables.EDITOR = "nvim";
  home.packages = with pkgs; [ git gh fzf ripgrep fd jq bat ];
}

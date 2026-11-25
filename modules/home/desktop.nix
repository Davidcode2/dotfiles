{ config, lib, pkgs, ... }:
{
  options.dotfiles.wayland.enable = lib.mkEnableOption "the Sway desktop profile";

  config = lib.mkIf config.dotfiles.wayland.enable {
    home.packages = with pkgs; [
      waybar wofi wl-clipboard cliphist
      dunst networkmanagerapplet udiskie grim slurp playerctl brightnessctl
      pavucontrol pulseaudio libnotify firefox feh
      nerd-fonts.inconsolata
      (callPackage ./waybar-timer.nix { })
    ];
    fonts.fontconfig.enable = true;
    home.sessionVariables = { TERMINAL = "alacritty"; BROWSER = "firefox"; };
    home.activation.screenshotDirectory = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p "$HOME/Pictures/Screenshots"
    '';
    programs.zathura = {
      enable = true;
      options = { selection-clipboard = "clipboard"; guioptions = "none"; };
    };
    xdg.configFile = {
      "sway/config".source = ../../config/sway/config;
      "sway/outputs.conf".source = ../../hosts/arch/sway-outputs.conf;
      "waybar" = { source = ../../config/waybar; recursive = true; };
      "wofi" = { source = ../../config/wofi; recursive = true; };
      "alacritty/alacritty.toml".source = ../../config/alacritty/alacritty.toml;
      "alacritty/aura.toml".source = ../../config/alacritty/aura.toml;
      "feh/keys".source = ../../config/feh/keys;
    };
  };
}

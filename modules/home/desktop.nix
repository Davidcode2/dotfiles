{ config, lib, pkgs, ... }:
{
  options.dotfiles.wayland.enable = lib.mkEnableOption "the Sway desktop profile";

  config = lib.mkIf config.dotfiles.wayland.enable {
    home.packages = with pkgs; [
      sway waybar wofi alacritty swayidle swaylock wl-clipboard cliphist
      dunst networkmanagerapplet udiskie grim slurp playerctl brightnessctl
      pavucontrol mako
    ];
    xdg.configFile = {
      "sway/config".source = ../../config/sway/config;
      "waybar" = { source = ../../config/waybar; recursive = true; };
      "wofi" = { source = ../../config/wofi; recursive = true; };
      "alacritty/alacritty.toml".source = ../../config/alacritty/alacritty.toml;
      "alacritty/aura.toml".source = ../../config/alacritty/aura.toml;
    };
  };
}

{ ... }: {
  imports = [ ../../modules/home ];
  home.username = "jakob";
  home.homeDirectory = "/home/jakob";
  dotfiles.wayland.enable = true;
}

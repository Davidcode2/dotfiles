{ nixgl, ... }: {
  imports = [ ../../modules/home ];
  home.username = "jakob";
  home.homeDirectory = "/home/jakob";
  dotfiles.wayland.enable = true;

  targets.genericLinux = {
    enable = true;
    nixGL = {
      packages = nixgl.packages;
      defaultWrapper = "mesa";
    };
  };
}

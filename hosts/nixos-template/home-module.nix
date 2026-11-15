home-manager: { ... }: {
  imports = [ home-manager.nixosModules.home-manager ];
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.jakob = {
    imports = [ ../../modules/home ];
    home.username = "jakob";
    home.homeDirectory = "/home/jakob";
  };
}

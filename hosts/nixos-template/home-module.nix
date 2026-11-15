home-manager: { lib, ... }: {
  imports = [ home-manager.nixosModules.home-manager ];
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "terraform" ];
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.jakob = {
    imports = [ ../../modules/home ];
    home.username = "jakob";
    home.homeDirectory = "/home/jakob";
  };
}

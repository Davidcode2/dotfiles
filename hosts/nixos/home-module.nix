home-manager: sops-module: { config, lib, ... }: {
  imports = [ home-manager.nixosModules.home-manager ];
  options.dotfiles.homeUser = lib.mkOption {
    type = lib.types.str;
    default = "jakob";
    description = "NixOS user whose home is managed by the dotfiles profile.";
  };
  config = {
    nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "terraform" ];
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.users.${config.dotfiles.homeUser} = {
      imports = [ sops-module ../../modules/home ];
      home.username = config.dotfiles.homeUser;
      home.homeDirectory = config.users.users.${config.dotfiles.homeUser}.home;
    };
  };
}

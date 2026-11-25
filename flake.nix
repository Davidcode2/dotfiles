{
  description = "Jakob's portable development and desktop environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix/c5eebd4eb2e3372fe12a8d70a248a6ee9dd02eff";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nixpkgs-unstable, home-manager, sops-nix, nixgl, ... }: {
    homeConfigurations."jakob@archlinux" = home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [ "terraform" ];
      };
      extraSpecialArgs = {
        inherit nixgl nixpkgs-unstable;
      };
      modules = [ sops-nix.homeManagerModules.sops ./hosts/arch/home.nix ];
    };

    # Import this module into a real NixOS host after generating its hardware configuration.
    nixosModules.jakob-home = import ./hosts/nixos/home-module.nix home-manager sops-nix.homeManagerModules.sops nixpkgs-unstable;
  };
}

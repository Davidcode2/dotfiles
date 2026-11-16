{ lib, pkgs, ... }:
{
  imports = [
    /etc/nixos/hardware-configuration.nix
    (import ../nixos/home-module.nix {
      nixosModules.home-manager = (builtins.fetchTarball {
        url = "https://github.com/nix-community/home-manager/archive/6eb2d33d1d0c95a37ef6443c88e6c1686012ee8b.tar.gz";
        sha256 = "0y9xxavks8m1a0q50cn9zz5wjw3c3dcqklvv0b3qs9lfg02ijss7";
      }) + "/nixos";
    } ((builtins.fetchTarball {
      url = "https://github.com/Mic92/sops-nix/archive/11e5885d241743ff0193465d533b20e754bc3ce0.tar.gz";
      sha256 = "1l870303ck550rsnxvy984c0gjd7yzhwghsxkm7nv5fzkz3f3byy";
    }) + "/modules/home-manager/sops.nix"))
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/vda";
  networking.hostName = "nixos-vm";
  networking.useDHCP = lib.mkDefault true;
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };
  users.users.nixosgod = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDsLkYbOwi//AzAT57Sx9cBv2rf1xWVZNWWeRMeyrSoY jlingel68@gmail.com"
    ];
  };
  security.sudo.wheelNeedsPassword = false;
  programs.zsh.enable = true;
  dotfiles.homeUser = "nixosgod";
  home-manager.users.nixosgod.dotfiles.workstation.enable = false;
  home-manager.users.nixosgod.programs.neovim = {
    withRuby = false;
    withPython3 = false;
  };
  system.stateVersion = "26.05";
}

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
      url = "https://github.com/Mic92/sops-nix/archive/c5eebd4eb2e3372fe12a8d70a248a6ee9dd02eff.tar.gz";
      sha256 = "05b0gpg2xb43ya2kps3csj91jh1g926br1cgjfqr1ckacvgjnmy0";
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
  system.stateVersion = "26.05";
}

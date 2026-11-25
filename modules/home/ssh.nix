{ config, lib, options, pkgs, ... }:
let
  usesSettings = options.programs.ssh ? settings;
  convertHost = host: {
    HostName = host.hostname;
    IdentityFile = host.identityFile;
  } // lib.optionalAttrs (host ? identitiesOnly) { IdentitiesOnly = host.identitiesOnly; };
in {
  sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
  sops.secrets = {
    zeiss = { sopsFile = ../../secrets/zeiss.enc; format = "binary"; };
    hetzner-1 = { sopsFile = ../../secrets/hetzner-1.enc; format = "binary"; };
  };
  home.packages = [ pkgs.sops pkgs.age ];
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    ${if usesSettings then "settings" else "matchBlocks"} =
      (if usesSettings then lib.mapAttrs (_: convertHost) else lib.id) {
      zeiss = {
        hostname = "github.com";
        identityFile = config.sops.secrets.zeiss.path;
        identitiesOnly = true;
      };
      hetzner = {
        hostname = "167.235.70.95";
        identityFile = config.sops.secrets.hetzner-1.path;
      };
      k8s-node-1 = {
        hostname = "116.203.111.240";
        identityFile = config.sops.secrets.hetzner-1.path;
      };
      k8s-node-2 = {
        hostname = "195.201.5.29";
        identityFile = config.sops.secrets.hetzner-1.path;
      };
      k8s-node-3 = {
        hostname = "91.98.235.232";
        identityFile = config.sops.secrets.hetzner-1.path;
      };
      bot-node-1 = {
        hostname = "167.233.153.108";
        identityFile = config.sops.secrets.hetzner-1.path;
      };
    };
  };

  services.ssh-agent.enable = true;

  # Arch and GCR can export sockets that conflict with the Home Manager agent.
  # Keep explicitly forwarded or otherwise custom agents intact.
  programs.zsh.envExtra = ''
    case "$SSH_AUTH_SOCK" in
      "$XDG_RUNTIME_DIR/ssh-agent.socket"|"$XDG_RUNTIME_DIR/gcr/ssh")
        export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent"
        ;;
    esac
  '';
}

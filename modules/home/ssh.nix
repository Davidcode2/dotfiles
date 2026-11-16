{ ... }: {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      zeiss = {
        hostname = "github.com";
        identityFile = "~/.ssh/zeiss";
        identitiesOnly = true;
      };
      hetzner = {
        hostname = "167.235.70.95";
        identityFile = "~/.ssh/hetzner-1";
      };
      k8s-node-1 = {
        hostname = "116.203.111.240";
        identityFile = "~/.ssh/hetzner-1";
      };
      k8s-node-2 = {
        hostname = "195.201.5.29";
        identityFile = "~/.ssh/hetzner-1";
      };
      k8s-node-3 = {
        hostname = "91.98.235.232";
        identityFile = "~/.ssh/hetzner-1";
      };
      bot-node-1 = {
        hostname = "167.233.153.108";
        identityFile = "~/.ssh/hetzner-1";
      };
    };
  };

  services.ssh-agent.enable = true;
}

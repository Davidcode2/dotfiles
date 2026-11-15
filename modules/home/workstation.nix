{ pkgs, ... }: {
  home.packages = with pkgs; [
    openssh curl wget rsync unzip zip tree
    python3 nodejs_24 rustc cargo rust-analyzer dotnetCorePackages.sdk_10_0-bin typst
    docker-compose docker-buildx kubectl terraform ansible hcloud doctl
    postgresql
    gimp inkscape thunderbird pandoc
    opencode
  ];

  # Docker discovers CLI plugins in this directory, even with the daemon from Arch.
  home.file.".docker/cli-plugins/docker-compose".source = "${pkgs.docker-compose}/bin/docker-compose";
  home.file.".docker/cli-plugins/docker-buildx".source = "${pkgs.docker-buildx}/bin/docker-buildx";
}

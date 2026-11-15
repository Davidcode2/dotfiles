# Dotfiles

One flake for the Arch Home Manager profile and future NixOS hosts. The old
branch configurations remain available in Git history while the migration is
reviewed. The `config/` files are inputs to Home Manager, not a home-directory
worktree.

## Fresh Arch workstation

The bootstrap targets an installed x86_64 Arch system, not a blank disk. First
install Arch with a kernel, firmware and hardware drivers, working internet,
Git, and a `jakob` account with home `/home/jakob` and sudo access. Clone this
repository into `~/dotfiles` and review `hosts/arch/sway-outputs.conf` for the
new machine. The default solid-color background works without a wallpaper.

```sh
cd ~/dotfiles
./scripts/bootstrap-arch.sh
```

The script upgrades Arch packages, installs the system baseline, enables
NetworkManager, Nix, Docker, Tailscale and CUPS sockets/services, then builds
and activates the pinned Home Manager profile. It can be rerun. Downloads and
builds may take significant time, particularly on the first run. It does not
configure a bootloader, drivers, Wi-Fi credentials, printer, or display manager.
Select a hardware-appropriate graphics driver and start Sway from a login
session. To use Zsh as the login shell, run `chsh -s /usr/bin/zsh` and log in
again. Run `tailscale up` to authenticate the new machine.

Docker is installed but the user is not automatically granted daemon access.
If desired, run `./scripts/bootstrap-arch.sh --docker-group` and log out and
back in. Docker group membership grants effectively root-level privileges.
Without it, use `sudo docker`; Arch's Compose and Buildx plugins are installed
for sudo workflows, while the user profile links the Nix-pinned plugins.

System packages/services such as sudo, systemd, Docker Engine, PipeWire and
NetworkManager are owned by Arch. Nix manages user tools including OpenSSH,
Node 24, Python, Rust, .NET 10, kubectl, Terraform, Ansible, Typst, OpenCode,
PostgreSQL tools and the selected desktop applications. Nixpkgs' Terraform is
unfree, so the flake permits that package specifically. Compose and Buildx are
linked as user Docker CLI plugins. The lock file pins Nix inputs; Arch packages
follow the rolling Arch repositories and are not version-pinned. Project-specific
Nix development shells can provide different language or CLI versions.

Restore SSH keys and configuration, kubeconfig, cloud/API credentials, browser
and mail profiles, documents and wallpaper from secure backups separately. Do
not place secrets in this repository or in Nix source files: they may be copied
to the world-readable Nix store. Review existing `~/.docker/cli-plugins`, shell,
editor and desktop files before activation: Home Manager refuses to overwrite
unmanaged files. Move them aside or back them up before retrying.

Check the resulting environment after a new login:

```sh
ssh -V
docker compose version
docker buildx version
docker info                 # use sudo if not in the docker group
kubectl version --client
terraform version
python --version; node --version; cargo --version; dotnet --version
typst --version
systemctl is-active NetworkManager nix-daemon.socket docker.socket tailscaled cups.socket
```

## Existing Arch installation

Clone this repository to `~/dotfiles`. Install the Arch `nix` package and start
the daemon socket, or use the official multi-user installer:
https://nixos.org/download/. For the Arch package:

```sh
sudo pacman -S nix
sudo systemctl enable --now nix-daemon.socket
nix --extra-experimental-features 'nix-command flakes' store ping --store daemon
```

Ensure your user can connect to the Nix daemon and open a new login session.
Enable `nix-command` and `flakes` in `/etc/nix/nix.conf`, or pass
`--extra-experimental-features 'nix-command flakes'` to Nix commands.
After starting a new login shell:

```sh
cd ~/dotfiles
nix flake check
nix build .#homeConfigurations."jakob@archlinux".activationPackage
```

Before activation, back up or move every existing target file. In particular,
the current `.zshenv` sources the old shell configuration directly, and
Neovim, tmux, Sway and OpenCode already have files in this home directory.
Home Manager refuses to overwrite unmanaged files by default; inspect its
collision list and move those files yourself. Keep `~/.cfg` and its worktree
until the new setup has been tested. Then activate:

```sh
nix run github:nix-community/home-manager/release-25.11 -- switch --flake .#jakob@archlinux
```

Review `config/sway/config` for this machine's monitors and wallpapers. The
Waybar timer is packaged from the upstream x86_64 release, and Firefox,
Zathura, feh, audio utilities and the Inconsolata Nerd Font are managed by Nix.
System services,
display manager, graphics drivers and the login shell
remain the responsibility of Arch. Launch a fresh shell and test the desktop
before removing old configuration. Home Manager generations can be listed with
`home-manager generations` and an older generation's `activate` script run to
roll back managed files. Restore your own backups for pre-Home-Manager files.

### Arch migration backups

The original files from the 2026-11-15 migration are preserved locally:

- `~/.local/state/dotfiles-pre-home-manager-20261115.tar.gz` contains the
  pre-migration shell, editor, desktop and selected OpenCode configuration.
- `~/.local/state/dotfiles-identical-before-home-manager/` contains the
  identical existing files moved aside so Home Manager could link them.
- Files replaced because their contents differed have `.pre-home-manager`
  copies beside their original locations, including `~/.zshenv`,
  `~/.tmux.conf`, the Zsh startup files and the Alacritty configuration.

These are local backups and are not stored in this repository. Home Manager
generations roll back managed files; use these backups to restore the original
pre-migration files if needed.

Zsh loads optional `~/.config/zsh/local.zsh` at runtime. Use it for local PATH
additions and secret loading, for example `export ANTHROPIC_API_KEY=$(< ~/keys/.anthropic-secret-key.txt)`;
never place secrets in flake files or any Nix source path. The copied LazyVim
configuration is linked from the Nix store: change its lock file in the
checkout rather than through a running editor. Restart OpenCode after switching
its configuration.

## NixOS

Generate a host's hardware configuration with `nixos-generate-config`, define
its boot loader, file systems, networking, user and `system.stateVersion`, then
include `self.nixosModules.jakob-home` in that host's module list. Enable
`dotfiles.wayland.enable` in `home-manager.users.jakob` if desired. This is a
Home Manager integration module, not an installable hardware configuration.
The module fixes the user and home directory to `jakob` and `/home/jakob`;
adapt it for a different user. It imports Home Manager itself, so avoid importing
the Home Manager NixOS module a second time. No NixOS host has been tested yet.

## Updates

After editing the checkout, check and apply the Arch profile:

```sh
cd ~/dotfiles
nix flake check
home-manager switch --flake .#jakob@archlinux
```

Run `nix flake update` when you want to update the pinned dependencies. New
files in a Git-backed flake must be added to Git's index before Nix can see
them. Review changes and credentials before committing or publishing.

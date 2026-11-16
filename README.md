# Dotfiles

One flake for the Arch Home Manager profile and future NixOS hosts. The old
branch configurations remain available in Git history while the migration is
reviewed. The `config/` files are inputs to Home Manager, not a home-directory
worktree.

## Fresh Arch workstation

The bootstrap targets an installed x86_64 Arch system, not a blank disk. First
install Arch with a kernel, firmware and hardware drivers, working internet,
Git, and a `jakob` account with home `/home/jakob` and sudo access. Clone this
repository into `~/dotfiles` (use HTTPS authentication if SSH is not yet set up)
and review `hosts/arch/sway-outputs.conf` for the
new machine. The default solid-color background works without a wallpaper.
Restore the age identity as described below before running the bootstrap.

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
session. The bootstrap sets Zsh as the login shell; log in again to use it.
Run `tailscale up` to authenticate the new machine.

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

Restore kubeconfig, cloud/API credentials, browser
and mail profiles, documents and wallpaper from secure backups separately. Do
not place plaintext secrets in this repository or in Nix source files: they may be copied
to the world-readable Nix store. Review existing `~/.docker/cli-plugins`, shell,
editor and desktop files before activation: Home Manager refuses to overwrite
unmanaged files. Move them aside or back them up before retrying.

### SSH

Home Manager manages the SSH client aliases in `modules/home/ssh.nix` and runs
an SSH agent. SOPS encrypts the `zeiss` and `hetzner-1` private keys in
`secrets/`; only their ciphertext enters the Nix store. The user systemd
`sops-nix.service` decrypts them into `$XDG_RUNTIME_DIR/secrets.d` and links
them under `~/.config/sops-nix/secrets`. Existing files in `~/.ssh` are not
overwritten. Host keys in `~/.ssh/known_hosts` remain locally managed.

Before the first activation on **each Arch or NixOS host**, restore the age
identity from the password manager or encrypted offline backup to
`~/.config/sops/age/keys.txt`. Create the directory with `mkdir -p -m 700
~/.config/sops/age`, restore the file without exposing its contents, and run
`chmod 600 ~/.config/sops/age/keys.txt`. The identity is unencrypted on the
host; protect access to the account and backups. Keep both backups current and
test restoring one before relying on this setup. SSH key passphrases remain
unchanged.

After activation, check `systemctl --user status sops-nix.service` and that
`~/.config/sops-nix/secrets/zeiss` and `hetzner-1` are readable only by the
user. If decryption fails, check the restored identity and run `systemctl --user
restart sops-nix.service`; use `journalctl --user -u sops-nix.service` for
diagnostics. A running user systemd manager is required. Activation can skip
starting the service when the manager is unavailable, so a successful build or
activation alone does not confirm secrets are loaded. Check again after login.

On an existing installation, back up `~/.ssh/config` before switching, since
Home Manager will not overwrite an unmanaged file:

```sh
mv ~/.ssh/config ~/.ssh/config.pre-home-manager
```

On Arch, the distribution's socket-activated SSH agent and GCR's SSH agent may
already be enabled. Home Manager supplies its own `ssh-agent.service` and uses
`$XDG_RUNTIME_DIR/ssh-agent`. Before switching, disable the competing sockets:

```sh
systemctl --user disable --now ssh-agent.socket gcr-ssh-agent.socket
```

After switching, log out and back in so the session gets a fresh environment.
Home Manager sets `SSH_AUTH_SOCK` only when it is unset; if another component
still sets it, disable that integration or remove its override. Check with
`systemctl --user status ssh-agent` and `printenv SSH_AUTH_SOCK`, then load keys
as needed with `ssh-add ~/.config/sops-nix/secrets/zeiss ~/.config/sops-nix/secrets/hetzner-1`. Agent-held keys need to
be loaded again after restarting the agent. Verify aliases with `ssh -G zeiss`
or `ssh -G k8s-node-1` before connecting.

### Maintaining encrypted SSH keys

The age public recipient is in `.sops.yaml`. `sops` and `age` are installed by
Home Manager. To replace a key without creating a plaintext repository file,
encrypt directly from its existing private file, for example:

```sh
sops --encrypt --input-type binary --output-type binary \
  --filename-override secrets/zeiss.enc --output secrets/zeiss.enc ~/.ssh/zeiss
```

Run `sops updatekeys --input-type binary secrets/zeiss.enc`
and the equivalent command for `hetzner-1.enc` after changing recipients in
`.sops.yaml`; the current identity must be available. To rotate the age
identity, generate a new identity outside the repository, back it up in both
places, add its public recipient alongside the old one, update both files,
and verify decryption using the new identity. Then remove the old recipient,
update both files again, and deploy the new identity to every host. Do not
remove the old identity until recovery and deployment are verified. If the
old identity was compromised, rotate the SSH credentials too: old ciphertext
remains in Git history.

For a new secret, add a matching SOPS creation rule if necessary, encrypt it
without putting plaintext in the checkout, and declare it in Home Manager.
Treat temporary editor files, shell history and backups as sensitive; never
write plaintext secrets into a Nix source or the Nix store.

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

Clone this repository to `~/dotfiles` and restore the age identity as described
above. Install the Arch `nix` package and start
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
never place secrets in flake files or any Nix source path. LazyVim uses a writable
lock file in `~/.local/share/nvim/lazy-lock.json`, initially seeded from the
checkout. Restart OpenCode after switching its configuration.

## NixOS

Generate a host's hardware configuration with `nixos-generate-config`, define
its boot loader, file systems, networking, user and `system.stateVersion`, then
include `self.nixosModules.jakob-home` in that host's module list. Enable
`dotfiles.wayland.enable` in `home-manager.users.jakob` if desired. This is a
Home Manager integration module, not an installable hardware configuration.
It defaults to the existing NixOS user `jakob`; set `dotfiles.homeUser` to use
another existing user. The home directory comes from the NixOS user definition.
It imports Home Manager itself, so avoid importing it a second time. The full
workstation package profile is enabled by default; set
`home-manager.users.<name>.dotfiles.workstation.enable = false` for a smaller
headless installation. Core shell, editor, tmux and OpenCode configuration remain
enabled. The VM exercises the headless profile; the full desktop and workstation
profile still need testing on NixOS hardware. Restore the age identity to the
managed user's home before activation. The separate VM configuration pins its
own sops-nix source; update that pin when updating the flake input.

`hosts/nixos-vm/configuration.nix` contains the VM-specific system configuration,
using its generated `/etc/nixos/hardware-configuration.nix` and the VM's existing
26.05 NixOS/Home Manager sources. The separate VM scripts and deployment guide
are in `~/documents/code/nixos`. They copy the current checkout to the VM; edits
are not applied automatically. The VM configuration is not a flake output and
does not use this flake's 25.11 lock file.

## Updates

After editing the checkout, check and apply the Arch profile:

```sh
cd ~/dotfiles
nix flake check
home-manager switch --flake .#jakob@archlinux
```

Run `nix flake update` when you want to update the pinned dependencies. The
sops-nix URL is pinned to a compatible revision; update that revision
explicitly along with the NixOS VM pin. New
files in a Git-backed flake must be added to Git's index before Nix can see
them. Review changes and credentials before committing or publishing.

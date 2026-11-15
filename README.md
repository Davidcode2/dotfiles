# Dotfiles

One flake for the Arch Home Manager profile and future NixOS hosts. The old
branch configurations remain available in Git history while the migration is
reviewed. The `config/` files are inputs to Home Manager, not a home-directory
worktree.

## Arch bootstrap

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

Review `config/sway/config` and `config/waybar/config` for this machine's
monitors, wallpapers, scripts and external commands (including
`~/.scripts/waybar_timer`, Firefox and audio utilities). Install and configure
those external dependencies and suitable fonts on the host. System services,
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
checkout rather than through a running editor. The `mux` alias requires a
locally installed `tmuxinator`. Restart OpenCode after switching its configuration.

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

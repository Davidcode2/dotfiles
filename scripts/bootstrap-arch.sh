#!/usr/bin/env bash
set -euo pipefail

root=$(realpath "$(dirname "${BASH_SOURCE[0]}")/..")
docker_group=false
if [[ ${1:-} == --docker-group && $# == 1 ]]; then
  docker_group=true
elif [[ $# != 0 ]]; then
  printf 'Usage: %s [--docker-group]\n' "$0" >&2
  exit 2
fi

if [[ $(id -u) == 0 || ! -f /etc/arch-release ]]; then
  printf 'Run as your normal user on an installed Arch Linux system.\n' >&2
  exit 1
fi
if [[ $(id -un) != jakob || $HOME != /home/jakob ]]; then
  printf 'This profile expects user jakob with home /home/jakob; adapt hosts/arch/home.nix first.\n' >&2
  exit 1
fi
if [[ ! -r $HOME/.config/sops/age/keys.txt ]]; then
  printf 'Restore the age identity to ~/.config/sops/age/keys.txt before continuing. See README.md.\n' >&2
  exit 1
fi
if ! systemctl --user show-environment >/dev/null 2>&1; then
  printf 'A running systemd user manager is required to load SSH secrets. Log in normally and retry.\n' >&2
  exit 1
fi

packages=(
  base-devel sudo git openssh ca-certificates networkmanager nix docker docker-compose docker-buildx
  tailscale cups pipewire pipewire-pulse wireplumber
  xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk
  xorg-xwayland polkit udisks2 swaybg zsh
)
sudo pacman -Syu --needed "${packages[@]}"
sudo systemctl enable --now NetworkManager.service nix-daemon.socket docker.socket tailscaled.service cups.socket
sudo usermod -s /usr/bin/zsh "$USER"
nix --extra-experimental-features 'nix-command flakes' store ping --store daemon

if "$docker_group"; then
  sudo usermod -aG docker "$USER"
  printf 'Docker group membership requires a new login.\n'
fi

printf 'Building Home Manager profile; existing unmanaged files may block activation.\n'
activation=$(nix --extra-experimental-features 'nix-command flakes' build --no-link --print-out-paths "path:$root#homeConfigurations.\"jakob@archlinux\".activationPackage")
"$activation/activate"
systemctl --user restart sops-nix.service
for key in zeiss hetzner-1; do
  if [[ ! -r $HOME/.config/sops-nix/secrets/$key ]]; then
    printf 'SSH secret %s is unavailable; inspect systemctl --user status sops-nix.service.\n' "$key" >&2
    exit 1
  fi
done
printf 'Provisioning finished. Start a new login session and restore other private data separately.\n'

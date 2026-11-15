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

packages=(
  base-devel sudo git openssh ca-certificates networkmanager nix docker docker-compose docker-buildx
  tailscale cups pipewire pipewire-pulse wireplumber
  xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk
  xorg-xwayland polkit udisks2 swaybg zsh
)
sudo pacman -Syu --needed "${packages[@]}"
sudo systemctl enable --now NetworkManager.service nix-daemon.socket docker.socket tailscaled.service cups.socket

if "$docker_group"; then
  sudo usermod -aG docker "$USER"
  printf 'Docker group membership requires a new login.\n'
fi

printf 'Building Home Manager profile; existing unmanaged files may block activation.\n'
activation=$(nix --extra-experimental-features 'nix-command flakes' build --no-link --print-out-paths "path:$root#homeConfigurations.\"jakob@archlinux\".activationPackage")
"$activation/activate"
printf 'Provisioning finished. Start a new login session and restore private data separately.\n'

#!/bin/bash

set -e

RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}== Arch Install${NC}"

echo -e "\n=== ${RED}Check initial deps${NC}"

sudo pacman -S --needed gum

gum confirm "Have you updated /etc/pacman.conf?" || { echo "Please update /etc/pacman.conf and try again."; exit 1; }

echo -e "\n===${RED} AUR${NC}"

if ! command -v yay &> /dev/null; then
    sudo pacman -S --needed --noconfirm base-devel git
    pushd /tmp
    git clone https://aur.archlinux.org/yay-bin.git
    pushd yay-bin
    makepkg -si --noconfirm
    popd
    popd
else
    echo "Yay is already installed, moving on."
fi

echo -e "\n===${RED} Install packages${NC}"

package_files=($(ls packages-*.txt 2> /dev/null))

# Check if any package files are found
if [ ${#package_files[@]} -eq 0 ]; then
  echo "No package files found matching the pattern packages-*.txt"
  exit 1
fi

# Use gum to select files
selected_files=$(gum choose --no-limit "${package_files[@]}")

# Loop through the selected files and install the packages
for file in $selected_files; do
  echo "> Install $file..."
  sudo pacman -S --needed --noconfirm $(cat "$file")
done

echo "> Enable base services"

sudo systemctl enable --now NetworkManager

echo "> Install 1Password..."

yay -Syu --needed 1password 1password-cli

echo -e "\n\n${YELLOW}== Installation complete${NC}"

function setup-tailscale() {
    sudo pacman -S tailscale
    sudo systemctl enable --now tailscaled
    sudo tailscale up
}

gum confirm "Install and configure tailscale?" && setup-tailscale

function setup-syncthing () {
    sudo pacman -S syncthing
    systemctl --user enable --now syncthing.service
}
gum confirm "Install and configure syncthing?" && setup-syncthing

echo "Visit https://localhost:8384 to configure syncthing"


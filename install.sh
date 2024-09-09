#!/bin/bash

set -e

if [ "$EUID" -ne 0 ]
  then echo "This script is expected to be run as root during install."
  exit
fi

RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

function get_user () {
    if [ $(ls /home | wc -l) -eq 1 ]; then
       ls /home | head -n 1
    else
        echo "Which user do you want to install to? "
        read username
        echo $username
    fi
}

INSTALLED_USER_NAME=$(get_user)

echo -e "${YELLOW}== Arch Install${NC}"

echo -e "\n=== ${RED}Ensure Parallel Downloads in pacman.conf${NC}"
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf

echo -e "\n=== ${RED}Set a nice TTY font${NC}"
pacman -S --noconfirm --needed terminus-font
echo -e 'FONT=ter-122b' | tee -a /etc/vconsole.conf

echo -e "\n=== ${RED}Check initial deps${NC}"
pacman -S --noconfirm --needed gum

echo -e "\n=== ${RED}LTS Kernel{NC}"
for f in /boot/loader/entries/*_linux.conf
do
    cp "$f" "${f/_linux.conf/_linux-lts.conf}"
    sed -i 's|Arch Linux|Arch Linux LTS Kernel|g' "$f"
    sed -i 's|vmlinuz-linux|vmlinuz-linux-lts|g' "$f"
    sed -i 's|initramfs-linux.img|initramfs-linux-lts.img|g' "$f"
done

echo -e "\n===${RED} Install the Chaotic AUR${NC}"
pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
pacman-key --lsign-key 3056513887B78AEB
pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' --noconfirm
pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' --noconfirm
echo -e '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' | tee -a /etc/pacman.conf
pacman -Syy --noconfirm

echo -e "\n===${RED} AUR${NC}"

if ! command -v yay &> /dev/null; then
    pacman -S --needed --noconfirm yay
    su -l "$INSTALLED_USER_NAME" -c "yay -Syy --noconfirm"
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
  pacman -S --needed --noconfirm $(cat "$file")
done

echo "> Enable base services"
systemctl enable --now NetworkManager

echo "> Install 1Password..."
pacman -S --noconfirm --needed 1password
su -l "$INSTALLED_USER_NAME" -c "yay -S --noconfirm --needed 1password-cli"

echo -e "\n\n${YELLOW}== Installation complete${NC}"

function setup-tailscale() {
    pacman -S --noconfirm tailscale
    systemctl enable --now tailscaled
    tailscale up
}

gum confirm "Install and configure tailscale?" && setup-tailscale

function setup-syncthing () {
    pacman -S --noconfirm syncthing

    su -l "$INSTALLED_USER_NAME" -c "systemctl --user enable --now syncthing.service"
    echo "Visit https://localhost:8384 to configure syncthing"
}

gum confirm "Install and configure syncthing?" && setup-syncthing

#!/bin/bash
# backup.sh - copy current configs into the dotfiles repo
set -eu
set -o pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Backing up to: $DOTFILES_DIR"

# bin
cp -r ~/bin/. "$DOTFILES_DIR/bin/"

# waybar
cp -r ~/.config/waybar/. "$DOTFILES_DIR/config/waybar/"

# swaync
cp -r ~/.config/swaync/. "$DOTFILES_DIR/config/swaync/"

# rofi
cp -r ~/.config/rofi/. "$DOTFILES_DIR/config/rofi/"

# hyprland
cp -r ~/.config/hypr/. "$DOTFILES_DIR/config/hypr/"

# Thunar
cp -r ~/.config/Thunar/. "$DOTFILES_DIR/config/Thunar/"

echo "==> Backup complete."
echo "    Review changes with: cd $DOTFILES_DIR && git diff"
echo "    Then: git add -A && git commit -m 'backup: update configs' && git push"

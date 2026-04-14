#!/bin/bash
# install.sh - fresh Arch Linux + Hyprland + NVIDIA setup
# Run this after a base Arch install with internet access.
set -eu
set -o pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── Helpers ────────────────────────────────────────────────────────────────
log()  { echo "==> $*"; }
ask()  { read -rp "    $* [y/N] " ans; [[ "${ans,,}" == "y" ]]; }

# ─── 1. Ensure paru (AUR helper) ────────────────────────────────────────────
if ! command -v paru &>/dev/null; then
    log "Installing paru (AUR helper)..."
    sudo pacman -S --needed --noconfirm git base-devel
    tmpdir=$(mktemp -d)
    git clone https://aur.archlinux.org/paru.git "$tmpdir/paru"
    (cd "$tmpdir/paru" && makepkg -si --noconfirm)
    rm -rf "$tmpdir"
fi

# ─── 2. Pacman packages ──────────────────────────────────────────────────────
log "Installing pacman packages..."
sudo pacman -S --needed --noconfirm \
    hyprland \
    hyprlock \
    hypridle \
    hyprpaper \
    waybar \
    rofi-wayland \
    swaync \
    thunar \
    thunar-volman \
    thunar-archive-plugin \
    gvfs \
    xdg-user-dirs \
    noto-fonts \
    noto-fonts-emoji \
    ttf-jetbrains-mono-nerd \
    papirus-icon-theme \
    polkit-gnome \
    qt5-wayland \
    qt6-wayland \
    xdg-desktop-portal-hyprland \
    pipewire \
    pipewire-pulse \
    wireplumber \
    bash \
    git

# ─── 3. NVIDIA drivers ──────────────────────────────────────────────────────
log "Installing NVIDIA drivers..."
sudo pacman -S --needed --noconfirm \
    nvidia \
    nvidia-utils \
    nvidia-settings \
    libva-nvidia-driver

# Enable DRM kernel mode setting for NVIDIA + Wayland
GRUB_CFG="/etc/default/grub"
if ! grep -q "nvidia_drm.modeset=1" "$GRUB_CFG" 2>/dev/null; then
    log "Adding nvidia_drm.modeset=1 to GRUB_CMDLINE_LINUX..."
    sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 nvidia_drm.modeset=1 nvidia.NVreg_PreserveVideoMemoryAllocations=1"/' "$GRUB_CFG"
    sudo grub-mkconfig -o /boot/grub/grub.cfg
fi

# Add nvidia modules to mkinitcpio
MKINIT="/etc/mkinitcpio.conf"
if ! grep -q "nvidia nvidia_modeset" "$MKINIT" 2>/dev/null; then
    log "Adding NVIDIA modules to mkinitcpio.conf..."
    sudo sed -i 's/^MODULES=(\(.*\))/MODULES=(\1 nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' "$MKINIT"
    sudo mkinitcpio -P
fi

# Enable nvidia-suspend/hibernate services
sudo systemctl enable nvidia-suspend nvidia-hibernate nvidia-resume 2>/dev/null || true

# ─── 4. AUR packages ────────────────────────────────────────────────────────
log "Installing AUR packages..."
paru -S --needed --noconfirm \
    hyprshot \
    wlogout \
    nwg-look \
    swayosd-git || true

# ─── 5. Restore configs ──────────────────────────────────────────────────────
log "Restoring configs..."

restore() {
    local src="$1" dst="$2"
    mkdir -p "$(dirname "$dst")"
    cp -r "$src/." "$dst/"
    log "  restored $dst"
}

restore "$DOTFILES_DIR/bin"              "$HOME/bin"
restore "$DOTFILES_DIR/config/waybar"   "$HOME/.config/waybar"
restore "$DOTFILES_DIR/config/swaync"   "$HOME/.config/swaync"
restore "$DOTFILES_DIR/config/rofi"     "$HOME/.config/rofi"
restore "$DOTFILES_DIR/config/hypr"     "$HOME/.config/hypr"
restore "$DOTFILES_DIR/config/Thunar"   "$HOME/.config/Thunar"

# Ensure bin scripts are executable
chmod +x "$HOME/bin/"* 2>/dev/null || true
chmod +x "$HOME/.config/waybar/scripts/"*.sh 2>/dev/null || true
chmod +x "$HOME/.config/hypr/config/scripts/"*.sh 2>/dev/null || true

# ─── 6. Thunar — icon theme via GTK settings ─────────────────────────────────
log "Configuring GTK / icon theme for Thunar..."
mkdir -p "$HOME/.config/gtk-3.0"
cat > "$HOME/.config/gtk-3.0/settings.ini" <<'EOF'
[Settings]
gtk-icon-theme-name=Papirus-Dark
gtk-theme-name=Adwaita-dark
gtk-font-name=Noto Sans 10
gtk-cursor-theme-name=Adwaita
EOF

mkdir -p "$HOME/.config/gtk-4.0"
cat > "$HOME/.config/gtk-4.0/settings.ini" <<'EOF'
[Settings]
gtk-icon-theme-name=Papirus-Dark
gtk-theme-name=Adwaita-dark
gtk-font-name=Noto Sans 10
gtk-cursor-theme-name=Adwaita
EOF

# ─── 7. xdg-user-dirs ───────────────────────────────────────────────────────
xdg-user-dirs-update

# ─── 8. Add ~/bin to PATH if missing ────────────────────────────────────────
BASHRC="$HOME/.bashrc"
if ! grep -q 'export PATH="$HOME/bin:$PATH"' "$BASHRC" 2>/dev/null; then
    log "Adding ~/bin to PATH in ~/.bashrc..."
    echo '' >> "$BASHRC"
    echo 'export PATH="$HOME/bin:$PATH"' >> "$BASHRC"
fi

log ""
log "Done! Reboot into Hyprland."
log "  - If GRUB config was changed, reboot for nvidia_drm.modeset to take effect."
log "  - Start Hyprland by typing 'Hyprland' at the TTY login."

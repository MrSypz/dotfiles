# dotfiles

Arch Linux · Hyprland · NVIDIA

## Contents

```
bin/                  — custom scripts (~/.bin)
config/
  hypr/               — Hyprland, hyprlock, hypridle
  waybar/             — bar config + scripts
  swaync/             — notification center
  rofi/               — launcher
  Thunar/             — file manager custom actions & keybinds
```

## Backup (before reinstall)

```bash
cd ~/dotfiles
./backup.sh
git add -A
git commit -m "backup: pre-reinstall snapshot"
git push
```

## Fresh install

### 1. Base Arch install

Boot the Arch ISO, partition, format, mount, then:

```bash
pacstrap /mnt base base-devel linux linux-firmware linux-headers grub efibootmgr networkmanager git
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt
# set locale, hostname, root password, create user, enable NetworkManager, install grub
exit
reboot
```

### 2. Clone and run install.sh

```bash
# Log in as your user (not root)
git clone https://github.com/<your-username>/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash install.sh
```

The script will:
- Install `paru` (AUR helper)
- Install Hyprland, Waybar, Rofi, SwayNC, Thunar + dependencies
- Install NVIDIA drivers and configure DRM modesetting for Wayland
- Restore all configs
- Configure Papirus-Dark icon theme so Thunar shows icons correctly
- Add `~/bin` to your PATH

### 3. Reboot

```bash
reboot
```

Log in at the TTY and type:

```bash
Hyprland
```

## Notes

- **NVIDIA**: the script adds `nvidia_drm.modeset=1` and `nvidia.NVreg_PreserveVideoMemoryAllocations=1` to GRUB and adds `nvidia nvidia_modeset nvidia_uvm nvidia_drm` to mkinitcpio. A reboot after running install.sh is required.
- **Icons in Thunar**: handled by setting `gtk-icon-theme-name=Papirus-Dark` in `~/.config/gtk-3.0/settings.ini` and `~/.config/gtk-4.0/settings.ini`. Run `nwg-look` after login if you want to change the theme via GUI.
- **monitor.conf**: edit `~/.config/hypr/config/monitor.conf` to match your display after install.

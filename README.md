# homeland-only NVIDIA setup

This repository is a standalone extraction of only the NVIDIA install and Hyprland NVIDIA environment patch from the original `MrSypz/dotfiles` repository.

## Files

- `install-nvidia.sh` — installs NVIDIA packages and applies required Arch + Wayland patches
- `nvidia.conf` — Hyprland NVIDIA environment variables
- `README.md` — usage and assumptions
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
git clone https://github.com/MrSypz/dotfiles.git ~/dotfiles
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

## Usage

```bash
chmod +x ./install-nvidia.sh
./install-nvidia.sh
```

Then reboot.

## What the script changes

1. Installs:
   - `nvidia`
   - `nvidia-utils`
   - `nvidia-settings`
   - `libva-nvidia-driver`
2. Ensures these GRUB kernel parameters exist in `/etc/default/grub`:
   - `nvidia_drm.modeset=1`
   - `nvidia.NVreg_PreserveVideoMemoryAllocations=1`
3. Regenerates GRUB config at `/boot/grub/grub.cfg` only if parameters were added.
4. Ensures these modules exist in `/etc/mkinitcpio.conf`:
   - `nvidia`
   - `nvidia_modeset`
   - `nvidia_uvm`
   - `nvidia_drm`
5. Runs `mkinitcpio -P` only if module entries were added.
6. Enables:
   - `nvidia-suspend`
   - `nvidia-hibernate`
   - `nvidia-resume`

## homeland-only assumptions

- Target distro: Arch Linux (uses `pacman` and `mkinitcpio`).
- Bootloader layout: GRUB config source at `/etc/default/grub`, generated output at `/boot/grub/grub.cfg`.
- Privileges: user must have `sudo` access.
- GPU layout for Hyprland patch: `AQ_DRM_DEVICES` assumes DRM devices at `/dev/dri/card0:/dev/dri/card1`.
- Scope is intentionally limited to NVIDIA install + patching only (no full dotfiles restore, Waybar, Rofi, Thunar, or backup flow).

## Notes

- The script is idempotent for GRUB parameters and mkinitcpio module entries.
- Original dotfiles content is intentionally excluded to keep this repository single-purpose.

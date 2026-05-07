#!/usr/bin/env bash
set -euo pipefail

log() {
  echo "==> $*"
}

require_file() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    echo "Missing required file: $file" >&2
    exit 1
  fi
}

append_grub_param_if_missing() {
  local param="$1"
  local escaped
  escaped=$(printf '%s' "$param" | sed 's/[.[\\*^$()+?{}|]/\\&/g')

  if grep -Eq "GRUB_CMDLINE_LINUX_DEFAULT=\"[^\"]*(^| )${escaped}($| )[^\"]*\"" "$GRUB_CFG"; then
    log "GRUB already contains: $param"
  else
    log "Adding GRUB parameter: $param"
    sudo sed -i "s/^\(GRUB_CMDLINE_LINUX_DEFAULT=\"[^\"]*\)\"/\1 $param\"/" "$GRUB_CFG"
    GRUB_CHANGED=1
  fi
}

ensure_mkinit_module() {
  local module="$1"
  if grep -Eq "^MODULES=\([^)]*\b${module}\b[^)]*\)" "$MKINIT"; then
    log "mkinitcpio already contains module: $module"
  else
    log "Adding mkinitcpio module: $module"
    sudo sed -i "s/^MODULES=(\(.*\))/MODULES=(\1 $module)/" "$MKINIT"
    MKINIT_CHANGED=1
  fi
}

if ! command -v pacman >/dev/null 2>&1; then
  echo "This script is for Arch Linux systems with pacman." >&2
  exit 1
fi

log "Installing NVIDIA packages..."
sudo pacman -S --needed --noconfirm \
  nvidia \
  nvidia-utils \
  nvidia-settings \
  libva-nvidia-driver

GRUB_CFG="/etc/default/grub"
require_file "$GRUB_CFG"

GRUB_CHANGED=0
append_grub_param_if_missing "nvidia_drm.modeset=1"
append_grub_param_if_missing "nvidia.NVreg_PreserveVideoMemoryAllocations=1"

if [[ "$GRUB_CHANGED" -eq 1 ]]; then
  log "Regenerating GRUB config..."
  sudo grub-mkconfig -o /boot/grub/grub.cfg
else
  log "No GRUB changes needed."
fi

MKINIT="/etc/mkinitcpio.conf"
require_file "$MKINIT"

MKINIT_CHANGED=0
ensure_mkinit_module "nvidia"
ensure_mkinit_module "nvidia_modeset"
ensure_mkinit_module "nvidia_uvm"
ensure_mkinit_module "nvidia_drm"

if [[ "$MKINIT_CHANGED" -eq 1 ]]; then
  log "Regenerating initramfs..."
  sudo mkinitcpio -P
else
  log "No mkinitcpio changes needed."
fi

log "Enabling NVIDIA suspend/hibernate services..."
sudo systemctl enable nvidia-suspend nvidia-hibernate nvidia-resume 2>/dev/null || true

log "Done. Reboot is required for kernel parameter changes to fully apply."

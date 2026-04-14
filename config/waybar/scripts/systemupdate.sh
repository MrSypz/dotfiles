#!/usr/bin/env bash
set -euo pipefail

# ---------- helpers ----------
pkg_installed() {
    command -v "$1" >/dev/null 2>&1
}

# Detect AUR helper
if pkg_installed yay; then
    AUR_HELPER="yay"
elif pkg_installed paru; then
    AUR_HELPER="paru"
else
    AUR_HELPER=""
fi

# Runtime dir
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}/waybar"
mkdir -p "$RUNTIME_DIR"
INFO_FILE="$RUNTIME_DIR/update_info"

# ---------- RUN UPDATE ----------
if [[ "${1:-}" == "up" && -f "$INFO_FILE" ]]; then
    trap 'pkill -RTMIN+20 waybar' EXIT
    source "$INFO_FILE"

    kitty --title systemupdate bash -ic "
        set -e

        echo '=== System Update ==='
        echo 'Official : ${OFFICIAL_UPDATES:-0}'
        echo 'AUR      : ${AUR_UPDATES:-0}'
        echo 'Flatpak  : ${FLATPAK_UPDATES:-0}'
        echo

        sudo pacman -Syu

        if [ -n '$AUR_HELPER' ]; then
            $AUR_HELPER -Syu
        fi

        if command -v flatpak >/dev/null; then
            flatpak update
        fi

        echo
        echo 'Update finished.'
        read -n 1 -p 'Press any key to close...'
    "
    exit 0
fi

# ---------- CHECK UPDATES ----------
ofc=0
aur=0
fpk=0

if command -v checkupdates >/dev/null; then
    ofc=$(checkupdates 2>/dev/null | wc -l)
fi

if [ -n "$AUR_HELPER" ]; then
    aur=$("$AUR_HELPER" -Qua 2>/dev/null | wc -l)
fi

if pkg_installed flatpak; then
    fpk=$(flatpak remote-ls --updates 2>/dev/null | wc -l)
fi

total=$((ofc + aur + fpk))

cat >"$INFO_FILE" <<EOF
OFFICIAL_UPDATES=$ofc
AUR_UPDATES=$aur
FLATPAK_UPDATES=$fpk
EOF

if [ "$total" -eq 0 ]; then
    echo '{"text":"","tooltip":" Packages are up to date","class":"up-to-date"}'
else
    echo "{\"text\":\"󰮯 $total\",\"tooltip\":\"󱓽 Official $ofc\n󱓾 AUR $aur\n󰏓 Flatpak $fpk\",\"class\":\"has-updates\"}"
fi


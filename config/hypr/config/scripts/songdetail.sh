#!/bin/bash

CACHE="/tmp/hyprlock_album.jpg"

case "$1" in
  --title)
    playerctl metadata --format '{{ xesam:title }}' 2>/dev/null | awk '{print substr($0,1,45)}'
    ;;
  --artist)
    playerctl metadata --format '{{xesam:artist}}' 2>/dev/null | awk '{print substr($0,1,40)}'
    ;;
  --length)
    len=$(playerctl metadata --format '{{ mpris:length }}' 2>/dev/null)
    if [ -n "$len" ]; then
        total_sec=$((len / 1000000))
        h=$((total_sec / 3600))
        m=$(((total_sec % 3600) / 60))
        s=$((total_sec % 60))

        if [ "$h" -gt 0 ]; then
            printf "%d:%02d:%02d\n" "$h" "$m" "$s"
        else
            printf "%02d:%02d\n" "$m" "$s"
        fi
    fi
    ;;

  --source)
    id=$(playerctl metadata --format '{{ mpris:trackid }}' 2>/dev/null)
    [[ "$id" == *youtube* || "$id" == *firefox* || "$id" == *chromium* ]] && echo "YouTube "
    ;;
esac

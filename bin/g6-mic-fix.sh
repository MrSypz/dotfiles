#!/bin/bash

# Find the G6 card number
CARD=$(aplay -l | grep 'Sound BlasterX G6' | awk '{print $2}' | tr -d ':')

if [ -n "$CARD" ]; then
    amixer -c "$CARD" set 'PCM Capture Source' 'External Mic' >/dev/null
    amixer -c "$CARD" sset 'Input Gain Control' 3 >/dev/null  # Adjust value as needed (0-3 typical)
    echo "G6 mic configured to External Mic"
else
    echo "Sound Blaster G6 not detected"
fi
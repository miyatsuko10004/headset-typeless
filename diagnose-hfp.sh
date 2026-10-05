#!/bin/bash
set -euo pipefail
echo 'READY: observing Bluetooth HFP/voice-assistant system logs only.'
echo 'With the headset selected as the Typeless microphone, start using right Shift,'
echo 'then briefly press the headset button three times, five seconds apart. Ctrl+C stops.'
echo 'No output is inconclusive: macOS may not expose these commands in system logs.'
exec /usr/bin/log stream --level debug --style compact \
  --predicate 'process == "bluetoothd" AND (eventMessage CONTAINS[c] "BVRA" OR eventMessage CONTAINS[c] "voice recognition" OR eventMessage CONTAINS[c] "Voice Command")'

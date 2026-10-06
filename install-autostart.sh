#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Headset Typeless contributors
set -euo pipefail
project_dir="$(cd "$(dirname "$0")" && pwd)"
target="typeless"
media_only=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) [[ $# -ge 2 ]] || { echo 'Missing target' >&2; exit 2; }; target="$2"; shift 2 ;;
    --media-only) media_only="--media-only"; shift ;;
    *) echo 'Usage: install-autostart.sh [--target typeless|local-dictation] [--media-only]' >&2; exit 2 ;;
  esac
done
[[ "$target" == typeless || "$target" == local-dictation ]] || { echo 'Invalid target' >&2; exit 2; }
"$project_dir/build.sh"
agent_label="local.headset.typeless"
agent_path="$HOME/Library/LaunchAgents/$agent_label.plist"
log_dir="$HOME/Library/Logs/headset-typeless"
mkdir -p "$(dirname "$agent_path")" "$log_dir"
# plistlib escapes paths correctly, including XML special characters.
/usr/bin/python3 - "$agent_path" "$project_dir/headset-typeless" "$log_dir" "$target" "$media_only" <<'PY'
import plistlib
import sys
path, executable, logs, target, media_only = sys.argv[1:]
arguments = [executable, "--target", target]
if media_only:
    arguments.append(media_only)
with open(path, 'wb') as output:
    plistlib.dump({
        'Label': 'local.headset.typeless',
        'ProgramArguments': arguments,
        'RunAtLoad': True,
        'KeepAlive': True,
        'ThrottleInterval': 30,
        'LimitLoadToSessionType': 'Aqua',
        'StandardOutPath': logs + '/stdout.log',
        'StandardErrorPath': logs + '/stderr.log',
    }, output)
PY
launchctl bootout "gui/$(id -u)/$agent_label" 2>/dev/null || true
# bootout may return before launchd has fully removed the old registration.
started=false
for attempt in 1 2 3; do
    if launchctl bootstrap "gui/$(id -u)" "$agent_path"; then started=true; break; fi
    sleep 1
done
[[ "$started" == true ]] || { echo 'Could not start headset bridge' >&2; exit 1; }
echo "Installed login agent: $agent_path"
launchctl print "gui/$(id -u)/$agent_label"

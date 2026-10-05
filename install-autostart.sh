#!/bin/bash
set -euo pipefail
project_dir="$(cd "$(dirname "$0")" && pwd)"
"$project_dir/build.sh"
agent_label="local.as660.typeless"
agent_path="$HOME/Library/LaunchAgents/$agent_label.plist"
log_dir="$HOME/Library/Logs/as660-typeless"
mkdir -p "$(dirname "$agent_path")" "$log_dir"
# plistlib escapes paths correctly, including XML special characters.
/usr/bin/python3 - "$agent_path" "$project_dir/as660-typeless" "$log_dir" <<'PY'
import plistlib
import sys
path, executable, logs = sys.argv[1:]
with open(path, 'wb') as output:
    plistlib.dump({
        'Label': 'local.as660.typeless',
        'ProgramArguments': [executable],
        'RunAtLoad': True,
        'KeepAlive': True,
        'ThrottleInterval': 30,
        'LimitLoadToSessionType': 'Aqua',
        'StandardOutPath': logs + '/stdout.log',
        'StandardErrorPath': logs + '/stderr.log',
    }, output)
PY
launchctl bootout "gui/$(id -u)/$agent_label" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$agent_path"
echo "Installed login agent: $agent_path"
launchctl print "gui/$(id -u)/$agent_label"

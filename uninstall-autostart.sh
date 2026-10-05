#!/bin/bash
set -euo pipefail
agent_label="local.headset.typeless"
launchctl bootout "gui/$(id -u)/$agent_label" 2>/dev/null || true
rm -f "$HOME/Library/LaunchAgents/$agent_label.plist"
echo "Login agent removed. Source, executable and logs are preserved."

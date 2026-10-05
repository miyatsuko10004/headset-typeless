#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Headset Typeless contributors
set -euo pipefail
project_dir="$(cd "$(dirname "$0")" && pwd)"
agent_target="gui/$(id -u)/local.headset.typeless"
agent_path="$HOME/Library/LaunchAgents/local.headset.typeless.plist"
restore_agent=0
cleanup() {
  if [ "$restore_agent" = 1 ]; then
    launchctl bootstrap "gui/$(id -u)" "$agent_path" || echo 'Could not restore login agent; run install-autostart.sh.' >&2
  fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
if launchctl print "$agent_target" >/dev/null 2>&1; then
  launchctl bootout "$agent_target"
  restore_agent=1
  echo 'Normal login agent temporarily stopped; it will be restored on exit.'
fi
"$project_dir/hfp-log-experiment"

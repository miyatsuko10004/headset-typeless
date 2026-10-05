#!/bin/bash
set -euo pipefail
project_dir="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$project_dir/.build/module-cache"
swiftc -module-cache-path "$project_dir/.build/module-cache" \
  "$project_dir/typeless-bridge.swift" -o "$project_dir/headset-typeless" \
  -framework AppKit -framework MediaPlayer -framework CoreGraphics
echo "Built: $project_dir/headset-typeless"

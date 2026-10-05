#!/bin/bash
set -euo pipefail
project_dir="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$project_dir/.build/module-cache"
cp "$project_dir/typeless-bridge.swift" "$project_dir/.build/main.swift"
swiftc -module-cache-path "$project_dir/.build/module-cache" \
  "$project_dir/.build/main.swift" "$project_dir/HFPLogLines.swift" -o "$project_dir/headset-typeless" \
  -framework AppKit -framework MediaPlayer -framework CoreGraphics
echo "Built: $project_dir/headset-typeless"

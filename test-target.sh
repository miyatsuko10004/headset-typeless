#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Headset Typeless contributors
set -euo pipefail
project_dir="$(cd "$(dirname "$0")" && pwd)"
test_dir="$(mktemp -d)"
trap 'rm -rf "$test_dir"' EXIT
cat > "$test_dir/main.swift" <<'SWIFT'
import Foundation
let standard = try BridgeOptions(arguments: [])
precondition(standard.target == .typeless)
let local = try BridgeOptions(arguments: ["--target", "local-dictation", "--media-only"])
precondition(local.target == .localDictation && local.mediaOnly)
for arguments in [["--target"], ["--target", "other"], ["--unknown"]] {
 do { _ = try BridgeOptions(arguments: arguments); fatalError("Invalid options accepted") } catch {}
}
let check = try BridgeOptions(arguments: ["--check"])
precondition(check.check)
print("PASS: 6 target-option assertions")
SWIFT
swiftc -module-cache-path "$project_dir/.build/module-cache" "$test_dir/main.swift" "$project_dir/BridgeOptions.swift" -o "$test_dir/test"
"$test_dir/test"

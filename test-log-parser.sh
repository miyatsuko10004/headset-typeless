#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Headset Typeless contributors
set -euo pipefail
project_dir="$(cd "$(dirname "$0")" && pwd)"
test_dir="$(mktemp -d)"
trap 'rm -rf "$test_dir"' EXIT
cat > "$test_dir/main.swift" <<'SWIFT'
import Foundation
var parser = HFPLogLines()
let message = "Received End Voice Command - Deactivating Siri"
precondition(parser.feed(Data("Filtering predicate: \(message)\n".utf8)) == 0)
precondition(parser.feed(Data("2026-10-05 bluetoothd[428:123] Received End Voice".utf8)) == 0)
precondition(parser.feed(Data(" Command - Deactivating Siri for <private>\n".utf8)) == 1)
precondition(parser.feed(Data("bluetoothd[1:2] heySiriAdvertActive: NO\nother[1:2] \(message)\n".utf8)) == 0)
precondition(parser.feed(Data("bluetoothd[1:2] \(message)\nbluetoothd[1:2] \(message)\n".utf8)) == 2)
precondition(parser.feed(Data(repeating: 65, count: 70000)) == 0)
precondition(parser.feed(Data("bluetoothd[1:2] \(message)\n".utf8)) == 1)
print("PASS: 7 log-parser assertions")
SWIFT
swiftc -module-cache-path "$project_dir/.build/module-cache" "$test_dir/main.swift" "$project_dir/HFPLogLines.swift" -o "$test_dir/test"
"$test_dir/test"

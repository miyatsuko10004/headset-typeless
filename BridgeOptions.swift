// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Headset Typeless contributors
import Foundation
struct BridgeOptions {
    enum Target: String { case typeless; case localDictation = "local-dictation" }
    var target: Target = .typeless
    var mediaOnly = false
    var check = false
    init(arguments: [String]) throws {
        var index = 0
        while index < arguments.count {
            switch arguments[index] {
            case "--target":
                index += 1
                guard index < arguments.count, let value = Target(rawValue: arguments[index]) else { throw OptionError.invalid }
                target = value
            case "--media-only": mediaOnly = true
            case "--check": check = true
            default: throw OptionError.invalid
            }
            index += 1
        }
    }
    enum OptionError: Error { case invalid }
    static let toggleName = "local.manyo.LocalDictation.headsetToggle.v1"
}

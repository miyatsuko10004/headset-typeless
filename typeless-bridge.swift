// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Headset Typeless contributors

import AppKit
import MediaPlayer
import Foundation
import CoreGraphics

setbuf(stdout, nil)
let trustOptions = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
guard AXIsProcessTrustedWithOptions(trustOptions) else {
    print("Accessibility permission required. Allow this program or Terminal in System Settings > Privacy & Security > Accessibility, then run again.")
    exit(1)
}
var lastPress: TimeInterval = -.infinity
func pressRightShift(origin: String) {
    let now = ProcessInfo.processInfo.systemUptime
    guard now - lastPress >= 1 else { print("Ignored duplicate: \(origin)"); return }
    lastPress = now
    let source = CGEventSource(stateID: .privateState)
    guard let down = CGEvent(keyboardEventSource: source, virtualKey: 0x3c, keyDown: true),
          let up = CGEvent(keyboardEventSource: source, virtualKey: 0x3c, keyDown: false) else { return }
    down.type = .flagsChanged
    down.flags = .maskShift
    up.type = .flagsChanged
    up.flags = []
    down.post(tap: .cghidEventTap)
    usleep(80000)
    up.post(tap: .cghidEventTap)
    print("Sent right Shift tap [\(origin)]")
}
let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let center = MPRemoteCommandCenter.shared()
let commands: [(String, MPRemoteCommand)] = [
    ("PLAY", center.playCommand),
    ("PAUSE", center.pauseCommand),
    ("TOGGLE", center.togglePlayPauseCommand),
    ("STOP", center.stopCommand)
]
for (name, command) in commands {
    command.isEnabled = true
    command.addTarget { _ in
        print("\(Date()) RECEIVED: \(name)")
        DispatchQueue.main.async { pressRightShift(origin: name) }
        return .success
    }
}
let info = MPNowPlayingInfoCenter.default()
info.nowPlayingInfo = [
    MPMediaItemPropertyTitle: "Headset Typeless control",
    MPNowPlayingInfoPropertyIsLiveStream: true,
    MPNowPlayingInfoPropertyPlaybackRate: 1.0
]
info.playbackState = .playing
// System-log fallback for headset buttons while their microphone is active.
// This observes a notification; it does not intercept or suppress Siri.
let reader = Process()
let pipe = Pipe()
var lines = HFPLogLines()
if !CommandLine.arguments.contains("--media-only") {
    reader.executableURL = URL(fileURLWithPath: "/usr/bin/log")
    reader.arguments = ["stream", "--level", "debug", "--style", "compact", "--predicate",
        "process == \"bluetoothd\" AND eventMessage CONTAINS \"Received End Voice Command - Deactivating Siri\""]
    reader.standardOutput = pipe
    reader.standardError = FileHandle.standardError
    pipe.fileHandleForReading.readabilityHandler = { handle in
        let data = handle.availableData
        guard !data.isEmpty else { handle.readabilityHandler = nil; return }
        DispatchQueue.main.async {
            for _ in 0..<lines.feed(data) { pressRightShift(origin: "HFP log") }
        }
    }
    reader.terminationHandler = { process in
        DispatchQueue.main.async {
            print("HFP log reader exited: \(process.terminationStatus). Restart bridge to restore fallback.")
            info.playbackState = .stopped
            info.nowPlayingInfo = nil
            exit(1)
        }
    }
    do { try reader.run() }
    catch { print("Cannot start HFP log reader: \(error)"); exit(1) }
}
signal(SIGINT, SIG_IGN)
signal(SIGTERM, SIG_IGN)
let signals = [SIGINT, SIGTERM].map { number -> DispatchSourceSignal in
    let source = DispatchSource.makeSignalSource(signal: number, queue: .main)
    source.setEventHandler {
        reader.terminationHandler = nil
        pipe.fileHandleForReading.readabilityHandler = nil
        if reader.isRunning { reader.terminate(); reader.waitUntilExit() }
        info.playbackState = .stopped
        info.nowPlayingInfo = nil
        exit(0)
    }
    source.resume()
    return source
}
print("READY: media commands + HFP log fallback send right Shift. Ctrl+C stops.")
print("Other playback/voice-assistant controls can trigger this program; Siri is not suppressed.")
app.run()

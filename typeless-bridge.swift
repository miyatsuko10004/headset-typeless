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
var lastPress = Date.distantPast
func pressRightShift() {
    guard Date().timeIntervalSince(lastPress) > 0.4 else { return }
    lastPress = Date()
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
    print("Sent right Shift tap")
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
        pressRightShift()
        return .success
    }
}
let info = MPNowPlayingInfoCenter.default()
info.nowPlayingInfo = [
    MPMediaItemPropertyTitle: "AS660 Typeless control",
    MPNowPlayingInfoPropertyIsLiveStream: true,
    MPNowPlayingInfoPropertyPlaybackRate: 1.0
]
info.playbackState = .playing
signal(SIGINT, SIG_IGN)
let interrupt = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
interrupt.setEventHandler {
    info.playbackState = .stopped
    info.nowPlayingInfo = nil
    exit(0)
}
interrupt.resume()
print("READY: playback commands send one right Shift tap. Ctrl+C stops.")
print("Quit music/video apps first. Other playback controls can also trigger this program.")
app.run()

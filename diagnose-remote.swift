import AppKit
import MediaPlayer
import Foundation

setbuf(stdout, nil)
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
        return .success
    }
}
let info = MPNowPlayingInfoCenter.default()
info.nowPlayingInfo = [
    MPMediaItemPropertyTitle: "AS660 button diagnostic",
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
print("READY: remote-command diagnostic. No audio is played and no keys are sent.")
print("Quit music/video apps first. Test AS660 while Typeless is idle and dictating. Ctrl+C stops.")
print("macOS may route playback buttons to this diagnostic while it runs.")
app.run()

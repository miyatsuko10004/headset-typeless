import Foundation
import AppKit
import CoreGraphics

setbuf(stdout, nil)
let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
guard AXIsProcessTrustedWithOptions(options) else {
    print("Allow hfp-log-experiment in Accessibility, then run again.")
    exit(1)
}
let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let reader = Process()
reader.executableURL = URL(fileURLWithPath: "/usr/bin/log")
reader.arguments = ["stream", "--level", "debug", "--style", "compact", "--predicate",
    "process == \"bluetoothd\" AND eventMessage CONTAINS \"Received End Voice Command - Deactivating Siri\""]
let pipe = Pipe()
reader.standardOutput = pipe
reader.standardError = FileHandle.standardError
var pending = Data()
var lastSent: TimeInterval = -.infinity
pipe.fileHandleForReading.readabilityHandler = { handle in
    let data = handle.availableData
    guard !data.isEmpty else { handle.readabilityHandler = nil; return }
    DispatchQueue.main.async {
        pending.append(data)
        while let newline = pending.firstIndex(of: 10) {
            let line = String(decoding: pending[..<newline], as: UTF8.self)
            pending.removeSubrange(...newline)
            // Require an actual log row, not log's predicate announcement.
            guard line.contains("bluetoothd["),
                  line.contains("Received End Voice Command - Deactivating Siri") else { continue }
            let now = ProcessInfo.processInfo.systemUptime
            guard now - lastSent >= 1 else { print("Ignored duplicate notification"); continue }
            lastSent = now
            let source = CGEventSource(stateID: .privateState)
            guard let down = CGEvent(keyboardEventSource: source, virtualKey: 0x3c, keyDown: true),
                  let up = CGEvent(keyboardEventSource: source, virtualKey: 0x3c, keyDown: false) else { continue }
            down.type = .flagsChanged
            down.flags = .maskShift
            up.type = .flagsChanged
            up.flags = []
            down.post(tap: .cghidEventTap)
            usleep(80000)
            up.post(tap: .cghidEventTap)
            print("HFP log detected → sent right Shift tap")
        }
        if pending.count > 65536 { pending.removeAll() }
    }
}
reader.terminationHandler = { process in
    DispatchQueue.main.async {
        print("Log reader exited: \(process.terminationStatus)")
        exit(1)
    }
}
do { try reader.run() } catch { print("Cannot start log reader: \(error)"); exit(1) }
signal(SIGINT, SIG_IGN)
signal(SIGTERM, SIG_IGN)
let signals = [SIGINT, SIGTERM].map { number -> DispatchSourceSignal in
    let signalSource = DispatchSource.makeSignalSource(signal: number, queue: .main)
    signalSource.setEventHandler {
        reader.terminationHandler = nil
        pipe.fileHandleForReading.readabilityHandler = nil
        if reader.isRunning { reader.terminate(); reader.waitUntilExit() }
        exit(0)
    }
    signalSource.resume()
    return signalSource
}
print("READY: HFP log experiment. Start Typeless using physical right Shift, then press headset button once.")
print("This does not suppress Siri or identify the headset. Ctrl+C stops.")
app.run()


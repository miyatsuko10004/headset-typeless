import AppKit
import CoreGraphics
import Foundation

// Listen only: never suppress events or generate keyboard input.
setbuf(stdout, nil)
let systemDefined = CGEventType(rawValue: 14)!
let callback: CGEventTapCallBack = { _, type, event, _ in
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        print("Event monitor disabled. Restart this program.")
        return Unmanaged.passUnretained(event)
    }
    if let ns = NSEvent(cgEvent: event) {
        let key = (ns.data1 >> 16) & 0xffff
        let state = (ns.data1 >> 8) & 0xff
        let label = key == 16 ? "PLAY/PAUSE" : "other"
        print("\(Date()) systemDefined subtype=\(ns.subtype.rawValue) key=\(key) state=\(state) data1=\(ns.data1) \(label)")
    }
    return Unmanaged.passUnretained(event)
}

guard let tap = CGEvent.tapCreate(
    tap: .cgSessionEventTap,
    place: .headInsertEventTap,
    options: .listenOnly,
    eventsOfInterest: CGEventMask(1) << systemDefined.rawValue,
    callback: callback,
    userInfo: nil
) else {
    print("Cannot start event monitor. Allow Terminal in System Settings > Privacy & Security > Input Monitoring, then quit and reopen Terminal.")
    exit(1)
}
let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
CGEvent.tapEnable(tap: tap, enable: true)
print("READY: listening only. Press headset button while Typeless is idle, then while dictating. Ctrl+C stops.")
print("No output does not prove no Bluetooth signal: this tests only system-defined events visible to CGEventTap.")
CFRunLoopRun()

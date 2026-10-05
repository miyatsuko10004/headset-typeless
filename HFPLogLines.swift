import Foundation

struct HFPLogLines {
    private var pending = Data()
    mutating func feed(_ data: Data) -> Int {
        pending.append(data)
        var matches = 0
        while let newline = pending.firstIndex(of: 10) {
            let line = String(decoding: pending[..<newline], as: UTF8.self)
            pending.removeSubrange(...newline)
            if line.contains("bluetoothd["),
               line.contains("Received End Voice Command - Deactivating Siri") {
                matches += 1
            }
        }
        if pending.count > 65536 { pending.removeAll() }
        return matches
    }
}

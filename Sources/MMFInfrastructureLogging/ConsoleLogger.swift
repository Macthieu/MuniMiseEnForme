import Foundation
import MMFCore

public struct ConsoleLogger: MMFLogger {
    public init() {}

    public func info(_ message: String) {
        print("[INFO] \(message)")
    }

    public func warning(_ message: String) {
        fputs("[WARN] \(message)\n", stderr)
    }

    public func error(_ message: String) {
        fputs("[ERROR] \(message)\n", stderr)
    }
}

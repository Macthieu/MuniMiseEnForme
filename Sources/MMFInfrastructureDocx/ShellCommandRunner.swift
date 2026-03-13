import Foundation
import MMFCore

public struct ShellCommandRunner: Sendable {
    public init() {}

    @discardableResult
    public func run(
        executable: String,
        arguments: [String],
        currentDirectoryURL: URL? = nil
    ) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.currentDirectoryURL = currentDirectoryURL

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        try process.run()
        process.waitUntilExit()

        let outputData = stdout.fileHandleForReading.readDataToEndOfFile()
        let errorData = stderr.fileHandleForReading.readDataToEndOfFile()

        if process.terminationStatus != 0 {
            let errorMessage = String(data: errorData, encoding: .utf8) ?? "Commande shell en echec"
            throw MMFError.ioFailure(errorMessage.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        return String(data: outputData, encoding: .utf8) ?? ""
    }
}

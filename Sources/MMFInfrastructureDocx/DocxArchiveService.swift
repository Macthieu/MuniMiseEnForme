import Foundation
import MMFCore

public struct DocxArchiveService: Sendable {
    private let shell = ShellCommandRunner()

    public init() {}

    public func unzip(docxURL: URL) throws -> URL {
        let tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("muni-mise-en-forme", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)

        try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)

        // ditto preserve mieux la structure docx sur macOS.
        try shell.run(
            executable: "/usr/bin/ditto",
            arguments: ["-x", "-k", docxURL.path, tempRoot.path]
        )

        return tempRoot
    }

    public func zip(folderURL: URL, outputDocxURL: URL) throws {
        let outputFolder = outputDocxURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: outputFolder, withIntermediateDirectories: true)

        if FileManager.default.fileExists(atPath: outputDocxURL.path) {
            try FileManager.default.removeItem(at: outputDocxURL)
        }

        try shell.run(
            executable: "/usr/bin/zip",
            arguments: ["-X", "-r", outputDocxURL.path, "."],
            currentDirectoryURL: folderURL
        )
    }
}

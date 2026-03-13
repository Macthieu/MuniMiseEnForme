import Foundation
import MMFCore
import MMFDomain

public struct ValidationReportJSONWriter: ValidationReportWriter {
    public init() {}

    public func write(validation: ValidationSummary, to outputURL: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let data = try encoder.encode(validation)

        let folder = outputURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try data.write(to: outputURL)
    }
}

public struct OutputPathResolver: Sendable {
    public init() {}

    public func resolveOutputURL(for sourceURL: URL, in outputDirectory: URL? = nil) -> URL {
        let directory = outputDirectory ?? sourceURL.deletingLastPathComponent()
        let basename = sourceURL.deletingPathExtension().lastPathComponent
        let timestamp = OutputPathResolver.timestampFormatter.string(from: Date())
        let filename = "\(basename)_muni_mise_en_forme_\(timestamp).docx"
        return directory.appendingPathComponent(filename)
    }

    public func resolveReportURL(for outputURL: URL) -> URL {
        outputURL
            .deletingPathExtension()
            .appendingPathExtension("validation.json")
    }

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter
    }()
}

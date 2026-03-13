import Foundation
import MMFCore

public struct TemplateStyleInspector: Sendable {
    private let archiveService = DocxArchiveService()

    public init() {}

    public func extractStyleIDs(fromDocx docxURL: URL) throws -> Set<String> {
        let unzippedURL = try archiveService.unzip(docxURL: docxURL)
        let stylesXMLURL = unzippedURL
            .appendingPathComponent("word", isDirectory: true)
            .appendingPathComponent("styles.xml")

        guard FileManager.default.fileExists(atPath: stylesXMLURL.path) else {
            throw MMFError.renderingFailure("Le gabarit DOCX ne contient pas word/styles.xml")
        }

        let xml = try String(contentsOf: stylesXMLURL, encoding: .utf8)
        let regex = try NSRegularExpression(pattern: #"<w:style\b[^>]*w:styleId=\"([^\"]+)\""#)
        let range = NSRange(xml.startIndex..<xml.endIndex, in: xml)

        var styleIDs: Set<String> = []
        for match in regex.matches(in: xml, range: range) {
            guard match.numberOfRanges > 1, let styleRange = Range(match.range(at: 1), in: xml) else {
                continue
            }
            styleIDs.insert(String(xml[styleRange]))
        }

        return styleIDs
    }
}

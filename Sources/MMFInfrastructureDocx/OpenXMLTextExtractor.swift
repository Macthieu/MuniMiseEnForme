import Foundation
import MMFCore
import MMFDomain

public struct OpenXMLTextExtractor: Sendable {
    public init() {}

    public func extractElements(fromDocx docxURL: URL) throws -> [ExtractedElement] {
        let archive = DocxArchiveService()
        let unzippedURL = try archive.unzip(docxURL: docxURL)
        let documentXMLURL = unzippedURL
            .appendingPathComponent("word", isDirectory: true)
            .appendingPathComponent("document.xml")

        guard FileManager.default.fileExists(atPath: documentXMLURL.path) else {
            throw MMFError.extractionFailure("word/document.xml introuvable dans le DOCX")
        }

        let xml = try String(contentsOf: documentXMLURL, encoding: .utf8)
        let paragraphPattern = #"(?s)<w:p\b.*?</w:p>"#
        let paragraphRegex = try NSRegularExpression(pattern: paragraphPattern)

        let nsRange = NSRange(xml.startIndex..<xml.endIndex, in: xml)
        let paragraphMatches = paragraphRegex.matches(in: xml, range: nsRange)

        var elements: [ExtractedElement] = []
        elements.reserveCapacity(paragraphMatches.count)

        for (index, match) in paragraphMatches.enumerated() {
            guard let range = Range(match.range, in: xml) else { continue }
            let paragraphXML = String(xml[range])
            let text = extractText(fromParagraphXML: paragraphXML).trimmingCharacters(in: .whitespacesAndNewlines)
            if text.isEmpty { continue }

            let styleHint = extractStyleHint(fromParagraphXML: paragraphXML)
            let inferredKind = inferKind(text: text, styleHint: styleHint)

            elements.append(
                ExtractedElement(
                    order: index + 1,
                    kind: inferredKind,
                    text: text,
                    styleHint: styleHint
                )
            )
        }

        return elements
    }

    private func extractText(fromParagraphXML paragraphXML: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: #"<w:t[^>]*>(.*?)</w:t>"#, options: [.dotMatchesLineSeparators]) else {
            return ""
        }

        let nsRange = NSRange(paragraphXML.startIndex..<paragraphXML.endIndex, in: paragraphXML)
        let matches = regex.matches(in: paragraphXML, range: nsRange)

        let parts = matches.compactMap { match -> String? in
            guard match.numberOfRanges > 1,
                  let range = Range(match.range(at: 1), in: paragraphXML)
            else {
                return nil
            }
            return decodeXMLEntities(String(paragraphXML[range]))
        }

        return parts.joined(separator: "")
    }

    private func extractStyleHint(fromParagraphXML paragraphXML: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: #"<w:pStyle[^>]*w:val=\"([^\"]+)\""#) else {
            return nil
        }

        let nsRange = NSRange(paragraphXML.startIndex..<paragraphXML.endIndex, in: paragraphXML)
        guard
            let match = regex.firstMatch(in: paragraphXML, range: nsRange),
            match.numberOfRanges > 1,
            let range = Range(match.range(at: 1), in: paragraphXML)
        else {
            return nil
        }

        return String(paragraphXML[range])
    }

    private func inferKind(text: String, styleHint: String?) -> ExtractedElementKind {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowerStyle = styleHint?.lowercased() ?? ""

        if lowerStyle.contains("heading") || lowerStyle.contains("titre") {
            return .heading
        }

        if trimmed.hasPrefix("SECTION ") {
            return .heading
        }

        if trimmed.range(of: #"^\d+\.\d+\.\d+\.?\s"#, options: .regularExpression) != nil {
            return .heading
        }

        if trimmed.range(of: #"^\d+\.\d+\.?\s"#, options: .regularExpression) != nil {
            return .heading
        }

        if trimmed.range(of: #"^\d+\.\s"#, options: .regularExpression) != nil {
            return .heading
        }

        if trimmed.range(of: #"^[a-z]\)\s"#, options: .regularExpression) != nil {
            return .letteredList
        }

        if trimmed.hasPrefix("•") || trimmed.hasPrefix("-") || trimmed.hasPrefix("*") {
            return .bullet
        }

        return .paragraph
    }

    private func decodeXMLEntities(_ text: String) -> String {
        var decoded = text
        let replacements: [(String, String)] = [
            ("&amp;", "&"),
            ("&lt;", "<"),
            ("&gt;", ">"),
            ("&quot;", "\""),
            ("&apos;", "'"),
            ("&#10;", "\n"),
            ("&#13;", "")
        ]

        for (entity, value) in replacements {
            decoded = decoded.replacingOccurrences(of: entity, with: value)
        }

        return decoded
    }
}

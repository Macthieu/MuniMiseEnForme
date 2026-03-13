import Foundation
import MMFCore
import MMFDomain

public struct OpenXMLDocxComposer: Sendable {
    private let archiveService = DocxArchiveService()

    public init() {}

    public func compose(
        normalizedDocument: NormalizedDocument,
        templateURL: URL,
        outputURL: URL
    ) throws {
        let workingURL = try archiveService.unzip(docxURL: templateURL)
        let documentXMLURL = workingURL
            .appendingPathComponent("word", isDirectory: true)
            .appendingPathComponent("document.xml")

        guard FileManager.default.fileExists(atPath: documentXMLURL.path) else {
            throw MMFError.renderingFailure("Le gabarit DOCX ne contient pas word/document.xml")
        }

        var xml = try String(contentsOf: documentXMLURL, encoding: .utf8)

        let metadataTokens = metadataTokenMap(document: normalizedDocument)
        for (token, value) in metadataTokens {
            xml = xml.replacingOccurrences(of: token, with: xmlEscaped(value))
        }

        let bodyXML = buildBodyXML(from: normalizedDocument.blocs)
        if xml.contains("{{BODY_BLOCKS}}") {
            xml = xml.replacingOccurrences(of: "{{BODY_BLOCKS}}", with: bodyXML)
        } else if let range = xml.range(of: "</w:body>", options: .backwards) {
            xml.insert(contentsOf: bodyXML, at: range.lowerBound)
        }

        try xml.write(to: documentXMLURL, atomically: true, encoding: .utf8)
        try archiveService.zip(folderURL: workingURL, outputDocxURL: outputURL)
    }

    private func metadataTokenMap(document: NormalizedDocument) -> [String: String] {
        [
            "{{document.type_document}}": document.document.typeDocument,
            "{{document.titre_long}}": document.document.titreLong,
            "{{document.titre_court}}": document.document.titreCourt,
            "{{document.code_document}}": document.document.codeDocument,
            "{{document.domaine}}": document.document.domaine,
            "{{document.version}}": document.document.version,
            "{{document.date_document}}": document.document.dateDocument,
            "{{document.resolution}}": document.document.resolution,
            "{{acteurs.service_responsable}}": document.acteurs.serviceResponsable,
            "{{acteurs.approbateur}}": document.acteurs.approbateur
        ]
    }

    private func buildBodyXML(from blocks: [DocumentBlock]) -> String {
        blocks
            .sorted { $0.ordre < $1.ordre }
            .map { block in
                let text = xmlEscaped(block.texte)
                let style = block.style.rawValue
                return """
                <w:p>
                  <w:pPr><w:pStyle w:val=\"\(style)\"/></w:pPr>
                  <w:r><w:t xml:space=\"preserve\">\(text)</w:t></w:r>
                </w:p>
                """
            }
            .joined(separator: "\n")
    }

    private func xmlEscaped(_ text: String) -> String {
        var value = text
        let replacements: [(String, String)] = [
            ("&", "&amp;"),
            ("<", "&lt;"),
            (">", "&gt;"),
            ("\"", "&quot;"),
            ("'", "&apos;")
        ]
        for (source, target) in replacements {
            value = value.replacingOccurrences(of: source, with: target)
        }
        return value
    }
}

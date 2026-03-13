import Foundation
import MMFCore
import MMFDomain
import MMFInfrastructureDocx

public struct BasicDocxExtractor: DocumentExtractor {
    private let openXMLExtractor: OpenXMLTextExtractor

    public init(openXMLExtractor: OpenXMLTextExtractor = OpenXMLTextExtractor()) {
        self.openXMLExtractor = openXMLExtractor
    }

    public func extract(from importedDocument: ImportedDocument) throws -> ExtractedDocument {
        let elements = try openXMLExtractor.extractElements(fromDocx: importedDocument.sourceURL)
        return ExtractedDocument(sourcePath: importedDocument.sourceURL.path, elements: elements)
    }
}

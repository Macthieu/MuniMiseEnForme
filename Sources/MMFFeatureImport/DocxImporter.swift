import Foundation
import MMFCore
import MMFDomain

public struct DocxImporter: DocumentImporter {
    public init() {}

    public func importDocument(from sourceURL: URL) throws -> ImportedDocument {
        guard sourceURL.pathExtension.lowercased() == "docx" else {
            throw MMFError.invalidInput("Le fichier source doit avoir l'extension .docx")
        }

        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: sourceURL.path, isDirectory: &isDirectory), !isDirectory.boolValue else {
            throw MMFError.invalidInput("Le fichier source est introuvable: \(sourceURL.path)")
        }

        return ImportedDocument(sourceURL: sourceURL)
    }
}

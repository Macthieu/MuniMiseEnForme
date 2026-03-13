import Foundation
import MMFCore
import MMFDomain
import MMFInfrastructureDocx

public struct TemplateDocxRenderer: TemplateRenderer {
    private let composer: OpenXMLDocxComposer
    private let styleInspector: TemplateStyleInspector
    private let strictStyleValidation: Bool

    public init(
        composer: OpenXMLDocxComposer = OpenXMLDocxComposer(),
        styleInspector: TemplateStyleInspector = TemplateStyleInspector(),
        strictStyleValidation: Bool = true
    ) {
        self.composer = composer
        self.styleInspector = styleInspector
        self.strictStyleValidation = strictStyleValidation
    }

    public func render(document: NormalizedDocument, templateURL: URL, outputURL: URL) throws {
        guard templateURL.pathExtension.lowercased() == "docx" else {
            throw MMFError.invalidInput("Le gabarit doit etre un fichier .docx")
        }

        if strictStyleValidation {
            let availableStyles = try styleInspector.extractStyleIDs(fromDocx: templateURL)
            let requiredStyles = Set(DocumentStyle.allCases.map(\.rawValue))
            let missingStyles = requiredStyles.subtracting(availableStyles).sorted()

            if !missingStyles.isEmpty {
                throw MMFError.renderingFailure(
                    "Le gabarit ne contient pas tous les styles requis. Manquants: \(missingStyles.joined(separator: ", "))"
                )
            }
        }

        try composer.compose(
            normalizedDocument: document,
            templateURL: templateURL,
            outputURL: outputURL
        )
    }
}

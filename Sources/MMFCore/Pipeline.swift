import Foundation
import MMFDomain

public protocol MMFLogger: Sendable {
    func info(_ message: String)
    func warning(_ message: String)
    func error(_ message: String)
}

public protocol DocumentImporter: Sendable {
    func importDocument(from sourceURL: URL) throws -> ImportedDocument
}

public protocol DocumentExtractor: Sendable {
    func extract(from importedDocument: ImportedDocument) throws -> ExtractedDocument
}

public protocol ContentStructurer: Sendable {
    func structure(from extractedDocument: ExtractedDocument) async throws -> NormalizedDocument
}

public protocol DocumentValidator: Sendable {
    func validate(document: inout NormalizedDocument) -> ValidationSummary
}

public protocol TemplateRenderer: Sendable {
    func render(document: NormalizedDocument, templateURL: URL, outputURL: URL) throws
}

public protocol ValidationReportWriter: Sendable {
    func write(validation: ValidationSummary, to outputURL: URL) throws
}

public enum MMFError: Error, LocalizedError {
    case invalidInput(String)
    case ioFailure(String)
    case extractionFailure(String)
    case structuringFailure(String)
    case validationFailure(String)
    case renderingFailure(String)
    case unsupported(String)

    public var errorDescription: String? {
        switch self {
        case .invalidInput(let message):
            return "Entrée invalide: \(message)"
        case .ioFailure(let message):
            return "Erreur d'entrée/sortie: \(message)"
        case .extractionFailure(let message):
            return "Erreur d'extraction: \(message)"
        case .structuringFailure(let message):
            return "Erreur de structuration: \(message)"
        case .validationFailure(let message):
            return "Erreur de validation: \(message)"
        case .renderingFailure(let message):
            return "Erreur de génération documentaire: \(message)"
        case .unsupported(let message):
            return "Fonction non prise en charge: \(message)"
        }
    }
}

public struct PipelineRequest: Sendable {
    public let sourceURL: URL
    public let templateURL: URL?
    public let outputURL: URL?
    public let reportURL: URL?

    public init(sourceURL: URL, templateURL: URL? = nil, outputURL: URL? = nil, reportURL: URL? = nil) {
        self.sourceURL = sourceURL
        self.templateURL = templateURL
        self.outputURL = outputURL
        self.reportURL = reportURL
    }
}

public struct PipelineDependencies: Sendable {
    public let importer: DocumentImporter
    public let extractor: DocumentExtractor
    public let structurer: ContentStructurer
    public let validator: DocumentValidator
    public let renderer: TemplateRenderer?
    public let reportWriter: ValidationReportWriter?
    public let logger: MMFLogger

    public init(
        importer: DocumentImporter,
        extractor: DocumentExtractor,
        structurer: ContentStructurer,
        validator: DocumentValidator,
        renderer: TemplateRenderer?,
        reportWriter: ValidationReportWriter?,
        logger: MMFLogger
    ) {
        self.importer = importer
        self.extractor = extractor
        self.structurer = structurer
        self.validator = validator
        self.renderer = renderer
        self.reportWriter = reportWriter
        self.logger = logger
    }
}

public struct DocumentPipeline: Sendable {
    private let dependencies: PipelineDependencies

    public init(dependencies: PipelineDependencies) {
        self.dependencies = dependencies
    }

    @discardableResult
    public func run(request: PipelineRequest) async throws -> PipelineOutput {
        dependencies.logger.info("Import du document source: \(request.sourceURL.path)")
        let imported = try dependencies.importer.importDocument(from: request.sourceURL)

        dependencies.logger.info("Extraction de la structure DOCX")
        let extracted = try dependencies.extractor.extract(from: imported)

        dependencies.logger.info("Structuration du contenu en JSON normalise")
        var normalized = try await dependencies.structurer.structure(from: extracted)

        dependencies.logger.info("Validation du JSON structure")
        let validation = dependencies.validator.validate(document: &normalized)
        normalized.validation = validation

        if
            let templateURL = request.templateURL,
            let outputURL = request.outputURL,
            let renderer = dependencies.renderer
        {
            dependencies.logger.info("Generation du DOCX final depuis le gabarit")
            try renderer.render(document: normalized, templateURL: templateURL, outputURL: outputURL)
        }

        if let reportURL = request.reportURL, let reportWriter = dependencies.reportWriter {
            dependencies.logger.info("Ecriture du rapport de validation")
            try reportWriter.write(validation: normalized.validation, to: reportURL)
        }

        return PipelineOutput(
            normalizedDocument: normalized,
            outputDocumentURL: request.outputURL,
            validationReportURL: request.reportURL
        )
    }
}

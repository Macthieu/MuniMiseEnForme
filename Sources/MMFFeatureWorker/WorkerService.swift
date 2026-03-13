import Foundation
import MMFCore
import MMFDomain
import MMFFeatureImport
import MMFFeatureExtraction
import MMFFeatureStructuring
import MMFFeatureValidation
import MMFFeatureTemplateEngine
import MMFFeatureOutput

public struct WorkerRequest: Codable, Sendable {
    public enum StructuringMode: String, Codable, Sendable, Hashable {
        case foundationModelsPreferred
        case deterministicOnly
    }

    public let sourceDocxPath: String
    public let templateDocxPath: String?
    public let outputDocxPath: String?
    public let reportPath: String?
    public let structuringMode: StructuringMode
    public let contractVersion: String?

    public init(
        sourceDocxPath: String,
        templateDocxPath: String? = nil,
        outputDocxPath: String? = nil,
        reportPath: String? = nil,
        structuringMode: StructuringMode = .foundationModelsPreferred,
        contractVersion: String? = "1.0"
    ) {
        self.sourceDocxPath = sourceDocxPath
        self.templateDocxPath = templateDocxPath
        self.outputDocxPath = outputDocxPath
        self.reportPath = reportPath
        self.structuringMode = structuringMode
        self.contractVersion = contractVersion
    }

    enum CodingKeys: String, CodingKey {
        case sourceDocxPath = "source_docx"
        case templateDocxPath = "template_docx"
        case outputDocxPath = "output_docx"
        case reportPath = "report_json"
        case structuringMode = "structuring_mode"
        case contractVersion = "contract_version"
    }
}

public struct WorkerResponse: Codable, Sendable {
    public let contractVersion: String
    public let success: Bool
    public let outputDocxPath: String?
    public let normalizedJsonPath: String?
    public let reportPath: String?
    public let warnings: [String]
    public let errors: [String]

    public init(
        contractVersion: String = "1.0",
        success: Bool,
        outputDocxPath: String?,
        normalizedJsonPath: String?,
        reportPath: String?,
        warnings: [String] = [],
        errors: [String] = []
    ) {
        self.contractVersion = contractVersion
        self.success = success
        self.outputDocxPath = outputDocxPath
        self.normalizedJsonPath = normalizedJsonPath
        self.reportPath = reportPath
        self.warnings = warnings
        self.errors = errors
    }

    enum CodingKeys: String, CodingKey {
        case contractVersion = "contract_version"
        case success
        case outputDocxPath = "output_docx"
        case normalizedJsonPath = "normalized_json"
        case reportPath = "report_json"
        case warnings
        case errors
    }
}

public struct WorkerService: Sendable {
    private let logger: MMFLogger

    public init(logger: MMFLogger) {
        self.logger = logger
    }

    public func run(request: WorkerRequest, normalizedJSONOutputURL: URL?) async -> WorkerResponse {
        do {
            var warnings: [String] = []
            if let version = request.contractVersion, version != "1.0" {
                warnings.append("Version de contrat worker non nominale: \(version). Version attendue: 1.0")
            }

            let sourceURL = URL(fileURLWithPath: request.sourceDocxPath)
            let templateURL = request.templateDocxPath.map { URL(fileURLWithPath: $0) }
            let outputURL = request.outputDocxPath.map { URL(fileURLWithPath: $0) }
            let reportURL = request.reportPath.map { URL(fileURLWithPath: $0) }

            let structuringMode: DocumentStructurer.Mode = request.structuringMode == .foundationModelsPreferred
                ? .foundationModelsPreferred
                : .deterministicOnly

            let dependencies = PipelineDependencies(
                importer: DocxImporter(),
                extractor: BasicDocxExtractor(),
                structurer: DocumentStructurer(mode: structuringMode),
                validator: DocumentJSONValidator(),
                renderer: templateURL == nil ? nil : TemplateDocxRenderer(),
                reportWriter: reportURL == nil ? nil : ValidationReportJSONWriter(),
                logger: logger
            )

            let pipeline = DocumentPipeline(dependencies: dependencies)
            let output = try await pipeline.run(
                request: PipelineRequest(
                    sourceURL: sourceURL,
                    templateURL: templateURL,
                    outputURL: outputURL,
                    reportURL: reportURL
                )
            )

            if let normalizedJSONOutputURL {
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
                let data = try encoder.encode(output.normalizedDocument)
                let folder = normalizedJSONOutputURL.deletingLastPathComponent()
                try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
                try data.write(to: normalizedJSONOutputURL)
            }

            return WorkerResponse(
                contractVersion: "1.0",
                success: true,
                outputDocxPath: output.outputDocumentURL?.path,
                normalizedJsonPath: normalizedJSONOutputURL?.path,
                reportPath: output.validationReportURL?.path,
                warnings: warnings + output.normalizedDocument.validation.commentaires,
                errors: []
            )
        } catch {
            logger.error(error.localizedDescription)
            return WorkerResponse(
                contractVersion: "1.0",
                success: false,
                outputDocxPath: nil,
                normalizedJsonPath: nil,
                reportPath: nil,
                warnings: [],
                errors: [error.localizedDescription]
            )
        }
    }
}

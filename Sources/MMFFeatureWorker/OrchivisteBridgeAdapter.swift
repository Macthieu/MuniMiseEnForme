import Foundation
import OrchivisteKitContracts

public struct OrchivisteExecutionPlan: Sendable {
    public let workerRequest: WorkerRequest
    public let normalizedJSONOutputURL: URL?

    public init(workerRequest: WorkerRequest, normalizedJSONOutputURL: URL?) {
        self.workerRequest = workerRequest
        self.normalizedJSONOutputURL = normalizedJSONOutputURL
    }
}

public enum OrchivisteBridgeError: Error, Sendable {
    case unsupportedAction(String)
    case missingParameter(String)
    case invalidParameter(String, String)

    public var toolError: ToolError {
        switch self {
        case .unsupportedAction(let action):
            return ToolError(
                code: "UNSUPPORTED_ACTION",
                message: "Unsupported action: \(action)",
                retryable: false
            )
        case .missingParameter(let parameter):
            return ToolError(
                code: "MISSING_PARAMETER",
                message: "Missing required parameter: \(parameter)",
                retryable: false
            )
        case .invalidParameter(let parameter, let reason):
            return ToolError(
                code: "INVALID_PARAMETER",
                message: "Invalid parameter \(parameter): \(reason)",
                retryable: false
            )
        }
    }
}

public enum OrchivisteBridgeAdapter {
    public static func makeExecutionPlan(from request: ToolRequest) throws -> OrchivisteExecutionPlan {
        let action = request.action.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let sourcePath = try resolveSourcePath(from: request)
        let mode = try resolveStructuringMode(from: request)
        let normalizedPath = try optionalStringParameter("normalized_json", in: request)

        switch action {
        case "run":
            let templatePath = try optionalStringParameter("template_docx", in: request)
            let outputPath = try optionalStringParameter("output_docx", in: request)
            let reportPath = try optionalStringParameter("report_json", in: request)
            return OrchivisteExecutionPlan(
                workerRequest: WorkerRequest(
                    sourceDocxPath: sourcePath,
                    templateDocxPath: templatePath,
                    outputDocxPath: outputPath,
                    reportPath: reportPath,
                    structuringMode: mode,
                    contractVersion: request.schemaVersion.rawValue
                ),
                normalizedJSONOutputURL: normalizedPath.map { URL(fileURLWithPath: $0) }
            )
        case "analyze":
            return OrchivisteExecutionPlan(
                workerRequest: WorkerRequest(
                    sourceDocxPath: sourcePath,
                    templateDocxPath: nil,
                    outputDocxPath: nil,
                    reportPath: nil,
                    structuringMode: mode,
                    contractVersion: request.schemaVersion.rawValue
                ),
                normalizedJSONOutputURL: normalizedPath.map { URL(fileURLWithPath: $0) }
            )
        default:
            throw OrchivisteBridgeError.unsupportedAction(request.action)
        }
    }

    public static func makeResult(
        for request: ToolRequest,
        response: WorkerResponse,
        startedAt: String,
        finishedAt: String
    ) -> ToolResult {
        let status = status(for: response)
        let summary: String
        switch status {
        case .succeeded:
            summary = "Worker execution completed successfully."
        case .needsReview:
            summary = "Worker execution completed with warnings."
        default:
            summary = "Worker execution failed."
        }

        let progressEvents = [
            ProgressEvent(
                requestID: request.requestID,
                status: .running,
                stage: "pipeline",
                percent: 10,
                message: "Pipeline execution started.",
                occurredAt: startedAt
            ),
            ProgressEvent(
                requestID: request.requestID,
                status: status,
                stage: "pipeline_complete",
                percent: 100,
                message: summary,
                occurredAt: finishedAt,
                metadata: [
                    "warning_count": .number(Double(response.warnings.count)),
                    "error_count": .number(Double(response.errors.count))
                ]
            )
        ]

        return ToolResult(
            requestID: request.requestID,
            tool: request.tool,
            status: status,
            startedAt: startedAt,
            finishedAt: finishedAt,
            progressEvents: progressEvents,
            outputArtifacts: artifacts(from: response),
            errors: toolErrors(from: response),
            summary: summary,
            metadata: resultMetadata(from: response)
        )
    }

    public static func makeFailureResult(
        for request: ToolRequest,
        startedAt: String,
        finishedAt: String,
        error: ToolError
    ) -> ToolResult {
        let summary = "Request adaptation failed before worker execution."
        let progressEvents = [
            ProgressEvent(
                requestID: request.requestID,
                status: .running,
                stage: "adapter",
                percent: 10,
                message: "Validating canonical request.",
                occurredAt: startedAt
            ),
            ProgressEvent(
                requestID: request.requestID,
                status: .failed,
                stage: "adapter_failed",
                percent: 100,
                message: summary,
                occurredAt: finishedAt
            )
        ]

        return ToolResult(
            requestID: request.requestID,
            tool: request.tool,
            status: .failed,
            startedAt: startedAt,
            finishedAt: finishedAt,
            progressEvents: progressEvents,
            outputArtifacts: [],
            errors: [error],
            summary: summary,
            metadata: [:]
        )
    }

    private static func status(for response: WorkerResponse) -> ToolStatus {
        if !response.success || !response.errors.isEmpty {
            return .failed
        }
        if !response.warnings.isEmpty {
            return .needsReview
        }
        return .succeeded
    }

    private static func toolErrors(from response: WorkerResponse) -> [ToolError] {
        guard !response.errors.isEmpty else {
            return []
        }

        return response.errors.enumerated().map { index, message in
            ToolError(
                code: "WORKER_EXECUTION_FAILED",
                message: message,
                details: [
                    "index": .number(Double(index)),
                    "worker_contract_version": .string(response.contractVersion)
                ],
                retryable: false
            )
        }
    }

    private static func artifacts(from response: WorkerResponse) -> [ArtifactDescriptor] {
        var artifacts: [ArtifactDescriptor] = []

        if let outputDocxPath = response.outputDocxPath {
            artifacts.append(
                ArtifactDescriptor(
                    id: "output_docx",
                    kind: .output,
                    uri: fileURI(forPath: outputDocxPath),
                    mediaType: "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
                )
            )
        }

        if let normalizedJSONPath = response.normalizedJsonPath {
            artifacts.append(
                ArtifactDescriptor(
                    id: "normalized_json",
                    kind: .intermediate,
                    uri: fileURI(forPath: normalizedJSONPath),
                    mediaType: "application/json"
                )
            )
        }

        if let reportPath = response.reportPath {
            artifacts.append(
                ArtifactDescriptor(
                    id: "report_json",
                    kind: .report,
                    uri: fileURI(forPath: reportPath),
                    mediaType: "application/json"
                )
            )
        }

        return artifacts
    }

    private static func resultMetadata(from response: WorkerResponse) -> [String: JSONValue] {
        [
            "worker_contract_version": .string(response.contractVersion),
            "warning_count": .number(Double(response.warnings.count)),
            "error_count": .number(Double(response.errors.count)),
            "warnings": .array(response.warnings.map { .string($0) })
        ]
    }

    private static func resolveSourcePath(from request: ToolRequest) throws -> String {
        if let sourcePath = try optionalStringParameter("source_docx", in: request) {
            return sourcePath
        }

        if let sourcePath = try optionalStringParameter("source_path", in: request) {
            return sourcePath
        }

        if let inputArtifact = request.inputArtifacts.first(where: { $0.kind == .input }) {
            return resolvePathFromURIOrPath(inputArtifact.uri)
        }

        throw OrchivisteBridgeError.missingParameter("source_docx")
    }

    private static func resolveStructuringMode(from request: ToolRequest) throws -> WorkerRequest.StructuringMode {
        guard let mode = try optionalStringParameter("structuring_mode", in: request) else {
            return .foundationModelsPreferred
        }

        switch mode.lowercased() {
        case "foundationmodelspreferred", "foundation", "foundation_models":
            return .foundationModelsPreferred
        case "deterministiconly", "deterministic", "rules":
            return .deterministicOnly
        default:
            throw OrchivisteBridgeError.invalidParameter(
                "structuring_mode",
                "expected foundationModelsPreferred or deterministicOnly"
            )
        }
    }

    private static func optionalStringParameter(_ key: String, in request: ToolRequest) throws -> String? {
        guard let value = request.parameters[key] else {
            return nil
        }

        switch value {
        case .string(let stringValue):
            let trimmed = stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : resolvePathFromURIOrPath(trimmed)
        default:
            throw OrchivisteBridgeError.invalidParameter(key, "expected string")
        }
    }

    private static func resolvePathFromURIOrPath(_ candidate: String) -> String {
        guard let url = URL(string: candidate), url.isFileURL else {
            return candidate
        }
        return url.path
    }

    private static func fileURI(forPath path: String) -> String {
        URL(fileURLWithPath: path).absoluteString
    }
}

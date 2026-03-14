import Foundation
import MMFCore
import MMFInfrastructureLogging
import MMFFeatureOutput
import MMFFeatureWorker
import OrchivisteKitContracts
import OrchivisteKitInterop

@main
struct MuniMiseEnFormeCLI {
    static func main() async {
        let logger = MMFInfrastructureLogging.ConsoleLogger()
        let service = WorkerService(logger: logger)

        do {
            let cli = try CLIArguments(arguments: Array(CommandLine.arguments.dropFirst()))

            switch cli.command {
            case .help:
                print(Self.helpText)

            case .analyze:
                guard let source = cli.value(for: "--source") else {
                    throw CLIError.missingOption("--source")
                }
                let jsonOut = cli.value(for: "--json") ?? defaultJSONPath(forSource: source)
                let mode = parseMode(cli.value(for: "--mode"))

                let request = WorkerRequest(
                    sourceDocxPath: source,
                    templateDocxPath: nil,
                    outputDocxPath: nil,
                    reportPath: nil,
                    structuringMode: mode
                )

                let response = await service.run(
                    request: request,
                    normalizedJSONOutputURL: URL(fileURLWithPath: jsonOut)
                )
                try printResponse(response)

            case .run:
                if cli.value(for: "--request") != nil || cli.value(for: "--result") != nil {
                    try await runCanonical(cli: cli, service: service)
                } else {
                    guard let source = cli.value(for: "--source") else {
                        throw CLIError.missingOption("--source")
                    }

                    let template = cli.value(for: "--template")
                    let output = resolveOutputPath(cli: cli, source: source, hasTemplate: template != nil)
                    let report = resolveReportPath(cli: cli, output: output)
                    let jsonOut = cli.value(for: "--json") ?? defaultJSONPath(forSource: source)
                    let mode = parseMode(cli.value(for: "--mode"))

                    let request = WorkerRequest(
                        sourceDocxPath: source,
                        templateDocxPath: template,
                        outputDocxPath: output,
                        reportPath: report,
                        structuringMode: mode
                    )

                    let response = await service.run(
                        request: request,
                        normalizedJSONOutputURL: URL(fileURLWithPath: jsonOut)
                    )
                    try printResponse(response)
                }

            case .worker:
                guard let requestPath = cli.value(for: "--request-json") else {
                    throw CLIError.missingOption("--request-json")
                }
                guard let responsePath = cli.value(for: "--response-json") else {
                    throw CLIError.missingOption("--response-json")
                }

                let requestData = try Data(contentsOf: URL(fileURLWithPath: requestPath))
                let decoder = JSONDecoder()
                let workerRequest = try decoder.decode(WorkerRequest.self, from: requestData)

                let normalizedJSONPath = cli.value(for: "--normalized-json")
                let response = await service.run(
                    request: workerRequest,
                    normalizedJSONOutputURL: normalizedJSONPath.map { URL(fileURLWithPath: $0) }
                )

                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
                let responseData = try encoder.encode(response)
                let responseURL = URL(fileURLWithPath: responsePath)
                try FileManager.default.createDirectory(
                    at: responseURL.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                try responseData.write(to: responseURL)

                try printResponse(response)
            }
        } catch {
            fputs("Erreur: \(error.localizedDescription)\n", stderr)
            fputs("\n\(helpText)\n", stderr)
            exit(1)
        }
    }

    private static func parseMode(_ value: String?) -> WorkerRequest.StructuringMode {
        guard let value else { return .foundationModelsPreferred }

        switch value.lowercased() {
        case "foundation", "foundationmodels", "foundation_models":
            return .foundationModelsPreferred
        case "deterministic", "rules":
            return .deterministicOnly
        default:
            return .foundationModelsPreferred
        }
    }

    private static func resolveOutputPath(cli: CLIArguments, source: String, hasTemplate: Bool) -> String? {
        if let output = cli.value(for: "--output") {
            return output
        }

        guard hasTemplate else {
            return nil
        }

        let resolver = OutputPathResolver()
        let sourceURL = URL(fileURLWithPath: source)
        return resolver.resolveOutputURL(for: sourceURL).path
    }

    private static func resolveReportPath(cli: CLIArguments, output: String?) -> String? {
        if let report = cli.value(for: "--report") {
            return report
        }

        guard let output else {
            return nil
        }

        let resolver = OutputPathResolver()
        return resolver.resolveReportURL(for: URL(fileURLWithPath: output)).path
    }

    private static func defaultJSONPath(forSource sourcePath: String) -> String {
        let sourceURL = URL(fileURLWithPath: sourcePath)
        return sourceURL
            .deletingPathExtension()
            .appendingPathExtension("normalized.json")
            .path
    }

    private static func runCanonical(cli: CLIArguments, service: WorkerService) async throws {
        guard let requestPath = cli.value(for: "--request") else {
            throw CLIError.missingOption("--request")
        }
        guard let resultPath = cli.value(for: "--result") else {
            throw CLIError.missingOption("--result")
        }

        let requestURL = URL(fileURLWithPath: requestPath)
        let resultURL = URL(fileURLWithPath: resultPath)
        let request = try ToolInteropService.loadRequest(from: requestURL)
        let startedAt = isoTimestamp()
        let result: ToolResult

        do {
            let executionPlan = try OrchivisteBridgeAdapter.makeExecutionPlan(from: request)
            let workerResponse = await service.run(
                request: executionPlan.workerRequest,
                normalizedJSONOutputURL: executionPlan.normalizedJSONOutputURL
            )
            let finishedAt = isoTimestamp()
            result = OrchivisteBridgeAdapter.makeResult(
                for: request,
                response: workerResponse,
                startedAt: startedAt,
                finishedAt: finishedAt
            )
        } catch let bridgeError as OrchivisteBridgeError {
            let finishedAt = isoTimestamp()
            result = OrchivisteBridgeAdapter.makeFailureResult(
                for: request,
                startedAt: startedAt,
                finishedAt: finishedAt,
                error: bridgeError.toolError
            )
        } catch {
            let finishedAt = isoTimestamp()
            result = OrchivisteBridgeAdapter.makeFailureResult(
                for: request,
                startedAt: startedAt,
                finishedAt: finishedAt,
                error: ToolError(
                    code: "CLI_RUNTIME_ERROR",
                    message: error.localizedDescription,
                    retryable: false
                )
            )
        }

        try ToolInteropService.writeResult(result, to: resultURL)
        printToolResult(result)

        if result.status == .failed {
            throw CLIError.executionFailed
        }
    }

    private static func printResponse(_ response: WorkerResponse) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let data = try encoder.encode(response)
        if let output = String(data: data, encoding: .utf8) {
            print(output)
        }

        if !response.success {
            throw CLIError.executionFailed
        }
    }

    private static func printToolResult(_ result: ToolResult) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        if let data = try? encoder.encode(result), let output = String(data: data, encoding: .utf8) {
            print(output)
            return
        }
        print("{\"status\":\"failed\",\"summary\":\"Unable to encode ToolResult.\"}")
    }

    private static func isoTimestamp() -> String {
        ISO8601DateFormatter().string(from: Date())
    }

    private static let helpText = """
    Muni Mise en forme - CLI

    Commandes:
      run --request <request.json> --result <result.json>
      run --source <docx> [--template <docx>] [--output <docx>] [--report <json>] [--json <normalized.json>] [--mode foundation|deterministic]
      analyze --source <docx> [--json <normalized.json>] [--mode foundation|deterministic]
      worker --request-json <request.json> --response-json <response.json> [--normalized-json <normalized.json>]
      help
    """
}

private enum CLIError: LocalizedError {
    case missingOption(String)
    case invalidCommand(String)
    case executionFailed

    var errorDescription: String? {
        switch self {
        case .missingOption(let option):
            return "Option manquante: \(option)"
        case .invalidCommand(let command):
            return "Commande invalide: \(command)"
        case .executionFailed:
            return "Execution echouee"
        }
    }
}

private struct CLIArguments {
    enum Command {
        case run
        case analyze
        case worker
        case help
    }

    let command: Command
    private let values: [String: String]

    init(arguments: [String]) throws {
        guard let first = arguments.first else {
            command = .help
            values = [:]
            return
        }

        switch first {
        case "run": command = .run
        case "analyze": command = .analyze
        case "worker": command = .worker
        case "help", "--help", "-h": command = .help
        default: throw CLIError.invalidCommand(first)
        }

        values = Self.parseKeyValues(Array(arguments.dropFirst()))
    }

    func value(for option: String) -> String? {
        values[option]
    }

    private static func parseKeyValues(_ options: [String]) -> [String: String] {
        var parsed: [String: String] = [:]
        var index = 0

        while index < options.count {
            let option = options[index]
            if option.hasPrefix("--"), index + 1 < options.count {
                parsed[option] = options[index + 1]
                index += 2
            } else {
                index += 1
            }
        }

        return parsed
    }
}

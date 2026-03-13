import SwiftUI
import AppKit
import Foundation
import UniformTypeIdentifiers
import MMFFeatureWorker
import MMFInfrastructureLogging

@main
struct MuniMiseEnFormeApp: App {
    @StateObject private var viewModel = AppViewModel()

    var body: some Scene {
        WindowGroup("Muni Mise en forme") {
            ContentView(viewModel: viewModel)
                .frame(minWidth: 900, minHeight: 620)
        }
    }
}

@MainActor
final class AppViewModel: ObservableObject {
    @Published var sourcePath: String = ""
    @Published var templatePath: String = ""
    @Published var outputPath: String = ""
    @Published var reportPath: String = ""
    @Published var normalizedJSONPath: String = ""
    @Published var structuringMode: WorkerRequest.StructuringMode = .foundationModelsPreferred
    @Published var normalizedJSON: String = ""
    @Published var validationReport: String = ""
    @Published var status: String = "Pret"
    @Published var isRunning: Bool = false

    private let worker = WorkerService(logger: ConsoleLogger())

    func pickSource() {
        if let url = pickFile(allowedExtensions: ["docx"]) {
            sourcePath = url.path
            if outputPath.isEmpty {
                outputPath = url
                    .deletingPathExtension()
                    .appendingPathExtension("out.docx")
                    .path
            }
            if reportPath.isEmpty {
                reportPath = url
                    .deletingPathExtension()
                    .appendingPathExtension("validation.json")
                    .path
            }
            if normalizedJSONPath.isEmpty {
                normalizedJSONPath = url
                    .deletingPathExtension()
                    .appendingPathExtension("normalized.json")
                    .path
            }
        }
    }

    func pickTemplate() {
        if let url = pickFile(allowedExtensions: ["docx"]) {
            templatePath = url.path
        }
    }

    func runAnalyze() {
        runPipeline(generateDocx: false)
    }

    func runGenerate() {
        runPipeline(generateDocx: true)
    }

    private func runPipeline(generateDocx: Bool) {
        guard !sourcePath.isEmpty else {
            status = "Selectionne un fichier source .docx"
            return
        }

        if generateDocx && templatePath.isEmpty {
            status = "Selectionne un gabarit .docx"
            return
        }

        isRunning = true
        status = "Execution en cours..."

        let request = WorkerRequest(
            sourceDocxPath: sourcePath,
            templateDocxPath: generateDocx ? templatePath : nil,
            outputDocxPath: generateDocx ? outputPath : nil,
            reportPath: generateDocx ? reportPath : nil,
            structuringMode: structuringMode
        )

        Task {
            let normalizedURL = normalizedJSONPath.isEmpty ? nil : URL(fileURLWithPath: normalizedJSONPath)
            let response = await worker.run(request: request, normalizedJSONOutputURL: normalizedURL)
            await MainActor.run {
                self.isRunning = false
                self.status = response.success ? "Termine" : "Erreur"
                self.validationReport = response.errors.isEmpty
                    ? response.warnings.joined(separator: "\n")
                    : response.errors.joined(separator: "\n")

                if let jsonPath = response.normalizedJsonPath,
                   let jsonText = try? String(contentsOfFile: jsonPath, encoding: .utf8)
                {
                    self.normalizedJSON = jsonText
                }
            }
        }
    }

    private func pickFile(allowedExtensions: [String]) -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = allowedExtensions.compactMap { UTType(filenameExtension: $0) }

        if panel.runModal() == .OK {
            guard let url = panel.url else { return nil }
            if allowedExtensions.contains(url.pathExtension.lowercased()) {
                return url
            }
        }

        return nil
    }
}

struct ContentView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Muni Mise en forme")
                .font(.title2.bold())

            GroupBox("Fichiers") {
                VStack(alignment: .leading, spacing: 8) {
                    fileRow(label: "Source .docx", value: $viewModel.sourcePath, buttonLabel: "Choisir", action: viewModel.pickSource)
                    fileRow(label: "Gabarit .docx", value: $viewModel.templatePath, buttonLabel: "Choisir", action: viewModel.pickTemplate)
                    pathField(label: "Sortie .docx", value: $viewModel.outputPath)
                    pathField(label: "Rapport validation", value: $viewModel.reportPath)
                    pathField(label: "JSON normalise", value: $viewModel.normalizedJSONPath)
                }
            }

            HStack(spacing: 10) {
                Picker("Mode structuration", selection: $viewModel.structuringMode) {
                    Text("Foundation Models").tag(WorkerRequest.StructuringMode.foundationModelsPreferred)
                    Text("Deterministe").tag(WorkerRequest.StructuringMode.deterministicOnly)
                }
                .frame(width: 280)

                Button("Analyser") { viewModel.runAnalyze() }
                    .disabled(viewModel.isRunning)

                Button("Generer document") { viewModel.runGenerate() }
                    .disabled(viewModel.isRunning)
            }

            Text("Statut: \(viewModel.status)")
                .font(.subheadline)

            HStack(alignment: .top, spacing: 12) {
                GroupBox("JSON normalise") {
                    ScrollView {
                        Text(viewModel.normalizedJSON.isEmpty ? "Aucun JSON produit" : viewModel.normalizedJSON)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.system(.body, design: .monospaced))
                            .padding(8)
                    }
                }

                GroupBox("Rapport") {
                    ScrollView {
                        Text(viewModel.validationReport.isEmpty ? "Aucun rapport" : viewModel.validationReport)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                    }
                }
            }
            .frame(maxHeight: .infinity)
        }
        .padding(16)
    }

    private func fileRow(label: String, value: Binding<String>, buttonLabel: String, action: @escaping () -> Void) -> some View {
        HStack {
            Text(label)
                .frame(width: 140, alignment: .leading)
            TextField("", text: value)
            Button(buttonLabel, action: action)
        }
    }

    private func pathField(label: String, value: Binding<String>) -> some View {
        HStack {
            Text(label)
                .frame(width: 140, alignment: .leading)
            TextField("", text: value)
        }
    }
}

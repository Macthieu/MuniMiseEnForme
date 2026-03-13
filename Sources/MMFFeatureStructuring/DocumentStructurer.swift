import Foundation
import MMFCore
import MMFDomain
import MMFInfrastructureFoundationModels

public struct DocumentStructurer: ContentStructurer {
    public enum Mode: Sendable {
        case foundationModelsPreferred
        case deterministicOnly
    }

    private let mode: Mode
    private let foundationClient: FoundationModelsClient
    private let promptBuilder: StrictStructuringPromptBuilder

    public init(
        mode: Mode = .foundationModelsPreferred,
        foundationClient: FoundationModelsClient = FoundationModelsClient(),
        promptBuilder: StrictStructuringPromptBuilder = StrictStructuringPromptBuilder()
    ) {
        self.mode = mode
        self.foundationClient = foundationClient
        self.promptBuilder = promptBuilder
    }

    public func structure(from extractedDocument: ExtractedDocument) async throws -> NormalizedDocument {
        var foundationFailureMessage: String?

        if mode == .foundationModelsPreferred, foundationClient.isAvailable {
            let rawText = extractedDocument.elements
                .sorted { $0.order < $1.order }
                .map(\.text)
                .joined(separator: "\n")

            let prompt = promptBuilder.buildPrompt(from: rawText)

            do {
                let modelOutput = try await foundationClient.generateStrictJSON(prompt: prompt)
                if let decoded = decodeModelJSON(modelOutput) {
                    return decoded
                }
                foundationFailureMessage = "Foundation Models a retourne un JSON non exploitable; fallback deterministe."
            } catch {
                foundationFailureMessage = "Foundation Models indisponible ou en echec (\(error.localizedDescription)); fallback deterministe."
            }
        }

        return buildDeterministicStructure(
            from: extractedDocument,
            additionalComment: foundationFailureMessage
        )
    }

    private func decodeModelJSON(_ modelOutput: String) -> NormalizedDocument? {
        let candidate = extractFirstJSONObject(in: modelOutput) ?? modelOutput
        guard let data = candidate.data(using: .utf8) else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(NormalizedDocument.self, from: data)
    }

    private func extractFirstJSONObject(in text: String) -> String? {
        guard let start = text.firstIndex(of: "{"), let end = text.lastIndex(of: "}") else {
            return nil
        }
        guard start <= end else { return nil }
        return String(text[start...end])
    }

    private func buildDeterministicStructure(from extracted: ExtractedDocument, additionalComment: String?) -> NormalizedDocument {
        let sortedElements = extracted.elements.sorted { $0.order < $1.order }

        let blocks = sortedElements.enumerated().map { offset, element in
            mapElementToBlock(order: offset + 1, element: element)
        }

        let firstHeading = blocks.first(where: { $0.type == .titre })?.texte ?? ""
        let inferredType = inferDocumentType(from: sortedElements.map(\.text))

        let metadata = DocumentMetadata(
            typeDocument: inferredType,
            titreLong: firstHeading,
            titreCourt: firstHeading,
            codeDocument: "",
            domaine: "",
            classification: [],
            version: "",
            dateDocument: "",
            resolution: "",
            langue: "fr-CA"
        )

        let actors = DocumentActors()
        let frontMatter = FrontMatter(pageTitre: true, tableauSynoptique: true, tableMatieres: true)
        var comments = ["Structuration deterministe appliquee (fallback local sans Foundation Models)"]
        if let additionalComment {
            comments.append(additionalComment)
        }

        let validation = ValidationSummary(
            champsManquants: [],
            sectionsManquantes: [],
            elementsAmbigus: [],
            commentaires: comments
        )

        return NormalizedDocument(
            document: metadata,
            acteurs: actors,
            pagesLiminaires: frontMatter,
            blocs: blocks,
            annexes: [],
            validation: validation
        )
    }

    private func mapElementToBlock(order: Int, element: ExtractedElement) -> DocumentBlock {
        let text = element.text.trimmingCharacters(in: .whitespacesAndNewlines)

        if text.range(of: #"^SECTION\b"#, options: [.regularExpression, .caseInsensitive]) != nil {
            return DocumentBlock(ordre: order, type: .titre, niveau: 1, style: .titreNiveau1, texte: text)
        }

        if text.range(of: #"^\d+\.\s"#, options: .regularExpression) != nil {
            return DocumentBlock(ordre: order, type: .titre, niveau: 2, style: .titreNiveau2, texte: text)
        }

        if text.range(of: #"^\d+\.\d+\.\s"#, options: .regularExpression) != nil {
            return DocumentBlock(ordre: order, type: .titre, niveau: 3, style: .titreNiveau3, texte: text)
        }

        if text.range(of: #"^\d+\.\d+\.\d+\.\s"#, options: .regularExpression) != nil {
            return DocumentBlock(ordre: order, type: .titre, niveau: 4, style: .titreNiveau4, texte: text)
        }

        if text.range(of: #"^[a-z]\)\s"#, options: [.regularExpression, .caseInsensitive]) != nil {
            return DocumentBlock(ordre: order, type: .liste, niveau: nil, style: .listeLettres, texte: text)
        }

        if text.hasPrefix("•") || text.hasPrefix("-") || text.hasPrefix("*") {
            return DocumentBlock(ordre: order, type: .liste, niveau: nil, style: .listePuces, texte: text)
        }

        if text.range(of: #"^(annexe|annexes)\b"#, options: [.regularExpression, .caseInsensitive]) != nil {
            return DocumentBlock(ordre: order, type: .annexe, niveau: nil, style: .annexeTitre, texte: text)
        }

        switch element.kind {
        case .heading:
            return DocumentBlock(ordre: order, type: .titre, niveau: 2, style: .titreNiveau2, texte: text)
        case .bullet:
            return DocumentBlock(ordre: order, type: .liste, niveau: nil, style: .listePuces, texte: text)
        case .letteredList:
            return DocumentBlock(ordre: order, type: .liste, niveau: nil, style: .listeLettres, texte: text)
        default:
            return DocumentBlock(ordre: order, type: .paragraphe, niveau: nil, style: .corpsTexte, texte: text)
        }
    }

    private func inferDocumentType(from lines: [String]) -> String {
        let text = lines.joined(separator: " ").lowercased()

        if text.contains("politique") { return "politique" }
        if text.contains("procedure") || text.contains("procédure") { return "procédure" }
        if text.contains("directive") { return "directive" }
        if text.contains("guide") { return "guide" }
        if text.contains("programme") { return "programme" }
        if text.contains("plan d'action") || text.contains("plan_action") { return "plan_action" }

        return "document"
    }
}

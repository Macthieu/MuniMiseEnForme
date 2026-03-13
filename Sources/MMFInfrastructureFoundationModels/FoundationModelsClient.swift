import Foundation
import MMFCore

#if canImport(FoundationModels)
import FoundationModels
#endif

public struct FoundationModelsClient: Sendable {
    public init() {}

    public var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            let model = SystemLanguageModel.default
            if case .available = model.availability {
                return true
            }
        }
        return false
        #else
        return false
        #endif
    }

    public func generateStrictJSON(prompt: String) async throws -> String {
        #if canImport(FoundationModels)
        guard #available(macOS 26.0, *) else {
            throw MMFError.unsupported("Foundation Models requiert macOS 26+")
        }

        let model = SystemLanguageModel.default
        switch model.availability {
        case .available:
            break
        case .unavailable(let reason):
            throw MMFError.unsupported("Foundation Models indisponible: \(String(describing: reason))")
        }

        let instructions = """
        Tu es un moteur de structuration documentaire municipale.
        Tu dois produire UNIQUEMENT un JSON valide.
        N'ajoute aucun texte avant ou apres le JSON.
        N'invente pas de contenu absent.
        En cas d'ambiguite, renseigne validation.elements_ambigus.
        """

        let session = LanguageModelSession(instructions: instructions)
        let response = try await session.respond(to: prompt)
        return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        #else
        throw MMFError.unsupported("Foundation Models indisponible sur cet environnement")
        #endif
    }
}

public struct StrictStructuringPromptBuilder: Sendable {
    public init() {}

    public func buildPrompt(from extractedText: String) -> String {
        """
        Produis uniquement un JSON valide selon ce schema logique:
        {
          "document": {...},
          "acteurs": {...},
          "pages_liminaires": {...},
          "blocs": [...],
          "annexes": [...],
          "validation": {...}
        }

        Regles:
        - Ne genere aucun texte hors JSON.
        - N'invente pas de contenu manquant.
        - Signale toute ambiguite dans validation.elements_ambigus.
        - Preserve le texte source le plus fidelement possible.

        Contenu source:
        \(extractedText)
        """
    }
}

import Foundation
import MMFCore
import MMFDomain

public struct DocumentJSONValidator: DocumentValidator {
    private let knownDocumentTypes: Set<String> = [
        "directive",
        "politique",
        "procédure",
        "procedure",
        "programme",
        "guide",
        "processus",
        "registre",
        "plan_action",
        "memo",
        "note_service",
        "formulaire",
        "document"
    ]

    public init() {}

    public func validate(document: inout NormalizedDocument) -> ValidationSummary {
        var missingFields: [String] = []
        var missingSections: [String] = []
        var ambiguousElements: [String] = document.validation.elementsAmbigus
        var comments: [String] = document.validation.commentaires

        if document.document.typeDocument.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            missingFields.append("document.type_document")
        } else if !knownDocumentTypes.contains(document.document.typeDocument.lowercased()) {
            ambiguousElements.append("Type documentaire non reconnu: \(document.document.typeDocument)")
        }

        if document.document.titreLong.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            missingFields.append("document.titre_long")
        }

        if document.document.langue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            missingFields.append("document.langue")
        } else if document.document.langue.lowercased() != "fr-ca" {
            comments.append("Langue differente de fr-CA: \(document.document.langue)")
        }

        if document.blocs.isEmpty {
            missingSections.append("blocs")
        }

        if !document.pagesLiminaires.pageTitre {
            missingSections.append("page_titre")
        }

        if !document.pagesLiminaires.tableauSynoptique {
            missingSections.append("tableau_synoptique")
        }

        if !document.pagesLiminaires.tableMatieres {
            missingSections.append("table_matieres")
        }

        let hasLevel1Title = document.blocs.contains { $0.style == .titreNiveau1 }
        if !hasLevel1Title {
            missingSections.append("Titre_Niveau_1")
            ambiguousElements.append("Aucun titre de niveau 1 detecte")
        }

        let sortedBlocks = document.blocs.sorted { $0.ordre < $1.ordre }
        for (expectedOrder, block) in sortedBlocks.enumerated() {
            let expected = expectedOrder + 1
            if block.ordre != expected {
                ambiguousElements.append("Ordre de bloc non sequentiel: attendu \(expected), obtenu \(block.ordre)")
            }

            if block.texte.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                ambiguousElements.append("Bloc vide a l'ordre \(block.ordre)")
            }

            if block.type == .titre {
                validateHeadingBlock(block, ambiguousElements: &ambiguousElements)
            }
        }

        let hasBodyText = document.blocs.contains { $0.style == .corpsTexte }
        if !hasBodyText {
            comments.append("Aucun bloc Corps_Texte detecte")
        }

        return ValidationSummary(
            champsManquants: uniqueSorted(missingFields),
            sectionsManquantes: uniqueSorted(missingSections),
            elementsAmbigus: uniqueSorted(ambiguousElements),
            commentaires: uniqueSorted(comments)
        )
    }

    private func validateHeadingBlock(_ block: DocumentBlock, ambiguousElements: inout [String]) {
        guard let level = block.niveau else {
            ambiguousElements.append("Bloc titre sans niveau a l'ordre \(block.ordre)")
            return
        }

        let expectedStyle: DocumentStyle?
        switch level {
        case 1: expectedStyle = .titreNiveau1
        case 2: expectedStyle = .titreNiveau2
        case 3: expectedStyle = .titreNiveau3
        case 4: expectedStyle = .titreNiveau4
        default:
            expectedStyle = nil
        }

        guard let expectedStyle else {
            ambiguousElements.append("Niveau de titre invalide \(level) a l'ordre \(block.ordre)")
            return
        }

        if block.style != expectedStyle {
            ambiguousElements.append(
                "Incoherence titre a l'ordre \(block.ordre): niveau \(level) mais style \(block.style.rawValue)"
            )
        }
    }

    private func uniqueSorted(_ values: [String]) -> [String] {
        Array(Set(values)).sorted()
    }
}

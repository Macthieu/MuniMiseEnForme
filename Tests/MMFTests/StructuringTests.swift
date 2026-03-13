import Testing
import MMFFeatureStructuring
import MMFDomain

@Test
func deterministicStructurerMapsHierarchyRules() async throws {
    let extracted = ExtractedDocument(
        sourcePath: "/tmp/source.docx",
        elements: [
            ExtractedElement(order: 1, kind: .paragraph, text: "SECTION Gouvernance"),
            ExtractedElement(order: 2, kind: .paragraph, text: "1. Objectif"),
            ExtractedElement(order: 3, kind: .paragraph, text: "1.1. Portee"),
            ExtractedElement(order: 4, kind: .paragraph, text: "1.1.1. Detail"),
            ExtractedElement(order: 5, kind: .paragraph, text: "Paragraphe courant")
        ]
    )

    let structurer = DocumentStructurer(mode: .deterministicOnly)
    let normalized = try await structurer.structure(from: extracted)

    #expect(normalized.blocs[0].style == .titreNiveau1)
    #expect(normalized.blocs[1].style == .titreNiveau2)
    #expect(normalized.blocs[2].style == .titreNiveau3)
    #expect(normalized.blocs[3].style == .titreNiveau4)
    #expect(normalized.blocs[4].style == .corpsTexte)
}

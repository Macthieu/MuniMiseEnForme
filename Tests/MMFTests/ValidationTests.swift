import Testing
import MMFFeatureValidation
import MMFDomain

@Test
func validatorDetectsMissingFieldsAndSections() {
    var document = NormalizedDocument(
        document: DocumentMetadata(typeDocument: "", titreLong: "", langue: ""),
        acteurs: DocumentActors(),
        pagesLiminaires: FrontMatter(pageTitre: true, tableauSynoptique: true, tableMatieres: true),
        blocs: [],
        annexes: [],
        validation: ValidationSummary()
    )

    let validator = DocumentJSONValidator()
    let report = validator.validate(document: &document)

    #expect(report.champsManquants.contains("document.type_document"))
    #expect(report.champsManquants.contains("document.titre_long"))
    #expect(report.sectionsManquantes.contains("blocs"))
}

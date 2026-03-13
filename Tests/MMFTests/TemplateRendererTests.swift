import Foundation
import Testing
import MMFDomain
import MMFFeatureTemplateEngine

@Test
func templateRendererRejectsMissingStyles() throws {
    let tempRoot = try makeTempFolder()
    let templateURL = tempRoot.appendingPathComponent("template_missing_styles.docx")
    try createMinimalTemplateDocx(at: templateURL, styleIDs: ["Corps_Texte"])

    let normalized = sampleNormalizedDocument()
    let outputURL = tempRoot.appendingPathComponent("output.docx")

    let renderer = TemplateDocxRenderer()

    var didThrow = false
    do {
        try renderer.render(document: normalized, templateURL: templateURL, outputURL: outputURL)
    } catch {
        didThrow = true
        #expect(error.localizedDescription.contains("styles requis"))
    }

    #expect(didThrow)
}

@Test
func templateRendererGeneratesDocxWhenStylesPresent() throws {
    let tempRoot = try makeTempFolder()
    let templateURL = tempRoot.appendingPathComponent("template_ok.docx")
    let allStyleIDs = Set(DocumentStyle.allCases.map(\.rawValue))
    try createMinimalTemplateDocx(at: templateURL, styleIDs: allStyleIDs)

    let normalized = sampleNormalizedDocument()
    let outputURL = tempRoot.appendingPathComponent("output_ok.docx")

    let renderer = TemplateDocxRenderer()
    try renderer.render(document: normalized, templateURL: templateURL, outputURL: outputURL)

    var isDirectory: ObjCBool = false
    let exists = FileManager.default.fileExists(atPath: outputURL.path, isDirectory: &isDirectory)
    #expect(exists)
    #expect(!isDirectory.boolValue)
}

private func sampleNormalizedDocument() -> NormalizedDocument {
    NormalizedDocument(
        document: DocumentMetadata(
            typeDocument: "directive",
            titreLong: "Directive test",
            titreCourt: "Directive",
            codeDocument: "DIR-001",
            domaine: "Administration",
            classification: [],
            version: "1.0",
            dateDocument: "2026-03-13",
            resolution: "",
            langue: "fr-CA"
        ),
        acteurs: DocumentActors(
            redacteurs: ["Service"],
            serviceResponsable: "Greffe",
            responsablesMiseEnOeuvre: [],
            approbateur: "Conseil"
        ),
        pagesLiminaires: FrontMatter(),
        blocs: [
            DocumentBlock(
                ordre: 1,
                type: .titre,
                niveau: 1,
                style: .titreNiveau1,
                texte: "SECTION Test"
            ),
            DocumentBlock(
                ordre: 2,
                type: .paragraphe,
                niveau: nil,
                style: .corpsTexte,
                texte: "Contenu de test"
            )
        ],
        annexes: [],
        validation: ValidationSummary()
    )
}

private func makeTempFolder() throws -> URL {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("mmf-tests", isDirectory: true)
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

private func createMinimalTemplateDocx(at outputURL: URL, styleIDs: Set<String>) throws {
    let workingDir = try makeTempFolder()
    let relsDir = workingDir.appendingPathComponent("_rels", isDirectory: true)
    let wordDir = workingDir.appendingPathComponent("word", isDirectory: true)

    try FileManager.default.createDirectory(at: relsDir, withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: wordDir, withIntermediateDirectories: true)

    let contentTypes = """
    <?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>
    <Types xmlns=\"http://schemas.openxmlformats.org/package/2006/content-types\">
      <Default Extension=\"rels\" ContentType=\"application/vnd.openxmlformats-package.relationships+xml\"/>
      <Default Extension=\"xml\" ContentType=\"application/xml\"/>
      <Override PartName=\"/word/document.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml\"/>
      <Override PartName=\"/word/styles.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml\"/>
    </Types>
    """

    let rootRels = """
    <?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>
    <Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\">
      <Relationship Id=\"rId1\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument\" Target=\"word/document.xml\"/>
    </Relationships>
    """

    let documentXML = """
    <?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>
    <w:document xmlns:w=\"http://schemas.openxmlformats.org/wordprocessingml/2006/main\">
      <w:body>
        <w:p><w:r><w:t>{{document.titre_long}}</w:t></w:r></w:p>
        <w:p><w:r><w:t>{{BODY_BLOCKS}}</w:t></w:r></w:p>
      </w:body>
    </w:document>
    """

    let styles = stylesXML(styleIDs: styleIDs)

    try contentTypes.write(to: workingDir.appendingPathComponent("[Content_Types].xml"), atomically: true, encoding: .utf8)
    try rootRels.write(to: relsDir.appendingPathComponent(".rels"), atomically: true, encoding: .utf8)
    try documentXML.write(to: wordDir.appendingPathComponent("document.xml"), atomically: true, encoding: .utf8)
    try styles.write(to: wordDir.appendingPathComponent("styles.xml"), atomically: true, encoding: .utf8)

    if FileManager.default.fileExists(atPath: outputURL.path) {
        try FileManager.default.removeItem(at: outputURL)
    }

    try runShell(
        executable: "/usr/bin/zip",
        arguments: ["-X", "-r", outputURL.path, "."],
        currentDirectoryURL: workingDir
    )
}

private func stylesXML(styleIDs: Set<String>) -> String {
    let stylesBody = styleIDs.sorted().map {
        "<w:style w:type=\"paragraph\" w:styleId=\"\($0)\"><w:name w:val=\"\($0)\"/></w:style>"
    }.joined(separator: "")

    return """
    <?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>
    <w:styles xmlns:w=\"http://schemas.openxmlformats.org/wordprocessingml/2006/main\">
      \(stylesBody)
    </w:styles>
    """
}

@discardableResult
private func runShell(executable: String, arguments: [String], currentDirectoryURL: URL? = nil) throws -> String {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = arguments
    process.currentDirectoryURL = currentDirectoryURL

    let outputPipe = Pipe()
    let errorPipe = Pipe()
    process.standardOutput = outputPipe
    process.standardError = errorPipe

    try process.run()
    process.waitUntilExit()

    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

    if process.terminationStatus != 0 {
        let stderr = String(data: errorData, encoding: .utf8) ?? "shell failure"
        throw NSError(domain: "MMFTests", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: stderr])
    }

    return String(data: outputData, encoding: .utf8) ?? ""
}

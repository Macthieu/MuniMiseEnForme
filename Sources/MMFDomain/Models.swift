import Foundation

public struct ImportedDocument: Sendable {
    public let sourceURL: URL
    public let importedAt: Date

    public init(sourceURL: URL, importedAt: Date = Date()) {
        self.sourceURL = sourceURL
        self.importedAt = importedAt
    }
}

public struct ExtractedDocument: Codable, Sendable {
    public let sourcePath: String
    public let extractedAt: Date
    public var elements: [ExtractedElement]

    public init(sourcePath: String, extractedAt: Date = Date(), elements: [ExtractedElement]) {
        self.sourcePath = sourcePath
        self.extractedAt = extractedAt
        self.elements = elements
    }
}

public struct ExtractedElement: Codable, Sendable {
    public let order: Int
    public let kind: ExtractedElementKind
    public let text: String
    public let styleHint: String?

    public init(order: Int, kind: ExtractedElementKind, text: String, styleHint: String? = nil) {
        self.order = order
        self.kind = kind
        self.text = text
        self.styleHint = styleHint
    }
}

public enum ExtractedElementKind: String, Codable, Sendable {
    case paragraph
    case heading
    case bullet
    case letteredList
    case table
}

public struct NormalizedDocument: Codable, Sendable {
    public var document: DocumentMetadata
    public var acteurs: DocumentActors
    public var pagesLiminaires: FrontMatter
    public var blocs: [DocumentBlock]
    public var annexes: [Annex]
    public var validation: ValidationSummary

    public init(
        document: DocumentMetadata,
        acteurs: DocumentActors,
        pagesLiminaires: FrontMatter,
        blocs: [DocumentBlock],
        annexes: [Annex],
        validation: ValidationSummary
    ) {
        self.document = document
        self.acteurs = acteurs
        self.pagesLiminaires = pagesLiminaires
        self.blocs = blocs
        self.annexes = annexes
        self.validation = validation
    }

    enum CodingKeys: String, CodingKey {
        case document
        case acteurs
        case pagesLiminaires = "pages_liminaires"
        case blocs
        case annexes
        case validation
    }
}

public struct DocumentMetadata: Codable, Sendable {
    public var typeDocument: String
    public var titreLong: String
    public var titreCourt: String
    public var codeDocument: String
    public var domaine: String
    public var classification: [String]
    public var version: String
    public var dateDocument: String
    public var resolution: String
    public var langue: String

    public init(
        typeDocument: String = "",
        titreLong: String = "",
        titreCourt: String = "",
        codeDocument: String = "",
        domaine: String = "",
        classification: [String] = [],
        version: String = "",
        dateDocument: String = "",
        resolution: String = "",
        langue: String = "fr-CA"
    ) {
        self.typeDocument = typeDocument
        self.titreLong = titreLong
        self.titreCourt = titreCourt
        self.codeDocument = codeDocument
        self.domaine = domaine
        self.classification = classification
        self.version = version
        self.dateDocument = dateDocument
        self.resolution = resolution
        self.langue = langue
    }

    enum CodingKeys: String, CodingKey {
        case typeDocument = "type_document"
        case titreLong = "titre_long"
        case titreCourt = "titre_court"
        case codeDocument = "code_document"
        case domaine
        case classification
        case version
        case dateDocument = "date_document"
        case resolution
        case langue
    }
}

public struct DocumentActors: Codable, Sendable {
    public var redacteurs: [String]
    public var serviceResponsable: String
    public var responsablesMiseEnOeuvre: [String]
    public var approbateur: String

    public init(
        redacteurs: [String] = [],
        serviceResponsable: String = "",
        responsablesMiseEnOeuvre: [String] = [],
        approbateur: String = ""
    ) {
        self.redacteurs = redacteurs
        self.serviceResponsable = serviceResponsable
        self.responsablesMiseEnOeuvre = responsablesMiseEnOeuvre
        self.approbateur = approbateur
    }

    enum CodingKeys: String, CodingKey {
        case redacteurs
        case serviceResponsable = "service_responsable"
        case responsablesMiseEnOeuvre = "responsables_mise_en_oeuvre"
        case approbateur
    }
}

public struct FrontMatter: Codable, Sendable {
    public var pageTitre: Bool
    public var tableauSynoptique: Bool
    public var tableMatieres: Bool

    public init(pageTitre: Bool = true, tableauSynoptique: Bool = true, tableMatieres: Bool = true) {
        self.pageTitre = pageTitre
        self.tableauSynoptique = tableauSynoptique
        self.tableMatieres = tableMatieres
    }

    enum CodingKeys: String, CodingKey {
        case pageTitre = "page_titre"
        case tableauSynoptique = "tableau_synoptique"
        case tableMatieres = "table_matieres"
    }
}

public struct DocumentBlock: Codable, Sendable {
    public var ordre: Int
    public var type: DocumentBlockType
    public var niveau: Int?
    public var style: DocumentStyle
    public var texte: String

    public init(ordre: Int, type: DocumentBlockType, niveau: Int?, style: DocumentStyle, texte: String) {
        self.ordre = ordre
        self.type = type
        self.niveau = niveau
        self.style = style
        self.texte = texte
    }
}

public enum DocumentBlockType: String, Codable, Sendable {
    case titre
    case paragraphe
    case liste
    case tableau
    case annexe
    case note
    case citation
}

public enum DocumentStyle: String, Codable, Sendable, CaseIterable {
    case titreDocument = "Titre_Document"
    case sousTitreDocument = "SousTitre_Document"
    case titreNiveau1 = "Titre_Niveau_1"
    case titreNiveau2 = "Titre_Niveau_2"
    case titreNiveau3 = "Titre_Niveau_3"
    case titreNiveau4 = "Titre_Niveau_4"
    case corpsTexte = "Corps_Texte"
    case listePuces = "Liste_Puces"
    case listeLettres = "Liste_Lettres"
    case tableauSynoptique = "Tableau_Synoptique"
    case annexeTitre = "Annexe_Titre"
    case note = "Note"
    case citation = "Citation"
    case footerInfo = "Footer_Info"
    case toc1 = "TOC_1"
    case toc2 = "TOC_2"
    case toc3 = "TOC_3"
    case toc4 = "TOC_4"
}

public struct Annex: Codable, Sendable {
    public var titre: String
    public var contenu: [DocumentBlock]

    public init(titre: String, contenu: [DocumentBlock] = []) {
        self.titre = titre
        self.contenu = contenu
    }
}

public struct ValidationSummary: Codable, Sendable {
    public var champsManquants: [String]
    public var sectionsManquantes: [String]
    public var elementsAmbigus: [String]
    public var commentaires: [String]

    public init(
        champsManquants: [String] = [],
        sectionsManquantes: [String] = [],
        elementsAmbigus: [String] = [],
        commentaires: [String] = []
    ) {
        self.champsManquants = champsManquants
        self.sectionsManquantes = sectionsManquantes
        self.elementsAmbigus = elementsAmbigus
        self.commentaires = commentaires
    }

    enum CodingKeys: String, CodingKey {
        case champsManquants = "champs_manquants"
        case sectionsManquantes = "sections_manquantes"
        case elementsAmbigus = "elements_ambigus"
        case commentaires
    }
}

public struct PipelineOutput: Sendable {
    public let normalizedDocument: NormalizedDocument
    public let outputDocumentURL: URL?
    public let validationReportURL: URL?

    public init(normalizedDocument: NormalizedDocument, outputDocumentURL: URL?, validationReportURL: URL?) {
        self.normalizedDocument = normalizedDocument
        self.outputDocumentURL = outputDocumentURL
        self.validationReportURL = validationReportURL
    }
}

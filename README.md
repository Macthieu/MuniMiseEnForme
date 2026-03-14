# MuniMiseEnForme

MuniMiseEnForme est une application macOS locale de reconstruction et normalisation documentaire municipale.

Nom technique: `MuniMiseEnForme`

## Mission

Transformer des documents hétérogènes en sorties structurées et conformes aux exigences documentaires municipales.

## Positionnement

`MuniMiseEnForme` est:
- un utilitaire autonome local sur macOS;
- un worker documentaire réutilisable par Orchiviste (cockpit/hub de l'écosystème).

Le logiciel n'est pas un orchestrateur de flux universel. Il applique une logique documentaire métier municipale.

## Principe de séparation (règle non négociable)

1. **Structuration**: Foundation Models (ou fallback déterministe) comprend le contenu et produit un JSON strict.
2. **Mise en forme**: le moteur documentaire applique les styles Word depuis un gabarit.

Le modèle IA **ne décide jamais** du rendu final DOCX.

## MVP actuel (v0.1.0-alpha)

- Import d'un fichier source `.docx`
- Extraction OpenXML texte + structure de base (titres/listes/paragraphes)
- Structuration vers JSON normalisé
- Validation de champs/sections minimales
- Génération DOCX à partir d'un gabarit officiel (injection de métadonnées + blocs)
- Vérification stricte des styles Word requis dans le gabarit
- Rapport de validation JSON
- Mode CLI
- Mode worker (contrat JSON stable)
- UI macOS SwiftUI simple

## Limites réelles DOCX en Swift (transparence)

Swift natif n'offre pas aujourd'hui l'équivalent mature de `Open XML SDK` (.NET) pour une édition DOCX complexe avec très haute fidélité Word (styles avancés, sections complexes, champs dynamiques, TOC complexe, etc.).

Le MVP utilise une approche locale OpenXML pragmatique:
- décompression DOCX (`ditto`),
- modification ciblée XML,
- recompression (`zip`).

### Recommandation architecture cible production

Pour une conformité Word municipale stricte à long terme:
- garder l'app/macOS et l'orchestration en Swift;
- isoler un moteur documentaire auxiliaire local dédié (`.NET + Open XML SDK`) derrière un contrat JSON versionné.

Ce moteur peut être branché sans changer les modules métier grâce aux protocoles (`TemplateRenderer`).

## Architecture

Voir [docs/architecture.md](docs/architecture.md).
Guide Foundation Models: `docs/foundation-models.md`.

## Arborescence

```text
MuniMiseEnForme/
  Package.swift
  Sources/
    MMFDomain/
    MMFCore/
    MMFInfrastructureLogging/
    MMFInfrastructureDocx/
    MMFInfrastructureFoundationModels/
    MMFFeatureImport/
    MMFFeatureExtraction/
    MMFFeatureStructuring/
    MMFFeatureValidation/
    MMFFeatureTemplateEngine/
    MMFFeatureOutput/
    MMFFeatureWorker/
    MuniMiseEnFormeCLI/
    MuniMiseEnFormeApp/
  Resources/
    Schemas/
    Examples/
    Templates/
  Tests/
  docs/
  .github/
```

## Exécution locale

Pré-requis:
- macOS 14+
- Xcode 16+ ou Swift 6.2+
- outils système: `ditto`, `zip`

### Build

```bash
swift build
```

### Tests

```bash
swift test
```

### CLI

```bash
swift run muni-mise-en-forme help
```

Analyse seule:

```bash
swift run muni-mise-en-forme analyze \
  --source /chemin/source.docx \
  --json /chemin/sortie.normalized.json
```

Pipeline complet:

```bash
swift run muni-mise-en-forme run \
  --source /chemin/source.docx \
  --template /chemin/template.docx \
  --output /chemin/final.docx \
  --report /chemin/validation.json \
  --json /chemin/normalized.json
```

Mode worker:

```bash
swift run muni-mise-en-forme worker \
  --request-json /chemin/request.json \
  --response-json /chemin/response.json \
  --normalized-json /chemin/normalized.json
```

## Contrat worker (résumé)

Entrée JSON:

```json
{
  "contract_version": "1.0",
  "source_docx": "/abs/source.docx",
  "template_docx": "/abs/template.docx",
  "output_docx": "/abs/output.docx",
  "report_json": "/abs/report.json",
  "structuring_mode": "foundationModelsPreferred"
}
```

Sortie JSON:

```json
{
  "contract_version": "1.0",
  "success": true,
  "output_docx": "/abs/output.docx",
  "normalized_json": "/abs/normalized.json",
  "report_json": "/abs/report.json",
  "warnings": [],
  "errors": []
}
```

## Versionnage et releases

- Schéma: **SemVer**
- État initial: `v0.1.0-alpha`
- Tant que le contrat worker/JSON peut changer: pré-1.0
- Première cible stable: `v1.0.0` quand:
  - contrat worker figé,
  - moteur documentaire validé,
  - tests de non-régression DOCX en place.

Template release notes: `.github/release-template.md`
Guide versioning: `docs/versioning.md`

## Limitations connues (MVP)

- Intégration Foundation Models: bridge actif uniquement sur environnements compatibles (`macOS 26+` + Apple Intelligence disponible). Sinon fallback déterministe.
- Extraction DOCX: centrée sur `word/document.xml`, couverture partielle des cas complexes (zones de texte, notes, objets imbriqués).
- TOC Word: préparation structurelle, mise à jour finale par Word/LibreOffice peut être nécessaire.
- Fidélité avancée Word: insuffisante pour certains documents complexes sans moteur auxiliaire spécialisé.

## Roadmap V2 (résumé)

- Classifieur type documentaire (Core ML)
- Score de conformité
- Multi-gabarits
- Export PDF
- Mode lot
- Intégration Orchiviste
- Moteur documentaire auxiliaire local (option .NET OpenXML)
- Contrats worker versionnés (`v1`, `v2`)

## Licence

Ce projet est publié sous licence GNU GPL v3.0.
Voir `LICENSE`.

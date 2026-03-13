# Architecture - MuniMiseEnForme

## 1) Contraintes techniques auditées

- Local-first obligatoire.
- macOS natif et Swift prioritaire.
- Séparation stricte entre compréhension (IA) et rendu documentaire (template engine).
- Conformité documentaire municipale prioritaire.
- Préparation native mode worker pour Orchiviste.

## 2) Faisabilité Swift DOCX

### Faisable nativement en Swift

- Import/validation de fichier `.docx`.
- Lecture OpenXML par extraction ZIP + parsing XML.
- Structuration JSON métier.
- Validation forte du JSON.
- Injection de contenu dans un gabarit DOCX simple à intermédiaire.
- Pipeline CLI/worker/UI macOS.

### Limites Swift actuelles

- Écosystème DOCX avancé moins mature que `.NET Open XML SDK`.
- Gestion haute fidélité des sections complexes Word, champs dynamiques, TOC complexe, références croisées: effort élevé en Swift pur.
- Maintenabilité plus difficile si on réimplémente une large portion d'OpenXML.

## 3) Décision DOCX recommandée

### MVP actuel

- Moteur DOCX local Swift/OpenXML minimal pour produire une première version utilisable.
- Garantit l'autonomie locale et la séparation claire des responsabilités.

### Cible production recommandée

- Conserver Swift pour UI/orchestration/métier.
- Isoler un moteur documentaire auxiliaire local (ex: `.NET + Open XML SDK`) pour la fidélité Word avancée.
- Contrat IPC fichier/JSON stable, versionné et testable.

## 4) Pipeline métier

1. Import DOCX source
2. Extraction structure intermédiaire
3. Structuration JSON via Foundation Models (ou fallback déterministe)
4. Validation JSON
5. Chargement gabarit
6. Injection des métadonnées + blocs stylés
7. Génération DOCX
8. Rapport de validation
9. Exécution possible via CLI/Worker/UI

## 5) Modules

- `MMFDomain`: modèles métier et contrat JSON.
- `MMFCore`: protocoles, erreurs, pipeline orchestration.
- `MMFInfrastructureFoundationModels`: bridge local Foundation Models.
- `MMFInfrastructureDocx`: extraction/composition OpenXML locale.
- `MMFInfrastructureLogging`: journalisation.
- `MMFFeatureImport`: validation + chargement source.
- `MMFFeatureExtraction`: conversion DOCX -> structure intermédiaire.
- `MMFFeatureStructuring`: structuration JSON.
- `MMFFeatureValidation`: validation du JSON normalisé.
- `MMFFeatureTemplateEngine`: application du gabarit et styles.
- `MMFFeatureOutput`: sortie et rapport.
- `MMFFeatureWorker`: contrat exécutable sans UI.
- `MuniMiseEnFormeCLI`: interface en ligne de commande.
- `MuniMiseEnFormeApp`: UI SwiftUI locale.

## 6) Contrats d'interface

- `DocumentImporter`
- `DocumentExtractor`
- `ContentStructurer`
- `DocumentValidator`
- `TemplateRenderer`
- `ValidationReportWriter`

Ces protocoles permettent de remplacer une implémentation sans réécrire le pipeline.

Le worker transporte `contract_version` pour stabiliser l'intégration future Orchiviste.

## 7) Stratégie Git/GitHub

- Branche principale: `main`.
- Versionnage: SemVer.
- Version initiale: `v0.1.0-alpha`.
- Tags de release: `vX.Y.Z`.
- CI minimale: build + tests sur macOS.
- Release notes via template standardisé.

## 8) Délimitation MVP vs futur

### MVP

- Source `.docx` unique.
- Extraction et structuration de base.
- Validation JSON minimale.
- Génération DOCX par gabarit.
- Rapport JSON.
- CLI + worker + UI simple.

### Futur

- multi-types documentaires avancés;
- classifieur Core ML;
- score conformité;
- mode lot;
- export PDF;
- intégration Orchiviste;
- moteur auxiliaire DOCX haute fidélité.

# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog, and this project adheres to Semantic Versioning.

## [0.2.0-alpha] - 2026-03-14

### Added
- Canonical OrchivisteKit CLI mode via `run --request <request.json> --result <result.json>`.
- Bridge adapter between `ToolRequest/ToolResult` and the existing worker pipeline.
- Interop tests for canonical request mapping and canonical status results.

### Changed
- README and contribution docs aligned with OrchivisteKit integration and release readiness.
- Release/versioning documentation aligned for `v0.2.0-alpha`.

## [0.1.0-alpha] - 2026-03-12

### Added
- Modular Swift package architecture (Domain/Core/Features/Infrastructure).
- Local pipeline: import DOCX, extraction OpenXML, structuring JSON, validation, templated generation, validation report.
- CLI commands: `run`, `analyze`, `worker`.
- Worker input/output contract for future Orchiviste integration.
- Basic SwiftUI macOS UI for source/template selection and pipeline execution.
- JSON schema and sample files.
- Project docs: README, architecture notes, roadmap and limitations.
- GitHub CI workflow (build + tests on macOS).
- Validation stricte des styles requis dans les gabarits DOCX.
- Versionnement du contrat worker via `contract_version`.
- Tests d'intégration template DOCX (cas succès/échec styles).

### Known Limitations
- Foundation Models real inference bridge is scaffolded but not finalized.
- DOCX high-fidelity rendering for complex Word constructs is partial in this MVP.

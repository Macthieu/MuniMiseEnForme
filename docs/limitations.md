# Limites connues (MVP v0.2.0-alpha)

1. Foundation Models
- Le bridge est présent mais activé seulement sur plateformes compatibles Foundation Models (`macOS 26+`).
- En cas d'indisponibilité, fallback déterministe.

2. DOCX extraction
- Extraction prioritairement via `word/document.xml`.
- Couverture partielle des zones avancées Word (objets, notes complexes, champs imbriqués).

3. DOCX génération
- Injection XML guidée par template et styles nommés.
- Fidélité non garantie pour tous les documents Word complexes municipaux.

4. Table des matières
- La structure est préparée, mais la mise à jour de certains champs Word peut nécessiter une ouverture/recalcul côté Word.

5. Validation
- Validation MVP orientée présence/structure minimale.
- Les règles métier de conformité exhaustive restent à enrichir.

6. Interop OrchivisteKit (alpha)
- Le mode canonique `run --request/--result` est actuellement basé sur des fichiers JSON locaux.
- L'orchestration distante et le streaming d'événements ne sont pas couverts dans cette version alpha.

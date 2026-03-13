# Versionnage et publication

## SemVer

- `MAJOR`: rupture de contrat (worker/schema/API)
- `MINOR`: nouvelles fonctionnalités rétrocompatibles
- `PATCH`: correctifs rétrocompatibles

## Point de départ

- Version initiale proposée: `v0.1.0-alpha`

## Politique de tags

- `v0.1.0-alpha`
- `v0.1.0-beta`
- `v0.1.0`
- ensuite `v0.2.0`, `v0.2.1`, etc.

## Messages de commit recommandés

- `feat(structuring): add deterministic heading hierarchy mapping`
- `feat(template): inject normalized blocks into DOCX template`
- `fix(validation): report missing level-1 section`
- `docs(architecture): document DOCX hybrid strategy`
- `ci(github): add macOS build and test workflow`

## Procédure release GitHub (résumé)

1. Mettre à jour `CHANGELOG.md`
2. Créer le tag `vX.Y.Z`
3. Publier une release avec `.github/release-template.md`
4. Attacher notes + limitations + migrations

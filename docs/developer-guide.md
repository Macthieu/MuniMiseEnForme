# Guide développeur

## Principes

- Local-first
- Séparation stricte structuration vs rendu
- Protocol-first pour remplacer les implémentations

## Points d'extension

- `ContentStructurer`: brancher Foundation Models réel ou autre moteur local
- `TemplateRenderer`: brancher un moteur DOCX haute fidélité auxiliaire
- `DocumentValidator`: ajouter règles de conformité métier

## Commandes utiles

```bash
swift build
swift test
swift run muni-mise-en-forme help
```

## Qualité

- Ajouter un test à chaque règle métier ajoutée.
- Ne jamais confondre extraction/structuration et mise en forme.
- Conserver les contrats JSON et worker rétrocompatibles dès `v1`.

# Installation locale

## Pré-requis

- macOS 14+
- Swift 6.2+
- Xcode 16+ (recommandé)
- outils système `ditto` et `zip` disponibles (natif macOS)

## Cloner et construire

```bash
git clone <URL_DU_REPO>
cd MuniMiseEnForme
swift build
```

## Lancer les tests

```bash
swift test
```

## Lancer la CLI

```bash
swift run muni-mise-en-forme help
```

## Ouvrir l'app SwiftUI

Le target app est inclus dans le package:

```bash
swift run muni-mise-en-forme-app
```

Note: selon la configuration locale, il peut être plus confortable d'ouvrir le package dans Xcode et exécuter le target `MuniMiseEnFormeApp`.

# Foundation Models - intégration locale

## Objectif

Le module Foundation Models est utilisé uniquement pour:
- compréhension du contenu;
- structuration;
- extraction vers JSON strict.

Il n'est jamais utilisé pour la mise en forme Word finale.

## Implémentation actuelle

- Bridge implémenté dans `MMFInfrastructureFoundationModels/FoundationModelsClient.swift`.
- Activation uniquement si:
  - framework importable,
  - `macOS 26+`,
  - modèle système disponible.
- Sinon, fallback déterministe (`DocumentStructurer` mode local).

## Sécurité de sortie

- Prompt strict JSON-only.
- En cas de sortie bruitée, tentative d'extraction du premier objet JSON.
- En cas d'échec, fallback déterministe avec commentaire de validation.

## Limites

- Dépend de la disponibilité Apple Intelligence locale.
- Comportement modèle à valider sur corpus documentaire municipal réel.

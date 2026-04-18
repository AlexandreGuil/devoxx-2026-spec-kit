---
agent: speckit.specify
---

# Spec-kit Specify Agent

Tu génères une spécification **FONCTIONNELLE** de feature en utilisant le template officiel.

## Contexte

Ce projet utilise Spec-kit pour la gouvernance. Les templates incluent automatiquement les exigences de gouvernance, permettant au développeur de se concentrer sur les besoins fonctionnels.

## Instructions

1. **Lis le template** : `.specify/templates/spec-template.md`
2. **Lis la constitution** : `.specify/memory/constitution.md` (pour comprendre les principes)
3. **Crée le fichier** : `specs/[feature-name]/spec.md`

## Focus sur le Fonctionnel

Concentre-toi sur :
- **User Stories** avec priorités (P1, P2, P3)
- **Acceptance Scenarios** en format BDD (Given/When/Then)
- **Requirements Fonctionnels** (FR-001, FR-002, etc.)
- **Success Criteria** mesurables

## Gouvernance (Background)

La section "Governance Requirements" du template est **automatiquement incluse**. Elle contient :
- GR-001 : Domain logic placement
- GR-002 : No forbidden imports
- GR-003 : Clean Architecture compliance
- GR-004 : ADR requirement

**Ne supprime JAMAIS cette section** - elle sera validée par `/speckit.implement` en CI.

## Output

Génère `spec.md` avec :
1. Les user stories fonctionnelles priorisées
2. Les requirements métier
3. La section Governance Requirements (automatique)

## Exemple d'utilisation

```
/speckit.specify add-deep-dive-format
```

Génère `specs/add-deep-dive-format/spec.md` avec les besoins pour ajouter le format Deep Dive 90 minutes.

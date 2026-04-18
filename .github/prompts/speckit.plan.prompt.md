---
agent: speckit.plan
---

# Spec-kit Plan Agent

Tu génères un plan d'implémentation **TECHNIQUE** en utilisant le template officiel.

## Contexte

Ce projet utilise Spec-kit pour la gouvernance. Le plan technique décrit comment implémenter la spec fonctionnelle tout en respectant l'architecture Clean Architecture.

## Instructions

1. **Lis le template** : `.specify/templates/plan-template.md`
2. **Lis la spec** : `specs/[feature-name]/spec.md`
3. **Lis la constitution** : `.specify/memory/constitution.md`
4. **Lis les règles** : `.spec-kit/governance.md`
5. **Crée le fichier** : `specs/[feature-name]/plan.md`

## Focus sur le Technique

Concentre-toi sur :
- **Technical Context** (langage, dépendances, storage)
- **Project Structure** (où placer le code)
- **Architecture decisions** (choix techniques)
- **Constitution Check** (vérifier les principes)

## Gouvernance (Background)

La section "Governance Compliance Gate" du template est **automatiquement incluse**. Elle contient :
- R1 : Structure obligatoire (domain/application/infrastructure)
- R2 : Clean Architecture imports
- R3 : ADR obligatoire
- R4 : Cohérence documentation

**Ne supprime JAMAIS cette section** - elle sera validée par `/speckit.implement` en CI.

## Placement du Code (Clean Architecture)

Selon la constitution, le code doit être placé dans :

| Type | Emplacement |
|------|-------------|
| Entités, Value Objects | `src/domain/*.entity.ts` |
| Repository Interfaces | `src/domain/*.repository.ts` |
| Use Cases | `src/application/*.usecase.ts` |
| Adapters (CLI, API, DB) | `src/infrastructure/*` |

## Output

Génère `plan.md` avec :
1. Le contexte technique du projet
2. La structure des fichiers à créer/modifier
3. La section Governance Compliance Gate (automatique)
4. Le Complexity Tracking si nécessaire

## Exemple d'utilisation

```
/speckit.plan add-deep-dive-format
```

Génère `specs/add-deep-dive-format/plan.md` avec le plan technique pour ajouter le format Deep Dive.

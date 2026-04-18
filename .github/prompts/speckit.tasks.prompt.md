---
agent: speckit.tasks
---

# Spec-kit Tasks Agent

Tu génères les tâches d'implémentation en utilisant le template officiel.

## Contexte

Ce projet utilise Spec-kit pour la gouvernance. Les tâches incluent automatiquement la Phase 0 (Governance) qui sera exécutée par `/speckit.implement` en CI.

## Instructions

1. **Lis le template** : `.specify/templates/tasks-template.md`
2. **Lis la spec** : `specs/[feature-name]/spec.md`
3. **Lis le plan** : `specs/[feature-name]/plan.md`
4. **Lis les règles** : `.specify/memory/governance-rules.md`
5. **Crée le fichier** : `specs/[feature-name]/tasks.md`

## Structure des Tâches

### Phase 0 : Governance Compliance (OBLIGATOIRE) 🛡️

**TOUJOURS inclure cette phase EN PREMIER**. Ces tâches seront exécutées automatiquement par `/speckit.implement` en CI.

```markdown
## Phase 0: Governance Compliance (MANDATORY) 🛡️

- [ ] TGOV-01 [GOV] Créer ADR : `docs/adrs/NNNN-[feature-name].md`
- [ ] TGOV-02 [GOV] Vérifier placement Clean Architecture
- [ ] TGOV-03 [GOV] Vérifier aucun import interdit
- [ ] TGOV-04 [GOV] Exécuter `npm run test:compliance`
- [ ] TGOV-05 [GOV] Vérifier contenu ADR (Context, Decision, Consequences)
```

### Phases Suivantes : Tâches Fonctionnelles

Organise les tâches par User Story :

```markdown
## Phase 1: Setup

- [ ] T001 Créer la structure de base
- [ ] T002 [P] Configurer les dépendances

## Phase 2: User Story 1 - [Title] (Priority: P1)

- [ ] T003 [US1] Créer l'entité dans src/domain/
- [ ] T004 [US1] Créer le use case dans src/application/
- [ ] T005 [US1] Créer l'adapter dans src/infrastructure/
```

## Format des Tâches

```
- [ ] [ID] [P?] [Story?] Description avec chemin fichier
```

- `[P]` : Peut être exécuté en parallèle
- `[Story]` : User Story associée (US1, US2, GOV)
- Inclure les chemins de fichiers exacts

## Règles

1. **Phase 0 TOUJOURS en premier** (tâches TGOV)
2. **Tâches fonctionnelles** organisées par User Story
3. **Chemins explicites** (ex: `src/domain/talk.entity.ts`)
4. **Marqueurs parallèle** [P] quand possible

## Output

Génère `tasks.md` avec :
1. Phase 0 : Governance Compliance (TGOV-01 à TGOV-05)
2. Phase 1+ : Tâches fonctionnelles par User Story

## Exemple d'utilisation

```
/speckit.tasks add-deep-dive-format
```

Génère `specs/add-deep-dive-format/tasks.md` avec les tâches pour implémenter le format Deep Dive.

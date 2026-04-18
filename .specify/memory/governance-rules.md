# Governance Rules for Spec-kit

> **IMPORTANT**: Ce fichier définit les règles de gouvernance qui DOIVENT être intégrées
> dans chaque `tasks.md` généré par `/speckit.tasks`. Ces règles sont automatiquement
> validées par la CI/CD.

## Règles Obligatoires

### Rule 1: Clean Architecture Structure

**Validation CI**: Le projet DOIT respecter la Clean Architecture avec trois couches :

```yaml
required_directories:
  - src/domain/ # Entités métier pures (0 dépendances)
  - src/application/ # Cas d'usage (orchestration)
  - src/infrastructure/ # Adaptateurs (implémentations)
  - docs/adrs/ # Architecture Decision Records
```

**Tâche tasks.md associée** :

```markdown
- [ ] TGOV-01 [GOV] Verify Clean Architecture structure exists (src/domain, src/application, src/infrastructure)
```

### Rule 2: Dependency Direction

**Validation CI**: Les imports DOIVENT respecter le flux :

```
Infrastructure → Application → Domain
```

**Interdit** :

- Domain ne peut PAS importer de Application ou Infrastructure
- Application ne peut PAS importer de Infrastructure

**Tâche tasks.md associée** :

```markdown
- [ ] TGOV-02 [GOV] Verify no forbidden imports in domain layer (grep for '../application' or '../infrastructure')
- [ ] TGOV-03 [GOV] Verify no forbidden imports in application layer (grep for '../infrastructure')
```

### Rule 3: ADR Requirement

**Validation CI**: Toute décision architecturale DOIT être documentée.

**Règle** : Au moins un fichier `.md` dans `docs/adrs/`

**Tâche tasks.md associée** :

```markdown
- [ ] TGOV-04 [GOV] Create or update ADR in docs/adrs/NNNN-[feature-name].md
```

### Rule 4: AI Documentation Coherence

**Validation CI**: Un LLM (GitHub Copilot) vérifie la cohérence entre :

- Le code modifié
- Les ADRs existants
- Les règles de governance.md

**Tâche tasks.md associée** :

```markdown
- [ ] TGOV-05 [GOV] Ensure ADR content matches implementation (AI will verify in CI)
```

---

## Template de Phase Governance pour tasks.md

Chaque `tasks.md` généré par `/speckit.tasks` DOIT inclure cette phase :

```markdown
## Phase 0: Governance Compliance (MANDATORY)

**Purpose**: Ensure all governance rules are satisfied before merging

**⚠️ CRITICAL**: PR will be BLOCKED if these tasks are not completed

### Documentation Tasks

- [ ] TGOV-01 [GOV] Create/Update ADR: docs/adrs/NNNN-[feature-name].md
  - Document: Context, Decision, Consequences
  - Follow format in docs/adrs/0001-\*.md

### Structure Validation Tasks

- [ ] TGOV-02 [GOV] Verify new code is in correct layer:

  - Domain entities → src/domain/
  - Use cases → src/application/
  - Adapters/CLI → src/infrastructure/

- [ ] TGOV-03 [GOV] Verify no forbidden imports:
  - Run: `grep -r "from.*infrastructure" src/domain/` (must be empty)
  - Run: `grep -r "from.*application" src/domain/` (must be empty)

### Pre-Merge Validation

- [ ] TGOV-04 [GOV] Run local governance check: `npm run test:compliance`
- [ ] TGOV-05 [GOV] Commit message references ADR if architectural change

**Checkpoint**: Governance OK - CI/CD will validate automatically on PR
```

---

## Intégration avec CI/CD

Le fichier `.github/workflows/spec-kit-ci.yml` exécute automatiquement :

1. **Static Checks** (shell scripts)

   - Rule 1: Directory structure
   - Rule 2: Import direction
   - Rule 3: ADR presence

2. **AI Review** (GitHub Copilot via GitHub Models)
   - Rule 4: Documentation coherence
   - Analyse sémantique du diff vs ADRs

---

## Pour /speckit.tasks

Quand tu génères un `tasks.md`, tu DOIS :

1. **Toujours inclure Phase 0: Governance** comme première phase après Setup
2. **Ajouter une tâche ADR** pour chaque nouvelle entité ou pattern
3. **Référencer ce fichier** dans les tâches governance

Exemple de prompt interne :

```
Avant de générer les tâches métier, inclure OBLIGATOIREMENT:
- Phase 0: Governance Compliance (copier depuis .specify/memory/governance-rules.md)
- Une tâche TGOV-01 pour créer l'ADR de cette feature
- Les tâches TGOV-02 à TGOV-05 pour la validation
```

---
agent: speckit.implement
---

# Spec-kit Implement Agent (CI/CD Validation)

Tu exécutes les tâches de validation de gouvernance définies dans `tasks.md`.

## Contexte

Ce projet utilise Spec-kit pour la gouvernance. En CI/CD, cet agent exécute automatiquement les tâches TGOV (Phase 0) pour valider la conformité avant le merge.

## Instructions

1. **Lis les tâches** : `specs/[feature-name]/tasks.md`
2. **Lis la constitution** : `.specify/memory/constitution.md`
3. **Lis les règles** : `.spec-kit/governance.md`
4. **Exécute Phase 0** : Les tâches TGOV-01 à TGOV-05

## Phase 0 : Tâches de Validation (EXÉCUTION AUTOMATIQUE)

### TGOV-01 : Vérifier ADR

```bash
# Vérifier qu'un ADR existe pour les changements domain/application
ls docs/adrs/*.md | head -5
# Vérifier le format du dernier ADR
cat docs/adrs/$(ls -t docs/adrs/*.md | head -1)
```

**PASS** si : Au moins un ADR existe et contient Context, Decision, Consequences
**FAIL** si : Aucun ADR ou ADR incomplet

### TGOV-02 : Vérifier Structure Clean Architecture

```bash
# Vérifier les répertoires obligatoires
test -d src/domain && echo "✅ src/domain exists"
test -d src/application && echo "✅ src/application exists"
test -d src/infrastructure && echo "✅ src/infrastructure exists"
test -d docs/adrs && echo "✅ docs/adrs exists"
```

**PASS** si : Les 4 répertoires existent
**FAIL** si : Un répertoire manque

### TGOV-03 : Vérifier Direction des Imports

```bash
# Domain ne doit PAS importer de application ou infrastructure
grep -rE "from\s+['\"]\.\./(infrastructure|application)" src/domain/ && echo "❌ FAIL" || echo "✅ PASS"

# Application ne doit PAS importer de infrastructure
grep -rE "from\s+['\"]\.\./(infrastructure)" src/application/ && echo "❌ FAIL" || echo "✅ PASS"
```

**PASS** si : Aucun import interdit trouvé
**FAIL** si : Import interdit détecté

### TGOV-04 : Exécuter Validation Locale

```bash
npm run test:compliance
```

**PASS** si : Exit code 0
**FAIL** si : Exit code != 0

### TGOV-05 : Vérifier Qualité ADR

Pour chaque ADR modifié ou créé, vérifier qu'il contient :
- **Context** : Pourquoi cette décision ?
- **Decision** : Qu'avons-nous choisi ?
- **Consequences** : Quels sont les impacts ?

**PASS** si : Les 3 sections sont présentes et non vides
**FAIL** si : Une section manque ou est vide

## Output

Génère un rapport JSON de compliance :

```json
{
  "feature": "[feature-name]",
  "timestamp": "2025-01-29T10:30:00Z",
  "phase0_governance": {
    "TGOV-01_adr_exists": "PASS",
    "TGOV-02_structure": "PASS",
    "TGOV-03_imports": "PASS",
    "TGOV-04_compliance": "PASS",
    "TGOV-05_adr_quality": "PASS"
  },
  "compliance_score": 100,
  "status": "PASS",
  "details": {
    "adrs_found": ["0001-*.md", "0002-*.md"],
    "directories_verified": ["src/domain", "src/application", "src/infrastructure", "docs/adrs"],
    "forbidden_imports": []
  }
}
```

## Règles de Décision

| Situation | Score | Status |
|-----------|-------|--------|
| Toutes les tâches TGOV passent | 100 | PASS |
| 4/5 tâches TGOV passent | 80 | PASS |
| 3/5 tâches TGOV passent | 60 | FAIL |
| < 3 tâches TGOV passent | < 60 | FAIL |

**Seuil de compliance** : 80 (configurable dans workflow)

## Exemple d'utilisation en CI

```yaml
# Dans spec-kit-ci.yml
- name: "🤖 Execute /speckit.implement"
  run: |
    copilot --prompt "Execute /speckit.implement for governance validation" \
      --allow-all-tools --allow-all-paths
```

## Intégration avec les 3 Agents CI

Cet agent peut être appelé par les 3 agents de validation :
- **Agent 1 (Structure)** : Appelle TGOV-02, TGOV-03
- **Agent 2 (ADR)** : Appelle TGOV-01, TGOV-05
- **Agent 3 (Coherence)** : Appelle TGOV-04, vérifie cohérence globale

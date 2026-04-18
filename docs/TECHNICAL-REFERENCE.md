# Documentation Technique - Spec-kit Governance Pipeline

> **Version** : 3.0.0
> **Date** : 2026-03-17
> **Auteur** : Équipe Devoxx 2026

---

## Table des Matières

1. [Vue d'Ensemble](#1-vue-densemble)
2. [Architecture CI/CD](#2-architecture-cicd)
3. [Modes de Validation](#3-modes-de-validation)
4. [Les 3 Agents de Gouvernance](#4-les-3-agents-de-gouvernance)
5. [Actions Composites](#5-actions-composites)
6. [Workflows Réutilisables](#6-workflows-réutilisables)
7. [Scripts et Utilitaires](#7-scripts-et-utilitaires)
8. [Système de Scoring](#8-système-de-scoring)
9. [Format des Rapports JSON](#9-format-des-rapports-json)
10. [Commentaires PR User-Friendly](#10-commentaires-pr-user-friendly)
11. [Configuration et Secrets](#11-configuration-et-secrets)
12. [Dépannage et FAQ](#12-dépannage-et-faq)

---

## 1. Vue d'Ensemble

### 1.1 Objectif

Le pipeline de gouvernance Spec-kit valide automatiquement que chaque Pull Request respecte :

- **Clean Architecture** (structure et imports)
- **Règle d'Or des ADRs** (documentation obligatoire)
- **Cohérence Code-Documentation** (Ubiquitous Language)

### 1.2 Flux d'Exécution

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           SPEC-KIT GOVERNANCE PIPELINE                      │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────┐                                                               │
│  │  PUSH /  │                                                               │
│  │    PR    │                                                               │
│  └────┬─────┘                                                               │
│       │                                                                     │
│       ▼                                                                     │
│  ┌──────────────────┐                                                       │
│  │  📋 PREPARE      │  Détecte fichiers modifiés, extrait contexte          │
│  │  (7-10 sec)      │  Output: changed-files, branch-name, feature-name     │
│  └────────┬─────────┘                                                       │
│           │                                                                 │
│           ├──────────────────┬──────────────────┐                           │
│           ▼                  ▼                  ▼                           │
│  ┌────────────────┐ ┌────────────────┐ ┌────────────────┐                  │
│  │ 🔍 AGENT 1     │ │ 📚 AGENT 2     │ │ 🔗 AGENT 3     │  PARALLÈLE       │
│  │ Structure      │ │ ADR Review     │ │ Coherence      │  (~1-2 min)      │
│  │ Validator      │ │                │ │ Checker        │                  │
│  └────────┬───────┘ └────────┬───────┘ └────────┬───────┘                  │
│           │                  │                  │                           │
│           └──────────────────┴──────────────────┘                           │
│                              │                                              │
│                              ▼                                              │
│                    ┌──────────────────┐                                     │
│                    │ 📊 AGGREGATE     │  Calcule score, génère rapport      │
│                    │ & REPORT         │  Poste commentaire PR formaté       │
│                    │ (10-15 sec)      │                                     │
│                    └────────┬─────────┘                                     │
│                             │                                               │
│                             ▼                                               │
│                    ┌──────────────────┐                                     │
│                    │ ✅ PASS (≥80)    │                                     │
│                    │ ❌ FAIL (<80)    │                                     │
│                    └──────────────────┘                                     │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 1.3 Arborescence des Fichiers

```
.github/
├── actions/                          # Actions composites réutilisables
│   ├── setup-environment/
│   │   └── action.yml                # Setup Node.js, Python, uv, CLIs
│   ├── run-agent/
│   │   └── action.yml                # Exécute un agent avec I/O standardisé
│   └── post-pr-comment/
│       └── action.yml                # Poste commentaire PR formaté
│
├── agents/                           # Prompts des agents IA
│   ├── 01-structure-validator.agent.md
│   ├── 02-adr-reviewer.agent.md
│   └── 03-coherence-checker.agent.md
│
├── scripts/                          # Scripts d'exécution
│   ├── agent-structure-validator.sh  # Agent 1 (bash + Claude)
│   ├── agent-adr-reviewer.sh         # Agent 2 (bash + Claude)
│   ├── agent-coherence-checker.sh    # Agent 3 (bash + Claude)
│   ├── call-claude.sh                # Wrapper Claude Code CLI
│   └── format-pr-comment.js          # Formateur Markdown
│
├── workflows/                        # GitHub Actions workflows
│   ├── spec-kit-ci.yml               # Orchestrateur principal
│   ├── _agent-structure.yml          # Workflow réutilisable Agent 1
│   ├── _agent-adr.yml                # Workflow réutilisable Agent 2
│   └── _agent-coherence.yml          # Workflow réutilisable Agent 3
│
└── README.md                         # Documentation CI/CD
```

---

## 2. Architecture CI/CD

### 2.1 Orchestrateur Principal

**Fichier** : `.github/workflows/spec-kit-ci.yml`

**Déclencheurs** :
```yaml
on:
  pull_request:
    branches: [main]
    types: [opened, synchronize, reopened]
  push:
    branches: [main]
  workflow_dispatch:
```

**Jobs** :

| Job | Dépendances | Description |
|-----|-------------|-------------|
| `prepare` | - | Détecte les fichiers modifiés, extrait le contexte |
| `agent-structure` | `prepare` | Exécute Agent 1 (parallèle) |
| `agent-adr` | `prepare` | Exécute Agent 2 (parallèle) |
| `agent-coherence` | `prepare` | Exécute Agent 3 (parallèle) |
| `aggregate` | Tous les agents | Calcule le score final, poste le commentaire PR |
| `skip-notification` | `prepare` | Notifie si aucun fichier pertinent modifié |

### 2.2 Concurrence

```yaml
concurrency:
  group: governance-${{ github.event.pull_request.number || github.run_id }}
  cancel-in-progress: true
```

Un seul workflow de gouvernance s'exécute par PR. Les exécutions précédentes sont annulées si une nouvelle est déclenchée.

### 2.3 Permissions

```yaml
permissions:
  contents: read
  pull-requests: write
```

- `contents: read` : Lecture du code source
- `pull-requests: write` : Écriture des commentaires PR

### 2.4 Variables d'Environnement

| Variable | Valeur | Description |
|----------|--------|-------------|
| `COMPLIANCE_THRESHOLD` | `80` | Score minimum pour passer |
| `REQUIRE_AI_ANALYSIS` | `true` | Rend l'analyse IA obligatoire |

---

## 3. Modes de Validation

Le systeme supporte **deux modes de validation** selon la presence d'artefacts Spec-kit :

### 3.1 Mode Spec-kit Driven (Optimal)

Quand les artefacts Spec-kit existent (`specs/[feature]/` ou `.specify/specs/[feature]/`) :

- `spec.md` → User stories extraites
- `plan.md` → Fichiers planifies extraits
- `tasks.md` → Taches TGOV-* (gouvernance) extraites

Les agents utilisent ce contexte pour une validation enrichie :
- Agent 1 verifie que les fichiers planifies sont crees
- Agent 2 verifie que TGOV-01 (ADR) est complete
- Agent 3 verifie que les user stories sont implementees

### 3.2 Mode Legacy Fallback (Degrade)

Quand aucun artefact Spec-kit n'est trouve :
- Validation generique (Clean Architecture, presence ADR, coherence basique)
- Banner d'avertissement affiche dans le commentaire PR
- Incite a utiliser `/speckit.specify`, `/speckit.plan`, `/speckit.tasks`

### 3.3 Architecture Hybride

| Composant | Bash | Claude IA |
|-----------|------|-----------|
| Collecte de donnees | Rapide, fiable | Lent |
| Analyse semantique | Impossible | Excellent |
| Generation de rapports | Basique | Riche |
| Suggestions contextuelles | Impossible | Excellent |
| Fiabilite | 100% | Depend API |

**Approche** : Bash collecte les donnees → Claude IA analyse → Markdown output.
Si l'IA n'est pas disponible → CI echoue (pas de fallback, mode strict).

---

## 4. Les 3 Agents de Gouvernance

### 4.1 Agent 1 : Structure Validator

**Fichiers** :
- Prompt : `.github/agents/01-structure-validator.agent.md`
- Script : `.github/scripts/agent-structure-validator.sh`
- Workflow : `.github/workflows/_agent-structure.yml`

**Rôle** : Vérifier la conformité Clean Architecture

**Vérifications** :

| Check | Description | Criticité |
|-------|-------------|-----------|
| `src/domain/` | Répertoire domain existe | CRITICAL |
| `src/application/` | Répertoire application existe | CRITICAL |
| `src/infrastructure/` | Répertoire infrastructure existe | CRITICAL |
| `docs/adrs/` | Répertoire ADRs existe | CRITICAL |
| Imports interdits | Pas d'import infra/app dans domain | CRITICAL |

**Règles de Décision** :

```
PASS si:
  - Les 4 répertoires existent
  - ET forbidden_imports_count = 0
  - ET adr_count >= 1

FAIL si:
  - Un répertoire manque
  - OU imports interdits détectés
```

**Output JSON** :
```json
{
  "agent": "structure-validator",
  "checks": {
    "src_domain_exists": true,
    "src_application_exists": true,
    "src_infrastructure_exists": true,
    "docs_adrs_exists": true,
    "forbidden_imports_count": 0
  },
  "adr_count": 5,
  "specs": {
    "found": true,
    "location": ".specify/specs/feature-name"
  },
  "status": "PASS"
}
```

---

### 4.2 Agent 2 : ADR Reviewer

**Fichiers** :
- Prompt : `.github/agents/02-adr-reviewer.agent.md`
- Script : `.github/scripts/agent-adr-reviewer.sh`
- Workflow : `.github/workflows/_agent-adr.yml`

**Rôle** : Vérifier la présence ET la pertinence des ADRs

**Règle d'Or** (Constitution, Principe III) :

> "Toute modification de logique métier dans `src/application` ou `src/domain` DOIT être accompagnée d'un nouveau fichier `.md` dans `docs/adrs/`."

**Vérifications** :

| Check | Description | Criticité |
|-------|-------------|-----------|
| ADR Presence | Un ADR existe pour les changements domain/app | CRITICAL |
| ADR Quality | Score ≥ 70/100 (Context, Decision, Consequences) | HIGH |
| ADR Pertinence | L'ADR parle du même sujet que le code | HIGH |
| Task Integration | Tâche ADR complétée dans tasks.md | MEDIUM |

**Scoring Qualité ADR** :

| Élément | Points | Critères |
|---------|--------|----------|
| Context section | 20 | Explique POURQUOI |
| Decision section | 30 | Décrit QUOI |
| Consequences section | 20 | Liste pros ET cons |
| Related to spec/tasks | 15 | Lié à la feature |
| Proper formatting | 15 | Status, Date, numérotation |

**Matrice de Décision** :

| Situation | Décision |
|-----------|----------|
| Pas de changements domain/application | PASS (pas d'ADR requis) |
| Changements domain + ADR pertinent | PASS |
| Changements domain + ADR existe mais faible pertinence | NEEDS_REVIEW |
| Changements domain + pas d'ADR | FAIL |
| Nouvelle entité + pas d'ADR | FAIL |

**Output JSON** :
```json
{
  "agent": "adr-reviewer",
  "feature_name": "validation-titre",
  "domain_changes_count": 1,
  "adrs_found": 5,
  "adrs_in_pr": 1,
  "pertinence_check": [
    {
      "change": "src/domain/talk.entity.ts",
      "matching_adr": "0005-validation-titre.md",
      "pertinence": "HIGH",
      "reason": "ADR mentions title validation explicitly"
    }
  ],
  "status": "PASS"
}
```

---

### 4.3 Agent 3 : Coherence Checker

**Fichiers** :
- Prompt : `.github/agents/03-coherence-checker.agent.md`
- Script : `.github/scripts/agent-coherence-checker.sh`
- Workflow : `.github/workflows/_agent-coherence.yml`

**Rôle** : Vérifier la cohérence code-documentation

**Vérifications** :

| Check | Points | Description |
|-------|--------|-------------|
| Naming Coherence | 25 | Utilise l'Ubiquitous Language du glossaire |
| Architecture Coherence | 25 | Code placé dans la bonne couche |
| Domain Purity | 25 | Pas d'effets de bord dans domain |
| Business Rules | 25 | Règles documentées = règles implémentées |

**Violations Naming** (termes interdits) :
- `Manager`, `Helper`, `Util`, `Data`, `Info`, `Handler`

**Violations Domain Purity** :
- `console.log`, `console.error`, `console.warn`
- `fetch`, `axios`, `http`
- Imports vers infrastructure/application

**Calcul du Score** :

```
overall_coherence_score = naming + architecture + domain_purity + business_rules
                        = 25 + 25 + 25 + 25 = 100 (max)

Threshold: 80/100 pour PASS
```

**Output JSON** :
```json
{
  "agent": "coherence-checker",
  "scores": {
    "naming": 19,
    "architecture": 25,
    "domain_purity": 25,
    "business_rules": 25
  },
  "overall_coherence_score": 94,
  "naming_violations": 6,
  "forbidden_imports": 0,
  "side_effects": 0,
  "status": "NEEDS_REVIEW"
}
```

---

## 5. Actions Composites

### 5.1 setup-environment

**Fichier** : `.github/actions/setup-environment/action.yml`

**Rôle** : Configurer l'environnement d'exécution

**Inputs** :

| Input | Default | Description |
|-------|---------|-------------|
| `node-version` | `22` | Version Node.js |
| `python-version` | `3.12` | Version Python |
| `install-claude-cli` | `true` | Installer Claude Code CLI |
| `install-speckit-cli` | `true` | Installer Spec-kit CLI |

**Outputs** :

| Output | Description |
|--------|-------------|
| `cache-hit` | Si les dépendances npm étaient en cache |

**Étapes** :

1. Setup Node.js avec cache npm
2. `npm ci` (install dependencies)
3. Setup Python (si speckit-cli requis)
4. Install uv (fast Python package manager)
5. Install Spec-kit CLI via uv
6. Install Claude Code CLI via npm global

**Usage** :
```yaml
- uses: ./.github/actions/setup-environment
  with:
    node-version: '22'
    install-speckit-cli: 'false'  # Optionnel
```

---

### 5.2 run-agent

**Fichier** : `.github/actions/run-agent/action.yml`

**Rôle** : Exécuter un agent avec I/O standardisé

**Inputs** :

| Input | Required | Description |
|-------|----------|-------------|
| `agent-name` | ✅ | `structure-validator`, `adr-reviewer`, `coherence-checker` |
| `changed-files` | | Liste des fichiers modifiés |
| `branch-name` | | Nom de la branche |
| `feature-name` | | Nom de la feature |
| `domain-changes` | | Changements domain/app (pour ADR agent) |
| `adr-changes` | | Changements ADR (pour ADR agent) |

**Outputs** :

| Output | Description |
|--------|-------------|
| `status` | `PASS`, `FAIL`, ou `NEEDS_REVIEW` |
| `score` | Score 0-100 |
| `report-json` | Chemin vers le rapport JSON |
| `report-md` | Chemin vers le rapport Markdown |

**Mapping des Rapports** :

| Agent | JSON Report | MD Report |
|-------|-------------|-----------|
| `structure-validator` | `structure-validation-report.json` | `structure-validation-report.md` |
| `adr-reviewer` | `adr-review-report.json` | `adr-review-report.md` |
| `coherence-checker` | `coherence-check-report.json` | `coherence-check-report.md` |

**Usage** :
```yaml
- uses: ./.github/actions/run-agent
  with:
    agent-name: 'structure-validator'
    changed-files: ${{ needs.prepare.outputs.changed-files }}
    branch-name: ${{ needs.prepare.outputs.branch-name }}
  env:
    ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
```

---

### 5.3 post-pr-comment

**Fichier** : `.github/actions/post-pr-comment/action.yml`

**Rôle** : Poster un commentaire PR formaté avec les résultats

**Inputs** :

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `github-token` | ✅ | | Token GitHub pour API |
| `overall-status` | ✅ | | `PASS`, `FAIL`, `NEEDS_REVIEW` |
| `overall-score` | ✅ | | Score 0-100 |
| `threshold` | | `80` | Seuil de conformité |
| `structure-report` | | `structure-validation-report.json` | Chemin rapport Agent 1 |
| `adr-report` | | `adr-review-report.json` | Chemin rapport Agent 2 |
| `coherence-report` | | `coherence-check-report.json` | Chemin rapport Agent 3 |

**Fonctionnement** :

1. Appelle `format-pr-comment.js` pour générer le Markdown
2. Cherche un commentaire existant avec le marker `<!-- spec-kit-governance-report -->`
3. Met à jour le commentaire existant OU en crée un nouveau (idempotent)

**Usage** :
```yaml
- uses: ./.github/actions/post-pr-comment
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}
    overall-status: ${{ steps.calculate.outputs.status }}
    overall-score: ${{ steps.calculate.outputs.score }}
```

---

## 6. Workflows Réutilisables

### 6.1 Structure

Les workflows réutilisables permettent l'exécution parallèle des agents.

**Naming Convention** : Préfixe `_` pour les workflows internes (ex: `_agent-structure.yml`)

### 6.2 Interface Commune

Tous les workflows agents ont la même interface :

**Inputs** :
```yaml
inputs:
  changed-files:
    type: string
    default: ''
  branch-name:
    type: string
    default: ''
  feature-name:
    type: string
    default: ''
```

**Outputs** :
```yaml
outputs:
  status:
    value: ${{ jobs.*.outputs.status }}
  score:
    value: ${{ jobs.*.outputs.score }}
  report-json:
    value: ${{ jobs.*.outputs.report-json }}
```

**Secrets** :
```yaml
secrets:
  ANTHROPIC_API_KEY:
    required: true
```

### 6.3 Appel depuis l'Orchestrateur

```yaml
agent-structure:
  name: "🔍 Structure Validator"
  needs: prepare
  if: needs.prepare.outputs.skip != 'true'
  uses: ./.github/workflows/_agent-structure.yml
  with:
    changed-files: ${{ needs.prepare.outputs.changed-files }}
    branch-name: ${{ needs.prepare.outputs.branch-name }}
  secrets:
    ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
```

---

## 7. Scripts et Utilitaires

### 7.1 call-claude.sh

**Fichier** : `.github/scripts/call-claude.sh`

**Rôle** : Wrapper pour Claude Code CLI

**Usage** :
```bash
./call-claude.sh "<prompt>" "<output_file>" [format]
```

**Arguments** :

| Argument | Description |
|----------|-------------|
| `prompt` | Le prompt à envoyer à Claude |
| `output_file` | Fichier de sortie |
| `format` | `json` (default) ou `markdown` |

**Variables d'Environnement** :

| Variable | Required | Description |
|----------|----------|-------------|
| `ANTHROPIC_API_KEY` | ✅ | Clé API Anthropic |
| `REQUIRE_AI_ANALYSIS` | | Si `true`, échoue sans API key |

**Modèle Utilisé** : `claude-haiku-4-5` (le moins cher : $1/1M input, $5/1M output)

**Gestion des Erreurs** :

```
╔═══════════════════════════════════════════════════════════════╗
║  ❌ ERREUR: ANTHROPIC_API_KEY non configurée                  ║
╠═══════════════════════════════════════════════════════════════╣
║                                                               ║
║  L'analyse IA est OBLIGATOIRE pour la validation.             ║
║                                                               ║
║  💡 Pour configurer:                                          ║
║     1. Obtenez une clé sur console.anthropic.com              ║
║     2. Ajoutez le secret ANTHROPIC_API_KEY dans GitHub        ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
```

---

### 7.2 format-pr-comment.js

**Fichier** : `.github/scripts/format-pr-comment.js`

**Rôle** : Transformer les rapports JSON en Markdown user-friendly

**Usage** :
```bash
node format-pr-comment.js \
  --structure "structure-validation-report.json" \
  --adr "adr-review-report.json" \
  --coherence "coherence-check-report.json" \
  --status "PASS" \
  --score "95" \
  --threshold "80" \
  --output "pr-comment.md"
```

**Arguments** :

| Argument | Default | Description |
|----------|---------|-------------|
| `--structure` | `structure-validation-report.json` | Rapport Agent 1 |
| `--adr` | `adr-review-report.json` | Rapport Agent 2 |
| `--coherence` | `coherence-check-report.json` | Rapport Agent 3 |
| `--status` | `UNKNOWN` | Status global |
| `--score` | `0` | Score global |
| `--threshold` | `80` | Seuil |
| `--output` | `pr-comment.md` | Fichier de sortie |

**Fonctions Utilitaires** :

```javascript
// Génère une barre de progression Unicode
progressBar(score, max = 100, width = 20)
// Exemple: `████████████████████` 100%

// Retourne l'icône de status
statusIcon(status)
// PASS → ✅, FAIL → ❌, NEEDS_REVIEW → ⚠️

// Retourne l'icône check
checkIcon(value)
// true → ✅, false → ❌
```

---

## 8. Systeme de Scoring

### 8.1 Fix Critique (2026-01-31 — Commit 41d020e)

**Probleme** : Les PRs affichaient "FAILED!" mais le CI ne bloquait pas (exit code 0).

**Cause** : Le workflow utilisait le score numerique (`>= 80 = passed`) au lieu du statut des agents.
Avec un score de 80/100, `passed='true'` meme si un agent rapportait `FAIL`.

**Solution** : Utilisation du `OVERALL_STATUS` au lieu du score numerique :
```yaml
# AVANT (BUG) : score >= 80 = passed, meme si un agent FAIL
if: steps.calculate.outputs.passed != 'true'

# APRES (FIX) : statut agent prioritaire
if: steps.calculate.outputs.status == 'FAIL'
```

**Garantie** : Si **un seul agent** renvoie `FAIL` → CI echoue immediatement (exit 1).

### 8.2 Calcul du Score Final

```
# Score informatif (affiche dans le rapport)
BASE_SCORE = Coherence_Score (0-100)

# Ajustements
if ADR_STATUS == "FAIL":   BASE_SCORE -= 20
if STRUCTURE_STATUS == "FAIL": BASE_SCORE -= 10

FINAL_SCORE = clamp(BASE_SCORE, 0, 100)

# Statut decisionnel (PRIORITAIRE pour CI)
OVERALL_STATUS:
├── FAIL:         Si AU MOINS UN agent renvoie FAIL → Exit 1
├── NEEDS_REVIEW: Si AU MOINS UN agent renvoie NEEDS_REVIEW
└── PASS:         Si TOUS les agents renvoient PASS
```

**Important** : Le CI ne se base PLUS sur le score numerique >= 80, mais sur `OVERALL_STATUS`.

### 8.3 Seuils par Agent

| Agent | PASS | NEEDS_REVIEW | FAIL |
|-------|------|--------------|------|
| Structure | 100% (all checks pass) | - | Any check fails |
| ADR | Domain modifie + ADR present | - | Domain modifie SANS ADR |
| Coherence | >= 80/100 | 60-80 | < 60 |

---

## 9. Format des Rapports JSON

### 9.1 Structure Validation Report

```json
{
  "agent": "structure-validator",
  "checks": {
    "src_domain_exists": boolean,
    "src_application_exists": boolean,
    "src_infrastructure_exists": boolean,
    "docs_adrs_exists": boolean,
    "forbidden_imports_count": number
  },
  "adr_count": number,
  "specs": {
    "found": boolean,
    "location": string
  },
  "status": "PASS" | "FAIL"
}
```

### 9.2 ADR Review Report

```json
{
  "agent": "adr-reviewer",
  "feature_name": string,
  "domain_changes_count": number,
  "adrs_found": number,
  "adrs_in_pr": number,
  "tasks_integration": {
    "adr_task_found": boolean,
    "adr_task_completed": boolean,
    "task_id": string,
    "task_description": string
  },
  "pertinence_check": [
    {
      "change": string,
      "matching_adr": string,
      "pertinence": "HIGH" | "MEDIUM" | "LOW" | "NONE",
      "reason": string
    }
  ],
  "issues": string[],
  "recommendations": string[],
  "status": "PASS" | "FAIL" | "NEEDS_REVIEW"
}
```

### 9.3 Coherence Check Report

```json
{
  "agent": "coherence-checker",
  "feature_name": string,
  "scores": {
    "naming": number,        // 0-25
    "architecture": number,  // 0-25
    "domain_purity": number, // 0-25
    "business_rules": number // 0-25
  },
  "overall_coherence_score": number, // 0-100
  "naming_violations": number,
  "forbidden_imports": number,
  "side_effects": number,
  "drift_detected": [
    {
      "document": string,
      "states": string,
      "code": string,
      "severity": "HIGH" | "MEDIUM" | "LOW",
      "recommendation": string
    }
  ],
  "status": "PASS" | "FAIL" | "NEEDS_REVIEW"
}
```

---

## 10. Commentaires PR User-Friendly

### 10.1 Format du Commentaire

Le commentaire PR inclut :

1. **Banner ASCII** Spec-Kit
2. **Tableau Score Overview** avec métriques
3. **3 sections agents** avec barres de progression
4. **Sections collapsibles** `<details>` pour les détails
5. **Actions requises** si FAIL
6. **Footer** avec liens et références

### 10.2 Exemple de Rendu

```markdown
```
╔═══════════════════════════════════════════════════════════════╗
║   ███████╗██████╗ ███████╗ ██████╗    ██╗  ██╗██╗████████╗   ║
║   ██╔════╝██╔══██╗██╔════╝██╔════╝    ██║ ██╔╝██║╚══██╔══╝   ║
║   ███████╗██████╔╝█████╗  ██║         █████╔╝ ██║   ██║      ║
║   ╚════██║██╔═══╝ ██╔══╝  ██║         ██╔═██╗ ██║   ██║      ║
║   ███████║██║     ███████╗╚██████╗    ██║  ██╗██║   ██║      ║
║   ╚══════╝╚═╝     ╚══════╝ ╚═════╝    ╚═╝  ╚═╝╚═╝   ╚═╝      ║
║               Governance Compliance Pipeline                  ║
╚═══════════════════════════════════════════════════════════════╝
```

## 🛡️ Spec-kit Governance Compliance Report

### ✅ PASSED

| Metric | Value | Status |
|--------|-------|--------|
| **Overall Score** | 95/100 | ✅ |
| **Threshold** | 80/100 | - |
| **Agents Run** | 3/3 | - |

### 🔍 Agent 1: Structure Validator ✅

`████████████████████` 100%

<details>
<summary>View Details</summary>

| Check | Status |
|-------|--------|
| `src/domain/` | ✅ |
| `src/application/` | ✅ |
| `src/infrastructure/` | ✅ |
| `docs/adrs/` | ✅ (5 found) |
| Forbidden imports | 0 violations |

</details>
```

### 10.3 Idempotence

Le commentaire utilise un marker HTML invisible :
```html
<!-- spec-kit-governance-report -->
```

Cela permet de :
- Trouver et mettre à jour le commentaire existant
- Éviter les duplications
- Garder l'historique des exécutions

---

## 11. Configuration et Secrets

### 11.1 Secrets GitHub Requis

| Secret | Description | Où l'obtenir |
|--------|-------------|--------------|
| `ANTHROPIC_API_KEY` | Clé API Anthropic | [console.anthropic.com](https://console.anthropic.com/) |

**Configuration** :
1. Aller dans Settings > Secrets and variables > Actions
2. Cliquer "New repository secret"
3. Nom : `ANTHROPIC_API_KEY`
4. Valeur : Votre clé (commence par `sk-ant-`)

### 11.2 Tokens Automatiques

| Token | Fourni par | Usage |
|-------|------------|-------|
| `GITHUB_TOKEN` | GitHub Actions | API PR comments |

### 11.3 Variables de Configuration

**Dans le workflow** :
```yaml
env:
  COMPLIANCE_THRESHOLD: 80      # Score minimum
  REQUIRE_AI_ANALYSIS: "true"   # Analyse IA obligatoire
```

**Dans les scripts** :
```bash
export REQUIRE_AI_ANALYSIS="true"
export CHANGED_FILES="src/domain/talk.entity.ts"
export BRANCH_NAME="feat/validation-titre"
export FEATURE_NAME="validation-titre"
```

---

## 12. Dépannage et FAQ

### 12.1 Erreurs Communes

#### API Key non configurée

```
❌ ERREUR: ANTHROPIC_API_KEY non configurée
```

**Solution** : Ajouter le secret `ANTHROPIC_API_KEY` dans les settings du repo.

#### Module ES vs CommonJS

```
ReferenceError: require is not defined in ES module scope
```

**Solution** : Le projet utilise `"type": "module"` dans `package.json`. Utiliser `import` au lieu de `require`.

#### Score NEEDS_REVIEW

```
Score: 70/100 | Status: NEEDS_REVIEW
```

**Cause** : Un agent a détecté des problèmes non-bloquants.

**Solution** : Vérifier les détails dans la section collapsible de l'agent concerné.

### 12.2 FAQ

**Q: Comment tester localement ?**
```bash
# Vérification rapide
npm run test:compliance

# Avec Spec-kit CLI
specify check
```

**Q: Comment forcer un re-run de la CI ?**
```bash
# Pousser un commit vide
git commit --allow-empty -m "chore: trigger CI"
git push
```

**Q: Comment ignorer la validation pour un fichier ?**

Les fichiers non-surveillés sont :
- `*.test.ts`
- `*.spec.ts`
- `*.md` (sauf ADRs)
- `package.json`
- Configuration files

**Q: Combien coûte l'analyse IA ?**

Avec Claude Haiku 4.5 :
- Input : $1 / 1M tokens
- Output : $5 / 1M tokens
- **~$0.02 par PR** en moyenne

---

## Références

- [Constitution](.specify/memory/constitution.md)
- [Governance Rules](.spec-kit/governance.md)
- [Glossaire](docs/glossary.md)
- [Clean Architecture - Uncle Bob](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Claude Code CLI](https://docs.anthropic.com/claude/docs/claude-code)
- [GitHub Actions Reusable Workflows](https://docs.github.com/en/actions/using-workflows/reusing-workflows)

---

**Derniere mise a jour** : 2026-03-17
**Maintenu par** : Equipe Devoxx 2026

> **Note** : Ce document fusionne les anciens `ARCHITECTURE-CI.md` et `TECHNICAL-REFERENCE.md` (archives dans `docs/archive/`).

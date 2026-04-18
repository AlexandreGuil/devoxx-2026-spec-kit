# ADR 0004 : Intégration de la Gouvernance dans le Workflow Spec-kit

**Statut** : Accepté  
**Date** : 2026-01-25  
**Décideur(s)** : Équipe Devoxx 2026

## Contexte

Le projet utilisait initialement deux mécanismes de validation séparés :
1. `specify check` (Spec-kit CLI) : Vérification des prérequis (outils installés)
2. Un workflow de validation basique de la structure (depuis supprimé)

Cette séparation créait plusieurs problèmes :
- Les développeurs ne savaient pas quelle validation était exécutée en CI
- La commande `specify check` ne validait pas réellement la conformité documentaire
- Les règles de gouvernance n'étaient pas intégrées dans le workflow `/speckit.tasks`
- Pas de review AI pour la cohérence code ↔ documentation

## Décision

### 1. Centralisation du workflow CI

Création d'un workflow unifié `.github/workflows/spec-kit-ci.yml` qui :
- Valide les 4 règles de gouvernance définies dans `.spec-kit/governance.md`
- Intègre GitHub Copilot (via GitHub Models API) pour la review de cohérence
- Remplace l'ancienne validation basique

### 2. Intégration dans les templates Spec-kit

Création de `.specify/memory/governance-rules.md` comme source de vérité pour les règles, et mise à jour des templates :

| Template | Modification |
|----------|--------------|
| `tasks-template.md` | Ajout de **Phase 0: Governance Compliance** (MANDATORY) |
| `plan-template.md` | Ajout de **Governance Compliance Gate** avec checklist |
| `spec-template.md` | Ajout de **Governance Requirements** (GR-001 à GR-004) |

### 3. Règles de gouvernance standardisées

| ID | Règle | Validation CI |
|----|-------|---------------|
| R1 | Structure obligatoire | Directories exist |
| R2 | Clean Architecture imports | No forbidden imports |
| R3 | ADR obligatoire | `docs/adrs/NNNN-*.md` exists |
| R4 | Cohérence documentation | GitHub Copilot AI review |

### 4. Tâches de gouvernance auto-générées

Le workflow `/speckit.tasks` génère automatiquement :
- TGOV-01 : Création d'ADR pour chaque feature
- TGOV-02 : Vérification du placement Clean Architecture
- TGOV-03 : Vérification des imports interdits
- TGOV-04 : Exécution de `npm run test:compliance`
- TGOV-05 : Validation du contenu ADR

## Conséquences

### Avantages

- ✅ **Workflow unifié** : Une seule source de vérité pour la CI (`spec-kit-ci.yml`)
- ✅ **Gouvernance auto-générée** : `/speckit.tasks` inclut automatiquement les tâches de conformité
- ✅ **Review AI native** : GitHub Copilot intégré sans API externe
- ✅ **Traçabilité complète** : Chaque feature a ses exigences de gouvernance documentées
- ✅ **DevEx améliorée** : Les développeurs savent exactement ce qui sera validé en CI

### Inconvénients

- ⚠️ **Complexité initiale** : Plus de fichiers à maintenir dans `.specify/`
- ⚠️ **Dépendance GitHub Models** : Nécessite le token `GITHUB_TOKEN` avec permission `models: read`
- ⚠️ **Phase 0 obligatoire** : Peut sembler contraignant pour les petites features

## Alternatives Considérées

1. **Garder deux workflows séparés** : Rejeté car confus pour les développeurs
2. **Ne pas intégrer dans les templates Spec-kit** : Rejeté car ne garantit pas l'automatisation
3. **Utiliser OpenAI API externe** : Rejeté car ajoute une dépendance et un secret supplémentaire

## Fichiers Impactés

- `.github/workflows/spec-kit-ci.yml` (nouveau)
- Ancien workflow de validation (supprimé)
- `.specify/memory/governance-rules.md` (nouveau)
- `.specify/templates/tasks-template.md` (modifié)
- `.specify/templates/plan-template.md` (modifié)
- `.specify/templates/spec-template.md` (modifié)

## Références

- Constitution : `.specify/memory/constitution.md` (Principe III)
- Règles de gouvernance : `.spec-kit/governance.md`
- CFP Devoxx 2026 : "Stop à la dette documentaire"

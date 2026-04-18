# ADR 0002 : Utilisation de GitHub Spec-kit pour la Gouvernance

**Date** : 2026-01-19  
**Statut** : Accepté  
**Décideur(s)** : Équipe DevEx

## Contexte

Le **Portail Devoxx 2026** gère les Talks soumis par les Speakers. Des règles métier critiques existent (ex: durées de session strictement limitées à 15, 30 ou 45 minutes). La dette documentaire s'accumule souvent car :

1. Les règles de gouvernance sont documentées mais non appliquées
2. Les revues de code manuelles manquent des violations subtiles
3. Les équipes n'ont pas de feedback immédiat sur la conformité

Nous cherchons un outil qui permette de **transformer la documentation en validation automatique**, notamment pour garantir que les règles métier du domaine Talk sont toujours tracées dans les ADRs.

## Décision

Nous utilisons **GitHub Spec-kit** (`github/spec-kit`) pour :

- Définir des règles de gouvernance dans `.spec-kit/governance.md`
- Valider automatiquement ces règles via la CI/CD
- Fournir un feedback machine-readable sur la conformité

### Implémentation

1. **Fichier de règles** : `.spec-kit/governance.md` définit :

   - Structure obligatoire des dossiers
   - Présence de documentation ADR
   - Contraintes de dépendances entre couches

2. **CI/CD** : `.github/workflows/spec-kit-ci.yml` exécute la validation avec agents IA sur chaque Pull Request

3. **Installation** : Spec-kit s'installe via `uv tool install specify-cli --from git+https://github.com/github/spec-kit.git`

## Conséquences

### Avantages

- ✅ **Gouvernance vivante** : Les règles sont vérifiées à chaque PR
- ✅ **Feedback immédiat** : Les développeurs savent instantanément s'ils respectent les conventions
- ✅ **Documentation exécutable** : `.spec-kit/governance.md` est à la fois doc et validation
- ✅ **Scalabilité** : Même approche pour 10 ou 100 projets
- ✅ **Open Source** : Toolkit maintenu par GitHub, pas de vendor lock-in

### Inconvénients

- ⚠️ **Installation requise** : Nécessite uv et Python 3.11+
- ⚠️ **Courbe d'apprentissage** : Les équipes doivent apprendre le workflow Spec-Driven Development
- ⚠️ **Jeune projet** : Spec-kit est encore en phase expérimentale

### Impact Organisationnel

- Les Platform Engineers maintiennent `.spec-kit/governance.md`
- Les développeurs reçoivent un feedback automatique sans passer par une revue humaine
- Les audits de conformité deviennent automatisés

## Alternatives Considérées

1. **GitHub Copilot Instructions** : Guidage en temps réel mais pas de validation stricte (choisie en complément)
2. **Linters classiques (ESLint, Architecture Lint)** : Limités aux règles syntaxiques
3. **Revues de code manuelles** : Non scalables et incohérentes
4. **Scripts personnalisés** : Maintenance complexe, pas de standard

## Liens

- [GitHub Spec-kit Repository](https://github.com/github/spec-kit)
- [Documentation Spec-kit](https://github.github.io/spec-kit/)

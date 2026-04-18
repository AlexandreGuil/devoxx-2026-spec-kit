# <!--

# SYNC IMPACT REPORT - Constitution v1.0.0

Version Change: Initial creation → v1.0.0

Modifications:

- CRÉATION INITIALE: Établissement de la constitution pour Devoxx 2026 Spec-kit POC
- Principes ajoutés:
  • Principe I - Clean Architecture (3 couches obligatoires)
  • Principe II - Software Craftsmanship (SOLID, TDD, Boy Scout Rule)
  • Principe III - Règle d'Or de la Documentation ADR (CRITIQUE)
  • Principe IV - Ubiquitous Language
  • Principe V - Test-Driven Development (TDD)
  • Principe VI - Code Review Obligatoire

Sections créées:

- Standards d'Ingénierie
- Workflow de Développement
- Gouvernance et Conformité

Templates à vérifier:
✅ plan-template.md - Constitution Check aligné
✅ spec-template.md - Scope aligné avec ADR
✅ tasks-template.md - Phases de test alignées avec TDD
⚠️ Commandes à vérifier pour cohérence future

Déploiement:

- Date de ratification: 2026-01-25 (aujourd'hui)
- Statut: Constitution exécutable par CI/CD
- Impact: MAJEUR - Définit les règles pour tous les futurs développements

================================================================================
-->

# Constitution du Projet Devoxx 2026 Spec-kit POC

**Nature du Document** : Contrat exécutable et non négociable. Cette constitution définit les règles d'ingénierie applicables à tous les développements du projet. Toute violation entraîne un échec de la CI/CD.

---

## Principes Fondamentaux

### Principe I : Clean Architecture (NON-NÉGOCIABLE)

**Déclaration** : Le code source DOIT strictement respecter la Clean Architecture avec trois couches distinctes et isolées.

**Structure Obligatoire** :

```
src/
├── domain/          # Couche Domaine (cœur métier)
├── application/     # Couche Application (cas d'usage)
└── infrastructure/  # Couche Infrastructure (adaptateurs)
```

**Règles de Dépendance** :

- Le **Domain** ne DOIT avoir AUCUNE dépendance vers Application ou Infrastructure
- Le **Domain** contient UNIQUEMENT la logique métier pure (entités, value objects, interfaces de repositories)
- L'**Application** ne DOIT dépendre QUE du Domain (cas d'usage, orchestration)
- L'**Infrastructure** implémente les interfaces du Domain (repositories concrets, CLI, API, bases de données)

**Direction de dépendance unique** :

```
Infrastructure → Application → Domain
      ❌              ❌           ✅ (0 dépendances externes)
```

**Rationale** : La séparation stricte des préoccupations garantit la testabilité, la maintenabilité et l'indépendance vis-à-vis des frameworks. Le Domain est le patrimoine technique : il ne doit jamais être pollué par des détails techniques.

**Validation** : Toute importation violant cette règle DOIT être rejetée en code review ET par la CI.

---

### Principe II : Software Craftsmanship (CRAFT)

**Déclaration** : Le code est un artefact d'artisanat exigeant excellence, lisibilité et maintenabilité.

**Pratiques Obligatoires** :

- **Principes SOLID** : Chaque classe/fonction respecte Single Responsibility, Open/Closed, Liskov Substitution, Interface Segregation, Dependency Inversion
- **Boy Scout Rule** : Laisser le code plus propre qu'on ne l'a trouvé à chaque commit
- **Lisibilité avant concision** : Le code est écrit pour être lu par des humains, pas pour impressionner
- **Refactoring continu** : La dette technique est remboursée immédiatement, pas différée
- **Nommage explicite** : Variables, fonctions et classes portent des noms métier compréhensibles sans commentaire

**Anti-patterns Interdits** :

- God Objects (classes > 300 lignes)
- Fonctions > 50 lignes sans justification documentée
- Magic numbers (constantes non nommées)
- Commentaires expliquant du "comment" au lieu du "pourquoi"

**Rationale** : Le Software Craftsmanship n'est pas un luxe mais une nécessité économique. Le coût de maintenance représente 80% du cycle de vie logiciel. Un code bien écrit réduit la charge cognitive et accélère le Time-To-Market.

**Validation** : Code review DOIT refuser tout code violant ces principes. Les outils de linting (ESLint, Prettier) sont des garde-fous minimum, pas des objectifs.

---

### Principe III : Règle d'Or de la Documentation (CRITIQUE)

**Déclaration (à respecter mot pour mot)** :

> **Toute modification de logique métier dans src/application ou src/domain DOIT être accompagnée d'un nouveau fichier .md dans docs/adrs/. L'absence d'ADR lors d'une évolution structurante est considérée comme une rupture de conformité majeure.**

**Qu'est-ce qu'une "évolution structurante" ?**

- Ajout/modification d'une entité métier dans `src/domain/`
- Création/modification d'un cas d'usage dans `src/application/`
- Changement d'interface de repository
- Modification de règle de gestion métier
- Introduction d'une nouvelle dépendance externe impactant le Domain

**Format ADR Obligatoire** :

```markdown
# ADR-NNNN : Titre de la Décision

**Statut** : [Proposé | Accepté | Refusé | Déprécié]
**Date** : YYYY-MM-DD
**Contexte** : Pourquoi cette décision est nécessaire ?
**Décision** : Quelle solution a été retenue ?
**Conséquences** : Impacts positifs et négatifs de cette décision
```

**Numérotation** : Format `NNNN-titre-de-la-decision.md` (ex: `0003-modification-durees-sessions.md`)

**Rationale** : Les ADRs sont le contrat de confiance entre développeurs humains et futurs agents IA. Ils capturent le "pourquoi" des décisions architecturales, seul élément que le code ne peut transmettre. Sans ADR, le projet accumule de la dette documentaire irrémédiable.

**Validation** : La CI DOIT vérifier qu'un ADR existe pour toute modification dans `src/domain/` ou `src/application/`. Spec-kit analyse cette cohérence automatiquement.

---

### Principe IV : Ubiquitous Language

**Déclaration** : Le code DOIT parler la langue métier, pas la langue technique.

**Règles de Nommage** :

- Les **entités** utilisent les termes exacts du domaine métier (ex: `Talk`, `Speaker`, `Duration`, `Conference`)
- Les **cas d'usage** décrivent des actions métier (ex: `SubmitTalkUseCase`, `ListTalksUseCase`)
- Les **value objects** portent des noms métier sans suffixe technique (ex: `Duration` au lieu de `IntegerWrapper`)
- INTERDIT : Noms techniques génériques (`Manager`, `Helper`, `Util`, `Data`, `Info`)

**Langage Partagé** :

- Les termes métier DOIVENT être documentés dans un glossaire (`docs/glossary.md`)
- Les termes techniques (repository, use case, entity) restent dans leur couche respective mais ne polluent pas le vocabulaire métier

**Rationale** : L'Ubiquitous Language réduit la friction cognitive entre experts métier et développeurs. Un code qui parle le langage métier est auto-documenté et réduit les risques d'incompréhension.

**Validation** : Code review DOIT rejeter tout nommage technique générique ou ambigu. Les termes métier doivent être approuvés par l'équipe avant usage.

---

### Principe V : Test-Driven Development (TDD)

**Déclaration** : Les tests ne sont pas une option, ils précèdent l'implémentation.

**Cycle TDD Obligatoire** :

1. **Red** : Écrire un test qui échoue
2. **Green** : Écrire le code minimum pour faire passer le test
3. **Refactor** : Améliorer le code sans casser les tests

**Couverture Obligatoire** :

- **Domain** : 100% de couverture (logique métier critique)
- **Application** : 100% de couverture (cas d'usage)
- **Infrastructure** : Tests d'intégration obligatoires pour repositories et adaptateurs

**Pyramide de Tests** :

```
           /\
          /  \  E2E (quelques-uns)
         /____\
        /      \  Intégration (modérés)
       /________\
      /          \  Unitaires (nombreux)
     /____________\
```

**Types de Tests Obligatoires** :

- **Tests unitaires** : Chaque fonction métier testée isolément
- **Tests d'intégration** : Vérification des contrats entre couches
- **Tests de contrat** : Validation des interfaces de repositories

**Rationale** : Le TDD n'est pas une perte de temps mais un investissement. Il réduit drastiquement le coût de debugging, augmente la confiance et facilite le refactoring. Un code non testé est un code legacy dès sa création.

**Validation** : Aucun code ne peut être mergé sans tests. La CI DOIT vérifier la couverture et échouer si < seuils définis.

---

### Principe VI : Code Review Obligatoire

**Déclaration** : Aucun code ne rejoint `main` sans validation par les pairs.

**Règles de Review** :

- **Minimum 1 approbation** requise avant merge
- **Checklist de review** :
  - [ ] Respect de la Clean Architecture
  - [ ] ADR créé si modification métier
  - [ ] Tests présents et pertinents
  - [ ] Nommage respectant l'Ubiquitous Language
  - [ ] Principes SOLID respectés
  - [ ] Pas de dette technique introduite
- **Délai maximum** : 24h pour première review (respect du Time-To-Market)

**Ton de la Review** :

- Bienveillant mais ferme sur les principes non négociables
- Suggestions constructives avec références (ex: "Voir ADR-0001 pour la séparation Domain/Infrastructure")
- Approuver uniquement si confiance totale dans la qualité

**Rationale** : La code review est un acte de partage de connaissance, pas de contrôle. Elle diffuse les bonnes pratiques et évite l'accumulation de dette technique silencieuse.

**Validation** : GitHub branch protection rules DOIVENT bloquer tout merge direct sur `main`.

---

## Standards d'Ingénierie

### Stack Technique

**Langage** : TypeScript (strict mode activé)
**Runtime** : Node.js >= 20.0.0
**Gestionnaire de paquets** : npm ou yarn
**Linting** : ESLint + Prettier (configuration stricte)
**Tests** : Jest ou Vitest (couverture > 80%)

**Justification** : TypeScript strict garantit la sûreté de type à la compilation. Node.js LTS assure la stabilité. ESLint/Prettier réduisent la friction sur le style.

### Conventions de Code

**Formatage** : Prettier avec configuration `.prettierrc`
**Linting** : ESLint avec règles strictes dans `.eslintrc.cjs`
**Commits** : Format Conventional Commits (`feat:`, `fix:`, `docs:`, `refactor:`, etc.)
**Branches** : Format `<type>/<description>` (ex: `feat/adr-validation`, `fix/test-coverage`)

### Gestion des Erreurs

**Règles** :

- Toujours typer les erreurs (pas de `any`)
- Les erreurs métier restent dans le Domain (ex: `InvalidProjectNameError`)
- Les erreurs techniques restent dans l'Infrastructure
- Jamais de `try/catch` silencieux
- Logging structuré obligatoire pour toute erreur

---

## Workflow de Développement

### Cycle de Développement

1. **Créer une branche** depuis `main` (format : `<type>/<description>`)
2. **Écrire les tests** (TDD Red)
3. **Implémenter le code** (TDD Green)
4. **Refactorer** (TDD Refactor)
5. **Créer un ADR** si modification métier
6. **Ouvrir une Pull Request**
7. **Passer la CI** (tests, linting, compliance Spec-kit)
8. **Code review** (minimum 1 approbation)
9. **Merge sur `main`**

### Intégration Continue (CI/CD)

**GitHub Actions** : Workflow `.github/workflows/spec-kit-ci.yml`

**Gates Obligatoires** :

- ✅ Rule 1 : Structure Clean Architecture (3 dossiers)
- ✅ Rule 2 : Imports unidirectionnels (domain pur)
- ✅ Rule 3 : ADR obligatoire (`docs/adrs/NNNN-*.md`)
- ✅ Rule 4 : Cohérence documentation (GitHub Copilot AI review)
- ✅ Tests unitaires passent
- ✅ Couverture de tests > 80%
- ✅ Linting réussi (ESLint + Prettier)
- ✅ Build TypeScript réussi

**Échec de CI = Blocage du merge** : Aucune exception tolérée.

### Gestion des Dépendances

**Règles** :

- Toute nouvelle dépendance DOIT être justifiée dans un ADR
- Privilégier les bibliothèques maintenues et populaires
- Éviter les dépendances avec CVE connus
- Audit de sécurité régulier (`npm audit`)

---

## Gouvernance et Conformité

### Autorité de la Constitution

**Statut Juridique** : Cette constitution est un contrat exécutable par la CI/CD. Elle supersède toute pratique informelle ou tribale.

**Hiérarchie des Normes** :

1. **Constitution** (ce document) - loi suprême
2. **ADRs** - décisions architecturales spécifiques
3. **Conventions d'équipe** - compléments non contradictoires
4. **Préférences individuelles** - libres tant que non en conflit

### Amendements

**Processus de Modification** :

1. Proposer un amendement via une Pull Request modifiant ce fichier
2. Créer un ADR justifiant la modification (ex: `ADR-NNNN-amendement-constitution-vX.Y.Z.md`)
3. Discussion en équipe (minimum 3 jours de review)
4. Vote à la majorité qualifiée (2/3 de l'équipe)
5. Mise à jour de la version (voir ci-dessous)
6. Synchronisation des templates et documentation dépendante

**Versioning de la Constitution** :

- **MAJOR** : Changement incompatible (suppression de principe, redéfinition majeure)
- **MINOR** : Ajout de principe ou section (extension)
- **PATCH** : Clarification, correction, amélioration de formulation

### Revue de Conformité

**Fréquence** : Trimestrielle

**Audit** :

- Vérification du respect des principes sur un échantillon de PRs
- Analyse de la dette technique accumulée
- Revue de la pertinence des ADRs existants
- Identification des dérives architecturales

**Rôle de Spec-kit** : Machine-Readable Governance automatise la conformité en continu. L'audit trimestriel vérifie la qualité qualitative (lisibilité, pertinence des ADRs, etc.).

### Mécanisme d'Exécution

**GitHub Spec-kit** : Outil officiel de validation

- Analyse automatique de la cohérence code ↔ documentation
- Vérification de la présence d'ADRs pour modifications métier
- Validation de la structure Clean Architecture
- Review AI via GitHub Copilot (GitHub Models API)
- Exécution en CI via workflow `.github/workflows/spec-kit-ci.yml`

**Commande Locale** :

```bash
npm run test:compliance  # Validation locale complète
specify check            # Validation Spec-kit CLI
```

**CI/CD Badge** : Le README DOIT afficher le statut de conformité Spec-kit.

### Sanctions

**Violations Mineures** (exemple : nommage non optimal)

- Demande de correction en code review
- Pas de blocage immédiat mais attention renforcée

**Violations Majeures** (exemple : absence d'ADR, violation Clean Architecture)

- **Échec de CI** : Merge impossible
- Revue obligatoire par un senior
- Documentation de l'incident pour éviter récidive

**Violations Répétées** :

- Session de formation individuelle
- Pair programming obligatoire sur prochaines tâches

**Rationale** : La fermeté sur les principes non négociables est une marque de respect envers le patrimoine technique et l'équipe. Ce n'est pas punitif mais protecteur.

---

## Références et Ressources

### Documentation Projet

- `README.md` : Présentation générale et installation
- `CONTRIBUTING.md` : Guide de contribution
- `docs/adrs/` : Architecture Decision Records
- `docs/glossary.md` : Glossaire métier (Ubiquitous Language)

### Standards Externes

- [Clean Architecture - Robert C. Martin](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Software Craftsmanship Manifesto](http://manifesto.softwarecraftsmanship.org/)
- [ADR GitHub Template](https://github.com/joelparkerhenderson/architecture-decision-record)
- [Ubiquitous Language - Domain-Driven Design](https://martinfowler.com/bliki/UbiquitousLanguage.html)

### Outils Recommandés

- **Spec-kit** : Validation automatique de la gouvernance
- **ESLint + Prettier** : Qualité de code automatisée
- **Husky + lint-staged** : Hooks Git pour vérifications pré-commit
- **Jest/Vitest** : Framework de tests
- **TypeScript strict mode** : Sûreté de type maximale

---

**Version** : 1.0.0 | **Ratifié** : 2026-01-25 | **Dernière Modification** : 2026-01-25

**Signataires** : Équipe Devoxx 2026 Spec-kit POC

**Engagement** : Nous, développeurs de ce projet, nous engageons à respecter cette constitution comme un contrat de confiance envers nos pairs, nos utilisateurs et les futurs contributeurs. Cette rigueur n'est pas un frein mais le moteur de notre excellence collective.

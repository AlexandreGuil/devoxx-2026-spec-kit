# Glossaire Métier - Ubiquitous Language

> **Objectif** : Ce glossaire définit les termes métier du domaine utilisés dans le code source. Il établit le vocabulaire partagé entre experts métier et développeurs (Ubiquitous Language du Domain-Driven Design).

**Mise à jour** : Ce document DOIT être enrichi à chaque introduction d'un nouveau terme métier dans `src/domain/` ou `src/application/`.

---

## Contexte Métier : Portail Devoxx 2026

Ce projet modélise le système de soumission et gestion des **Talks** pour la conférence **Devoxx**. Les entités et cas d'usage reflètent le vocabulaire officiel de la conférence.

---

## Entités Métier

### Talk (Session de Conférence)

**Définition** : Représente une session soumise par un Speaker pour la conférence Devoxx.

**Attributs métier** :

- `id` : Identifiant unique du talk (généré ou assigné)
- `title` : Titre de la session (affiché dans le programme)
- `abstract` : Résumé du contenu de la session
- `speakerName` : Nom complet du présentateur
- `duration` : Durée de la session (voir règle métier ci-dessous)

**Règles métier (CRITIQUES)** :

- Un talk DOIT avoir un titre non vide
- Un talk DOIT être associé à un speaker
- La durée DOIT être strictement de **15**, **30**, ou **45** minutes (voir Duration)

**Localisation code** : `src/domain/talk.entity.ts`

---

### Speaker (Présentateur)

**Définition** : Personne physique qui présente un Talk lors de la conférence Devoxx.

**Représentation actuelle** : Attribut `speakerName` (string) dans l'entité `Talk`.

**Évolution future** : Pourrait devenir une entité à part entière avec :

- `id` : Identifiant unique
- `name` : Nom complet
- `bio` : Biographie
- `company` : Entreprise ou affiliation
- `talks` : Liste des talks soumis

**Localisation code** : Intégré dans `src/domain/talk.entity.ts` (attribut `speakerName`)

---

### Duration (Durée de Session)

**Définition** : Durée d'un Talk, contrainte aux formats officiels Devoxx.

**Valeurs autorisées** :
| Valeur | Format Devoxx | Description |
|--------|---------------|-------------|
| **15** | Quickie | Session courte, idéale pour une idée percutante |
| **30** | Tools-in-Action | Démonstration pratique d'un outil ou technique |
| **45** | Conference | Session approfondie sur un sujet technique |
| **90** | Deep Dive | Session longue pour expertise technique avancée (voir [ADR-0003](../docs/adrs/0003-adoption-format-deep-dive.md)) |

**Règle métier critique** :

> Toute durée différente de 15, 30, 45 ou 90 minutes DOIT lever une erreur `InvalidDurationError`.

**Implémentation** : Type TypeScript strict `Duration = 15 | 30 | 45 | 90`

**Localisation code** : `src/domain/talk.entity.ts` (type `Duration`)

---

### Conference (Conférence)

**Définition** : Événement Devoxx regroupant plusieurs Talks organisés sur plusieurs jours.

**Contexte** : Ce POC se concentre sur la gestion des Talks. L'entité Conference pourrait être ajoutée pour modéliser :

- `id` : Identifiant (ex: `devoxx-2026`)
- `name` : Nom de l'édition
- `location` : Lieu (Paris, Anvers, etc.)
- `dates` : Période de l'événement
- `talks` : Liste des talks acceptés

**Localisation code** : À créer dans `src/domain/conference.entity.ts` (futur)

---

## Erreurs Métier

### InvalidDurationError

**Définition** : Erreur levée lorsqu'une durée invalide est fournie pour un Talk.

**Message** : `"Invalid duration: {value}. Duration must be 15 (Quickie), 30 (Tools-in-Action), or 45 (Conference) minutes."`

**Déclencheur** : Construction d'un `Talk` ou appel à `changeDuration()` avec une valeur ≠ 15, 30, 45.

**Localisation code** : `src/domain/talk.entity.ts` (classe `InvalidDurationError`)

---

## Cas d'Usage (Use Cases)

### Submit Talk (Soumettre un Talk)

**Définition** : Cas d'usage permettant à un Speaker de soumettre une nouvelle session pour la conférence.

**Responsabilités** :

- Valider les données d'entrée (via le constructeur de `Talk`)
- Créer l'entité `Talk` avec les règles métier
- Persister le talk via le repository

**Input** : `{ id, title, abstract, speakerName, duration }`

**Output** : `Talk` (entité créée)

**Localisation code** : `src/application/submit-talk.usecase.ts`

---

### List Talks (Lister les Talks)

**Définition** : Cas d'usage qui récupère tous les talks soumis pour la conférence.

**Responsabilités** :

- Interroger le repository de talks
- Retourner la liste complète

**Localisation code** : `src/application/list-talks.usecase.ts`

---

## Repositories (Ports)

### Talk Repository (Repository de Talks)

**Définition** : Interface abstraite (port) définissant les opérations de persistance pour les Talks.

**Opérations** :

- `findAll()` : Récupérer tous les talks
- `findById(id)` : Récupérer un talk par son identifiant
- `save(talk)` : Persister un nouveau talk ou mettre à jour un existant

**Implémentations** :

- `InMemoryTalkRepository` : Implémentation en mémoire (démonstration)
- `DatabaseTalkRepository` : Implémentation base de données (futur)

**Localisation code** :

- Interface : `src/domain/talk.repository.ts`
- Implémentation : `src/infrastructure/in-memory-talk.repository.ts`

---

## Termes Techniques (Infrastructure)

Ces termes sont techniques et ne doivent PAS apparaître dans le Domain ou l'Application :

- **CLI** (Command Line Interface) : Point d'entrée utilisateur dans `src/infrastructure/cli.ts`
- **Adapter** : Implémentation concrète d'un port (ex: repository, API externe)
- **DTO** (Data Transfer Object) : Objet de transfert de données entre couches (si utilisé)

---

## Ajout de Nouveaux Termes

**Processus** :

1. Terme métier introduit dans `src/domain/` ou `src/application/`
2. Ajouter définition dans ce glossaire (section appropriée)
3. Préciser localisation code exacte
4. Documenter règles métier associées si pertinent
5. Commit avec message : `docs(glossary): add [terme métier]`

**Anti-pattern** : Termes techniques génériques (Manager, Helper, Util) ne doivent JAMAIS apparaître dans ce glossaire.

---

## Références

- Constitution du projet : `.specify/memory/constitution.md` (Principe IV - Ubiquitous Language)
- [Ubiquitous Language - Martin Fowler](https://martinfowler.com/bliki/UbiquitousLanguage.html)
- [Domain-Driven Design - Eric Evans](https://www.domainlanguage.com/)
- [Devoxx Official Formats](https://devoxx.fr/)

---

**Dernière mise à jour** : 2026-01-25  
**Mainteneur** : Équipe Portail Devoxx 2026

# ADR 0001 : Adoption de la Clean Architecture

**Date** : 2026-01-19  
**Statut** : Accepté  
**Décideur(s)** : Équipe Platform Engineering

## Contexte

Le **Portail Devoxx 2026** est un système de gestion des Talks pour la conférence. Ce POC vise à démontrer comment GitHub Spec-kit peut automatiser la gouvernance architecturale. Nous devons choisir un style architectural qui :

- Soit facilement compréhensible lors d'une présentation Devoxx (Tools-in-Action)
- Permette de démontrer la séparation des responsabilités (ex: logique de validation des durées de Talk)
- Facilite la validation automatique via des règles lisibles par machine

## Décision

Nous adoptons la **Clean Architecture** (aussi appelée Architecture Hexagonale ou Ports & Adapters) avec trois couches principales :

### Structure

```
src/
├── domain/         # Logique métier pure (Talk, Duration, repositories)
│   ├── talk.entity.ts
│   └── talk.repository.ts
├── application/    # Cas d'usage (SubmitTalkUseCase, ListTalksUseCase)
│   ├── submit-talk.usecase.ts
│   └── list-talks.usecase.ts
└── infrastructure/ # Adaptateurs (InMemoryTalkRepository, CLI)
    ├── in-memory-talk.repository.ts
    └── cli.ts
```

### Règles de Dépendance

- **Domain** : Aucune dépendance externe. Code métier pur.
- **Application** : Dépend uniquement du domain. Contient les cas d'usage.
- **Infrastructure** : Dépend du domain et de l'application. Implémente les adaptateurs.

Le flux de dépendance est strictement **unidirectionnel** :  
`Infrastructure → Application → Domain`

## Conséquences

### Avantages

- ✅ **Testabilité** : Le domain est testable sans dépendances externes
- ✅ **Maintenabilité** : Séparation claire des responsabilités
- ✅ **Évolutivité** : Facile d'ajouter de nouveaux adaptateurs (REST API, GraphQL, etc.)
- ✅ **Gouvernance** : Les règles de dépendance sont vérifiables automatiquement par Spec-kit

### Inconvénients

- ⚠️ **Complexité initiale** : Plus de fichiers que pour un POC monolithique
- ⚠️ **Boilerplate** : Nécessite des interfaces et des implémentations séparées

### Impact sur la Gouvernance

Cette architecture facilite la définition de règles dans `.spec-kit/governance.md` :

- Vérification de l'existence des trois dossiers
- Validation des imports inter-couches
- Traçabilité des décisions via ce système d'ADR

## Alternatives Considérées

1. **Architecture Monolithique** : Rejetée car trop simple pour démontrer la valeur de Spec-kit
2. **Microservices** : Rejetée car trop complexe pour un POC de 30 minutes

## Liens

- [Clean Architecture par Uncle Bob](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Hexagonal Architecture](https://alistair.cockburn.us/hexagonal-architecture/)

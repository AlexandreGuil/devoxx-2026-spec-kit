# ADR 0003 : Adoption du format Deep Dive (90 min)

**Statut** : Accepté
**Date** : 2026-01-25
**Auteur(s)** : Equipe Devoxx 2026

## Contexte

Le Portail Devoxx 2026 limitait initialement les Talks aux formats classiques :
- **Quickie** : 15 minutes
- **Conference** : 30 minutes
- **Tools-in-Action** : 45 minutes

Cependant, certains sujets techniques avancés (architecture distribuee, securite, performance) necessitent un temps d'exploration plus long. Les speakers experts demandaient un format permettant :
- Une exploration approfondie d'un sujet complexe
- Des demonstrations live plus detaillees
- Un temps de questions-reponses substantiel

## Decision

Nous ajoutons le format **Deep Dive (90 minutes)** a la liste des durees valides dans l'entite Talk.

### Implementation

1. **Modification du type Duration** dans `src/domain/talk.entity.ts` :
   ```typescript
   export type Duration = 15 | 30 | 45 | 90;
   ```

2. **Mise a jour de la validation** : La methode `validateDuration()` accepte maintenant 90 comme valeur valide.

3. **Mise a jour de la CLI** : Les demonstrations incluent des exemples avec le format Deep Dive.

4. **Documentation** : Le glossaire (`docs/glossary.md`) documente le nouveau format.

## Consequences

### Avantages

- Les speakers peuvent proposer des contenus approfondis
- Meilleure couverture des sujets complexes (architecture, securite, etc.)
- Differenciation par rapport aux conferences classiques
- Alignement avec les pratiques des grandes conferences tech (QCon, Strange Loop)

### Inconvenients

- Necessite des creneaux horaires plus longs dans le programme
- Risque de fatigue des participants sur des sessions longues
- Plus difficile a remplir pour les speakers moins experimentes

### Impact sur le code

| Fichier | Modification |
|---------|--------------|
| `src/domain/talk.entity.ts` | Ajout de `90` au type `Duration` |
| `src/infrastructure/cli.ts` | Exemples avec Deep Dive |
| `docs/glossary.md` | Definition du format Deep Dive |

## Alternatives Considerees

1. **Format Workshop (120+ min)** : Rejete car trop long pour une conference
2. **Sessions en deux parties** : Rejete car complexe a organiser
3. **Garder uniquement 15/30/45** : Rejete car ne repond pas au besoin d'expertise

## References

- Formats Devoxx France : https://www.devoxx.fr/cfp-formats/
- Talk.entity.ts : `src/domain/talk.entity.ts`
- Glossaire : `docs/glossary.md`

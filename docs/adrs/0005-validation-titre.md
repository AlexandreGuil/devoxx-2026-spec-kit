# ADR 0005 : Validation de la longueur du titre

**Statut** : Accepte
**Date** : 2026-01-30
**Auteur(s)** : Equipe Devoxx

## Contexte

Les titres de talks peuvent etre tres longs, ce qui pose des problemes:

- Affichage tronque dans l'interface mobile
- Difficulte de lecture dans le programme papier
- SEO degradee pour les longues URLs

Les speakers ont tendance a vouloir inclure trop d'informations dans le titre,
ce qui nuit a la lisibilite et a l'impact du message.

## Decision

Limiter le titre des talks a **100 caracteres maximum**.

Cette limite est:

- Suffisante pour exprimer le sujet clairement
- Compatible avec les contraintes d'affichage (mobile, programme papier)
- Alignee avec les pratiques des autres conferences tech (QCon, Devoxx BE)

### Implementation

Ajout d'une validation dans l'entite `Talk` (`src/domain/talk.entity.ts`):

- Nouvelle erreur domaine: `InvalidTitleLengthError`
- Validation dans le constructeur avec limite de 100 caracteres
- Message d'erreur explicite indiquant la longueur actuelle et la limite

## Consequences

### Avantages

- Meilleure UX sur tous les supports (mobile, web, print)
- Titres plus percutants et memorables
- Simplification des templates d'affichage
- Coherence avec l'Ubiquitous Language du domaine

### Inconvenients

- Les speakers devront parfois reformuler leurs titres
- Migration necessaire pour les talks existants depassant 100 caracteres

### Impact sur le code

| Fichier                     | Modification                                 |
| --------------------------- | -------------------------------------------- |
| `src/domain/talk.entity.ts` | Ajout `InvalidTitleLengthError` + validation |

## Alternatives Considerees

1. **Limite de 80 caracteres** : Trop restrictif pour certains sujets techniques
2. **Limite de 150 caracteres** : Ne resout pas les problemes d'affichage mobile
3. **Pas de limite** : Status quo, problemes persistent

## References

- [Twitter/X limite: 280 caracteres](https://help.twitter.com/en/using-twitter/how-to-tweet)
- [Recommandations SEO titres: 50-60 caracteres](https://moz.com/learn/seo/title-tag)
- Constitution Spec-Kit: Principe III (documentation obligatoire)

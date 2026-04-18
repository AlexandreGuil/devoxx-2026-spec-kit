# ADR-0006 : Validation de la biographie speaker

## Statut
Accepte

## Contexte
Les speakers soumettent des talks avec une biographie. Sans contrainte, les bios sont soit vides soit excessivement longues, ce qui degrade l'affichage dans le programme de la conference.

## Decision
Ajouter une validation de la longueur de la biographie dans le domaine Talk :
- Minimum : 50 caracteres (apres trimming)
- Maximum : 500 caracteres (apres trimming)
- Erreur : InvalidBioLengthError avec la longueur reelle et les contraintes

### Pattern
Identique a InvalidTitleLengthError. Le bio est valide dans le constructeur Talk (fail-fast).

### Impact
| Fichier | Modification |
|---------|-------------|
| src/domain/talk.entity.ts | Ajout InvalidBioLengthError + validation bio |
| src/application/submit-talk.usecase.ts | Ajout parametre bio dans SubmitTalkInput |
| src/infrastructure/in-memory-talk.repository.ts | Ajout bio aux demo talks |

## Consequences
### Avantages
- Bios coherentes et informatives dans le programme
- Fail-fast : Talk invalide non-constructible
- Pattern coherent avec les validations existantes (titre, duree)

### Inconvenients
- Breaking change : tous les call sites doivent passer un bio
- Les speakers existants avec des bios < 50 chars devront les allonger

## Alternatives considerees
1. Limite 80 chars min - trop restrictif, exclut les juniors
2. Limite 150 chars max - trop court pour les seniors avec beaucoup d'experience
3. Pas de limite - statu quo, problemes d'affichage persistent

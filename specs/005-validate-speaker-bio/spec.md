# Feature Specification: Validation biographie speaker

**Feature Branch**: `001-validate-speaker-bio`
**Created**: 2026-04-17
**Status**: Done
**Spec**: 005-validate-speaker-bio

## User Stories

### US1 - Le systeme rejette un talk dont la bio est trop courte (Priority: P1)

**Given** un speaker soumet un talk avec une bio de moins de 50 caracteres (apres trimming),
**When** le Talk est construit,
**Then** le systeme leve `InvalidBioLengthError` avec le message indiquant la longueur reelle et le minimum requis.

### US2 - Le systeme rejette un talk dont la bio est trop longue (Priority: P1)

**Given** un speaker soumet un talk avec une bio de plus de 500 caracteres (apres trimming),
**When** le Talk est construit,
**Then** le systeme leve `InvalidBioLengthError` avec le message indiquant la longueur reelle et le maximum autorise.

### US3 - Le systeme accepte une bio valide (Priority: P1)

**Given** un speaker soumet un talk avec une bio entre 50 et 500 caracteres,
**When** le Talk est construit,
**Then** le Talk est cree avec succes et `talk.bio` contient la valeur soumise.

## Acceptance Criteria

1. Bio < 50 chars (apres trim) -> `InvalidBioLengthError`
2. Bio > 500 chars (apres trim) -> `InvalidBioLengthError`
3. Bio de 50 chars exactement -> acceptee
4. Bio de 500 chars exactement -> acceptee
5. Bio composee uniquement d'espaces -> rejetee (trim -> 0 chars)
6. Message d'erreur inclut la longueur reelle et les bornes min/max

## Governance Requirements

- [x] GR-001 : Logic domaine dans `src/domain/`
- [x] GR-002 : Pas d'imports interdits
- [x] GR-003 : ADR-0006 cree dans `docs/adrs/`

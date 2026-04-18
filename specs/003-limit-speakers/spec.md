# Feature Specification: Limit Speakers per Talk

**Feature Branch**: `003-limit-speakers`
**Created**: 2026-04-17
**Status**: Draft

## Description

Limiter le nombre de speakers par talk entre 1 et 3 (inclus).

## Contexte

- Le format Devoxx autorise au maximum 3 co-speakers par session
- Un talk sans speaker n'a pas de sens
- Migration du champ `speakerName: string` vers `speakers: string[]`

## User Stories

1. **[P1]** Le systeme accepte un talk avec 1, 2 ou 3 speakers
2. **[P1]** Le systeme rejette un talk avec 0 speakers (InvalidSpeakerCountError)
3. **[P1]** Le systeme rejette un talk avec plus de 3 speakers (InvalidSpeakerCountError)

## Acceptance Criteria

- `InvalidSpeakerCountError` est levee si `speakers.length === 0` ou `speakers.length > 3`
- Le message d'erreur indique le nombre reel de speakers et la contrainte 1-3
- Le champ `speakerName` est remplace par `speakers: string[]` dans toute la codebase

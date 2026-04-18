# Implementation Plan: Limit Speakers per Talk

**Branch**: `003-limit-speakers` | **Date**: 2026-04-17 | **Spec**: [spec.md](./spec.md)

## Summary

Ajouter une validation du nombre de speakers (1-3) dans l'entite Talk du domaine. Migration du champ scalaire `speakerName: string` vers un tableau `speakers: string[]`.

## Technical Context

- **Language/Version**: TypeScript 5.3.3 strict mode
- **Testing**: Vitest
- **Architecture**: Clean Architecture (domain/application/infrastructure)

## Changes

1. `src/domain/talk.entity.ts` — Ajout `InvalidSpeakerCountError`, remplacement `speakerName` par `speakers: string[]`, validation 1-3
2. `src/application/submit-talk.usecase.ts` — Mise a jour `SubmitTalkInput` et appel constructeur
3. `src/infrastructure/in-memory-talk.repository.ts` — Migration demo data vers arrays
4. `src/infrastructure/cli.ts` — Adaptation affichage `speakers.join(', ')`
5. `src/domain/talk.entity.spec.ts` — Tests unitaires speaker count validation

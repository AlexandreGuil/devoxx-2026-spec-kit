# Implementation Plan: Validation biographie speaker

**Branch**: `001-validate-speaker-bio` | **Date**: 2026-04-17 | **Spec**: [spec.md](./spec.md)

## Summary

Ajouter une validation de la biographie speaker (50-500 caracteres apres trimming) dans l'entite Talk du domaine. Pattern identique a la validation du titre (InvalidTitleLengthError).

## Technical Context

- **Language**: TypeScript 5.3.3 strict mode
- **Testing**: Vitest
- **Architecture**: Clean Architecture (domain/application/infrastructure)

## Constitution Check

| Principe | Statut |
|----------|--------|
| Clean Architecture | PASS - validation dans `src/domain/talk.entity.ts` |
| ADR Required | PASS - ADR-0006 cree |
| Ubiquitous Language | PASS - `InvalidBioLengthError` utilise le vocabulaire domaine |

## Files Modified

| Fichier | Action |
|---------|--------|
| `src/domain/talk.entity.ts` | Ajout `InvalidBioLengthError` + parametre `bio` + validation |
| `src/application/submit-talk.usecase.ts` | Ajout `bio` dans `SubmitTalkInput` |
| `src/infrastructure/in-memory-talk.repository.ts` | Ajout bios aux demo talks |
| `src/infrastructure/cli.ts` | Ajout bio dans les appels submitTalk |
| `src/domain/talk.entity.spec.ts` | Tests unitaires bio validation |
| `docs/adrs/0006-validation-biographie-speaker.md` | ADR documentant la decision |

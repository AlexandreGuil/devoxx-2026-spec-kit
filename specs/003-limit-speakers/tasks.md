# Tasks: Limit Speakers per Talk

**Input**: Design documents from `/specs/003-limit-speakers/`

## Phase 1: Domain

- [x] TASK-1 [P1] Ajouter `InvalidSpeakerCountError` dans `src/domain/talk.entity.ts`
- [x] TASK-2 [P1] Remplacer `speakerName: string` par `speakers: string[]` dans `Talk`
- [x] TASK-3 [P1] Ajouter validation `speakers.length >= 1 && speakers.length <= 3`
- [x] TASK-4 [P1] Mettre a jour `changeDuration()` pour passer `this.speakers`

## Phase 2: Application

- [x] TASK-5 [P1] Mettre a jour `SubmitTalkInput.speakerName` -> `speakers: string[]`
- [x] TASK-6 [P1] Mettre a jour l'appel `new Talk(...)` dans `SubmitTalkUseCase`

## Phase 3: Infrastructure

- [x] TASK-7 [P1] Migrer les demo talks vers `speakers: ['Name']` arrays
- [x] TASK-8 [P1] Adapter `cli.ts` pour afficher `speakers.join(', ')`

## Phase 4: Tests

- [x] TASK-9 [P1] Test: 1 speaker — valide
- [x] TASK-10 [P1] Test: 3 speakers — valide
- [x] TASK-11 [P1] Test: 0 speakers — throws `InvalidSpeakerCountError`
- [x] TASK-12 [P1] Test: 4 speakers — throws `InvalidSpeakerCountError`

## Phase 5: Governance (INTENTIONALLY SKIPPED)

- [ ] TASK-13 [GOV] Creer ADR dans `docs/adrs/` — **NON FAIT** (scenario demo PR #17)

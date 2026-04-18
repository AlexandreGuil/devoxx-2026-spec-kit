# Tasks: Validation biographie speaker

**Input**: Design documents from `/specs/005-validate-speaker-bio/`
**Prerequisites**: plan.md, spec.md

## Phase 0: Governance Compliance

- [x] TGOV-01 [GOV] Create ADR-0006: `docs/adrs/0006-validation-biographie-speaker.md`
- [x] TGOV-02 [GOV] Verify domain placement: validation dans `src/domain/talk.entity.ts`
- [x] TGOV-03 [GOV] Verify no forbidden imports

## Phase 1: Domain - Error class + validation

- [x] T001 Add `InvalidBioLengthError` class in `src/domain/talk.entity.ts`
- [x] T002 Add `bio: string` parameter to Talk constructor (after speakerName)
- [x] T003 Add bio validation in constructor: trim + check 50-500
- [x] T004 Update `changeDuration` to pass `this.bio`

## Phase 2: Application + Infrastructure

- [x] T005 [P] Add `bio: string` to `SubmitTalkInput` interface
- [x] T006 [P] Pass `input.bio` to Talk constructor in `SubmitTalkUseCase`
- [x] T007 [P] Add valid bios to demo talks in `InMemoryTalkRepository`
- [x] T008 [P] Update CLI demo calls with bio parameter

## Phase 3: Tests

- [x] T009 Create `src/domain/talk.entity.spec.ts`
- [x] T010 Test: bio 50 chars -> accepted
- [x] T011 Test: bio 500 chars -> accepted
- [x] T012 Test: bio 49 chars -> InvalidBioLengthError
- [x] T013 Test: bio 501 chars -> InvalidBioLengthError
- [x] T014 Test: whitespace-only bio -> InvalidBioLengthError (trimmed to 0)

## Phase 4: Commit & PR

- [x] T015 Run tests: `npm test`
- [x] T016 Run compliance: `npm run test:compliance`
- [x] T017 Commit with conventional message
- [x] T018 Push branch

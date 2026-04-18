---
description: 'Task list for 001-validate-speaker-bio feature implementation'
---

# Tasks: Validate Speaker Bio

**Input**: Design documents from `/specs/001-validate-speaker-bio/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅
**Governance**: Rules from `.specify/memory/governance-rules.md` and `.spec-kit/governance.md`

**Tests**: Included — Constitution Principe V mandates TDD (tests before implementation).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story/GOV] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- **[GOV]**: Governance/compliance task (MANDATORY for CI/CD)

---

## Phase 0: Governance Compliance (MANDATORY) 🛡️

**Purpose**: Create the ADR required by Constitution Principe III before any domain code is written.

**⚠️ CRITICAL**: PR will be BLOCKED by CI/CD (Agent 2 — ADR Reviewer) if this task is incomplete.

### Documentation Requirements

- [x] TGOV-01 [GOV] Create ADR for domain modification in `docs/adrs/0006-validation-biographie-speaker.md` using the mandatory format: `# ADR-0006 : Validation de la biographie du speaker`, with sections **Statut** (Accepté), **Date** (2026-03-17), **Contexte** (bio obligatoire au CFP, pas de contrainte de longueur actuellement), **Décision** (50–500 caractères, InvalidBioLengthError suivant le pattern existant), **Conséquences** (contrat Talk constructor étendu, tous les call sites mis à jour)

### Architecture Compliance

- [x] TGOV-02 [GOV] Verify that after implementation, domain imports remain pure — run `grep -rE "from\s+['\"]\.\./(infrastructure|application)" src/domain/` and confirm empty output

### Pre-Merge Validation

- [x] TGOV-03 [GOV] Run `npm run test:compliance` and confirm all governance gates pass (Structure ✅, Imports ✅, ADR ✅)

**Checkpoint**: ✅ Governance prepared — ADR written before code changes (as required by Principe III)

---

## Phase 1: Setup

**Purpose**: No new project setup required — this feature adds to an existing TypeScript project with Vitest already configured.

- [x] T001 Confirm test runner works against the current codebase by running `npm test` and verifying all existing tests in `tests/unit/domain/talk.entity.test.ts` pass

**Checkpoint**: Baseline green — existing tests pass, ready to write new failing tests

---

## Phase 2: Foundational — TDD Red (Write All Tests First)

**Purpose**: Write ALL bio validation test cases before any implementation. Constitution Principe V mandates tests precede code. All tests in this phase MUST FAIL after writing.

**⚠️ CRITICAL**: Do not implement anything in `src/` until all bio test cases are written and confirmed to fail.

- [x] T002 Add a `validTalkData` fixture update strategy note: existing tests in `tests/unit/domain/talk.entity.test.ts` use a fixture without `bio` — plan to add a `bio` field to `validTalkData` after the domain is updated (do NOT break existing tests now; note this for Phase 3)

- [x] T003 [US1] Add bio acceptance test cases to `tests/unit/domain/talk.entity.test.ts` in a new `describe('Bio Validation', ...)` block:
  - bio = `'A'.repeat(50)` → Talk created successfully (boundary lower)
  - bio = `'A'.repeat(500)` → Talk created successfully (boundary upper)
  - bio = `'A'.repeat(200)` → Talk created successfully (mid-range)

- [x] T004 [US2] Add bio-too-short test cases to `tests/unit/domain/talk.entity.test.ts` (same `describe` block):
  - bio = `'A'.repeat(49)` → throws `InvalidBioLengthError` (one below lower boundary)
  - bio = `''` → throws `InvalidBioLengthError` (empty)
  - bio = `'A'.repeat(10)` → error message contains `"10"` and `"50"`
  - bio = `' '.repeat(50)` → throws `InvalidBioLengthError` (whitespace-only, trimmed to 0)

- [x] T005 [US3] Add bio-too-long test cases to `tests/unit/domain/talk.entity.test.ts` (same `describe` block):
  - bio = `'A'.repeat(501)` → throws `InvalidBioLengthError` (one above upper boundary)
  - bio = `'A'.repeat(600)` → error message contains `"600"` and `"500"`

- [x] T006 Run `npm test` and confirm ALL new bio test cases FAIL (TypeScript compilation error or runtime failure expected — `bio` param does not exist yet)

**Checkpoint**: All bio tests written and failing — TDD Red phase complete, safe to implement

---

## Phase 3: User Story 1 — Valid Bio Acceptance (Priority: P1) 🎯 MVP

**Goal**: Talk creation succeeds when bio is between 50 and 500 characters (inclusive, trimmed).

**Independent Test**: Run `npm test` — US1 acceptance cases (`bio = 50 chars`, `bio = 500 chars`, `bio = 200 chars`) pass.

### Implementation for User Story 1

- [x] T007 [US1] Add exported constants `BIO_MIN_LENGTH = 50` and `BIO_MAX_LENGTH = 500` to `src/domain/talk.entity.ts` (above the `InvalidBioLengthError` class)

- [x] T008 [US1] Add `InvalidBioLengthError` class to `src/domain/talk.entity.ts` immediately after `InvalidTitleLengthError`, following the same pattern:
  ```
  constructor(actualLength: number, constraint: 'min' | 'max')
  name = 'InvalidBioLengthError'
  message (min): `Bio length (${actualLength} characters) is below the minimum required length of ${BIO_MIN_LENGTH} characters`
  message (max): `Bio length (${actualLength} characters) exceeds the maximum allowed length of ${BIO_MAX_LENGTH} characters`
  ```

- [x] T009 [US1] Add `bio: string` as the 5th parameter (before `duration`) in the `Talk` constructor signature in `src/domain/talk.entity.ts`, and add `public readonly bio: string` field

- [x] T010 [US1] Add bio validation logic in the `Talk` constructor body in `src/domain/talk.entity.ts` (after `speakerName` validation, before duration validation):
  ```
  const trimmedBio = bio.trim()
  if trimmedBio.length < BIO_MIN_LENGTH → throw new InvalidBioLengthError(trimmedBio.length, 'min')
  if trimmedBio.length > BIO_MAX_LENGTH → throw new InvalidBioLengthError(trimmedBio.length, 'max')
  this.bio = trimmedBio  // store trimmed value
  ```

- [x] T011 [US1] Update the `validTalkData` fixture in `tests/unit/domain/talk.entity.test.ts` to include `bio: 'A'.repeat(200)` so all existing title/duration tests continue to pass

- [x] T012 [US1] Update all `new Talk(...)` calls in `tests/unit/domain/talk.entity.test.ts` to include a valid `bio` argument in the 5th position — 9 existing call sites in the title and regression test blocks

- [x] T013 [US1] Run `npm test` and confirm:
  - All US1 bio acceptance cases pass (bio 50, 200, 500)
  - All pre-existing title and duration tests still pass (no regression)

**Checkpoint**: US1 complete — Talk accepts valid bio, existing tests unbroken ✅

---

## Phase 4: User Story 2 — Bio Too Short Rejection (Priority: P2)

**Goal**: Submissions with bio shorter than 50 characters (after trimming) are rejected with `InvalidBioLengthError` specifying the "too short" constraint and the actual length.

**Independent Test**: Run `npm test` — US2 rejection cases (bio 49 chars, empty, 10 chars with message check, whitespace-only) pass.

### Validation for User Story 2

- [x] T014 [US2] Run `npm test` and verify all US2 test cases written in Phase 2 now pass:
  - `bio = 'A'.repeat(49)` → throws `InvalidBioLengthError` ✅
  - `bio = ''` → throws `InvalidBioLengthError` ✅
  - `bio = 'A'.repeat(10)` → error message contains `"10"` and `"50"` ✅
  - `bio = ' '.repeat(50)` → throws `InvalidBioLengthError` (whitespace trimmed to 0) ✅

- [x] T015 [US2] If any US2 test fails: debug the trimming logic in `src/domain/talk.entity.ts` — ensure `bio.trim()` is called before the length comparison, not raw `bio.length`

**Checkpoint**: US2 complete — Too-short bios are rejected with informative error messages ✅

---

## Phase 5: User Story 3 — Bio Too Long Rejection (Priority: P3)

**Goal**: Submissions with bio exceeding 500 characters are rejected with `InvalidBioLengthError` specifying the "too long" constraint and the actual length.

**Independent Test**: Run `npm test` — US3 rejection cases (bio 501 chars, 600 chars with message check) pass.

### Validation for User Story 3

- [x] T016 [US3] Run `npm test` and verify all US3 test cases written in Phase 2 now pass:
  - `bio = 'A'.repeat(501)` → throws `InvalidBioLengthError` ✅
  - `bio = 'A'.repeat(600)` → error message contains `"600"` and `"500"` ✅

- [x] T017 [US3] If any US3 test fails: debug the max-length check in `src/domain/talk.entity.ts` — ensure the `BIO_MAX_LENGTH` constant (500) is used in both the condition and the error message

**Checkpoint**: US3 complete — All three user stories independently pass ✅

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Update all call sites outside the domain layer, run full validation suite.

- [x] T018 [P] Update `SubmitTalkInput` interface in `src/application/submit-talk.usecase.ts` to add `bio: string` field, and update the `new Talk(...)` call to pass `input.bio` as the 5th argument

- [x] T019 [P] Update all 3 demo `new Talk(...)` calls in `src/infrastructure/in-memory-talk.repository.ts` to include a representative `bio` string (50–500 chars) in the 5th position for each demo talk

- [x] T020 Update the two `submitTalk.execute({...})` calls in `src/infrastructure/cli.ts` to include a `bio` field — valid bio for the success demo, any bio for the error demo

- [x] T021 Run `npm run build` to confirm TypeScript strict-mode compilation succeeds across all modified files

- [x] T022 Run `npm test` — full suite must pass (all unit tests green, zero regressions)

- [x] T023 Run `npm run lint` — ESLint + Prettier must report no errors

- [x] T024 Run `npm run test:compliance` — all governance gates must pass (Structure, Imports, ADR)

- [x] T025 Review `docs/adrs/0006-validation-biographie-speaker.md` and confirm content accurately describes the final implementation (update if any decisions changed during coding)

**Checkpoint**: ✅ Feature complete — all tests green, build clean, governance gates pass, ready for PR

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 0 (Governance)**: No dependencies — write ADR BEFORE touching code (Principe III)
- **Phase 1 (Setup)**: No dependencies — baseline verification
- **Phase 2 (Foundational — TDD Red)**: Depends on Phase 1 completion — write ALL tests before implementing
- **Phase 3 (US1)**: Depends on Phase 2 — implement only after tests are written and failing
- **Phase 4 (US2)**: Depends on Phase 3 — domain implementation already complete; validate tests pass
- **Phase 5 (US3)**: Depends on Phase 3 — domain implementation already complete; validate tests pass
- **Phase 6 (Polish)**: Depends on Phases 3–5 all passing — update call sites and run full checks

### User Story Dependencies

- **US1 (P1)**: Core implementation — required by US2 and US3 (shared domain change)
- **US2 (P2)**: No new implementation after US1 — just test validation
- **US3 (P3)**: No new implementation after US1 — just test validation

### Parallel Opportunities

- `TGOV-01`, `TGOV-02` can run in parallel (different files)
- `T003`, `T004`, `T005` (writing test cases per story) can run in parallel — same file, different `describe` blocks; coordinate to avoid conflicts
- `T007`, `T008` (constants + error class) can run in parallel — same file section, coordinate
- `T018`, `T019` (update use case + repository) can run in parallel — different files, no dependencies between them
- `T014` and `T016` can run in parallel (validating US2 and US3 test cases after US1 implementation)

---

## Parallel Example: Phase 6 Call Site Updates

```bash
# These three tasks touch different files and can run simultaneously:
Task T018: Update src/application/submit-talk.usecase.ts
Task T019: Update src/infrastructure/in-memory-talk.repository.ts
Task T020: Update src/infrastructure/cli.ts
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 0: Write ADR
2. Complete Phase 1: Baseline check
3. Complete Phase 2: Write all tests (TDD Red)
4. Complete Phase 3: Implement domain changes (US1 tests go green)
5. **STOP and VALIDATE**: `npm test` — all US1 cases pass, no regressions
6. Proceed to Phase 4 + 5 (US2, US3 — zero new implementation needed)

### Incremental Delivery

1. Phase 0 + 1 + 2 → ADR written, tests written and failing
2. Phase 3 → Domain implemented, US1 tests green (MVP: valid bio accepted)
3. Phase 4 → US2 validated (too-short rejection confirmed)
4. Phase 5 → US3 validated (too-long rejection confirmed)
5. Phase 6 → Call sites updated, full suite passes → PR ready

### Key insight

Because all three user stories are served by a single domain change (adding bio validation to the `Talk` constructor), US2 and US3 become **free** once US1 is implemented. The effort is front-loaded in writing complete tests (Phase 2) and implementing the domain (Phase 3). Phases 4 and 5 are validation checkpoints only.

---

## Notes

- `[P]` tasks = different files, no dependencies — can run in parallel
- `[US1/US2/US3]` maps tasks to specific user stories for traceability
- Tests MUST be written BEFORE implementation (Constitution Principe V — TDD Red → Green → Refactor)
- The `bio` parameter is inserted at position 5 in the `Talk` constructor (before `duration`) — update all call sites carefully
- `bio` is stored trimmed (`this.bio = bio.trim()`) — tests must account for this
- Commit order suggestion: `TGOV-01` first (ADR), then test file changes, then domain implementation, then call site updates
- Run `npm run build` before pushing — TypeScript strict mode will catch missing `bio` arguments at compile time

---

## Task Summary

| Phase | Tasks | Description |
| ----- | ----- | ----------- |
| 0 — Governance | TGOV-01, TGOV-02, TGOV-03 | ADR + compliance checks |
| 1 — Setup | T001 | Baseline test run |
| 2 — Foundational | T002–T006 | TDD Red: write all tests |
| 3 — US1 (P1) | T007–T013 | Implement domain + validate US1 |
| 4 — US2 (P2) | T014–T015 | Validate too-short rejection |
| 5 — US3 (P3) | T016–T017 | Validate too-long rejection |
| 6 — Polish | T018–T025 | Call sites + full validation |
| **Total** | **23 tasks** | |

---
description: 'Task list for Feature 003: Limit Number of Speakers per Talk'
---

# Tasks: Limit Number of Speakers per Talk

**Input**: Design documents from `/specs/003-limit-speakers/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md, contracts/
**Governance**: Rules from `.specify/memory/governance-rules.md` and `.spec-kit/governance.md`

**Tests**: This feature follows TDD approach as specified in plan.md and constitution.md (Principle V).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story/GOV] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2)
- **[GOV]**: Governance/compliance task (MANDATORY for CI/CD)
- Include exact file paths in descriptions

## Path Conventions

- **Single project**: `src/`, `tests/` at repository root
- Clean Architecture: `src/domain/`, `src/application/`, `src/infrastructure/`

---

## Phase 0: Governance Compliance (MANDATORY) 🛡️

**Purpose**: Ensure all governance rules from `.spec-kit/governance.md` are satisfied

**⚠️ EXCEPTION**: ADR requirement (Rule 3) waived per user request (urgent business need documented in spec.md:99-101)

**Reference**: See `.specify/memory/governance-rules.md` for full rule definitions

### Documentation Requirements

- [ ] TGOV-01 [GOV] ~~Create ADR for this feature: `docs/adrs/0006-limit-speakers-per-talk.md`~~ **WAIVED**
  - **EXCEPTION**: User specified "PAS D'ADR REQUIS (urgent, pas le temps)"
  - ADR can be created later for documentation purposes if needed
  - This exception is documented in spec.md:99-101

### Architecture Compliance

- [ ] TGOV-02 [GOV] Verify new code placement follows Clean Architecture:
  - Domain error: `src/domain/talk.entity.ts` (InvalidSpeakerCountError)
  - Domain entity modification: `src/domain/talk.entity.ts` (Talk constructor validation)
  - No new files in application/ or infrastructure/ layers

- [ ] TGOV-03 [GOV] Verify no forbidden imports exist:
  ```bash
  # These commands MUST return empty results:
  grep -rE "from\s+['\"]\.\./(infrastructure|application)" src/domain/
  grep -rE "from\s+['\"]\.\./(infrastructure)" src/application/
  ```

### Pre-Merge Validation

- [ ] TGOV-04 [GOV] Run local governance check: `npm run test:compliance`
- [ ] TGOV-05 [GOV] Verify implementation matches spec.md requirements

**Checkpoint**: ✅ Governance ready (ADR waived) - CI/CD will auto-validate structure and imports on PR

---

## Phase 1: Setup (TDD Preparation)

**Purpose**: Prepare test infrastructure and understand current implementation

**No infrastructure changes needed**: This is a domain-only modification to existing Talk entity

- [x] T001 Review existing Talk entity implementation in `src/domain/talk.entity.ts`
  - Understand current constructor signature (lines 49-55)
  - Understand existing error patterns (InvalidDurationError, InvalidTitleLengthError)
  - Identify validation location (constructor, lines 56-70)

- [x] T002 Review existing Talk entity tests in `tests/unit/domain/talk.entity.test.ts`
  - Understand current test structure and patterns
  - Identify test data setup (validTalkData object)
  - Note that all existing tests will need constructor signature updates

**Checkpoint**: ✅ Current implementation understood - Ready to write failing tests (TDD Red phase)

---

## Phase 2: User Story 1 - System Rejects Talks with More Than 3 Speakers (Priority: P1) 🎯 MVP

**Goal**: Enforce speaker count validation (1-3 speakers accepted, 0 or 4+ rejected) at domain entity level

**Independent Test**: Create Talk instances with 0, 1, 2, 3, 4, 5 speakers and verify correct acceptance/rejection behavior

**TDD Approach**: Red (write failing tests) → Green (implement) → Refactor (clean up)

### TDD Red: Write Failing Tests

> **IMPORTANT**: These tests MUST fail before implementation. Run tests after each test file update to confirm failures.

- [x] T003 [P] [US1] Write unit test: Accept talk with 1 speaker in `tests/unit/domain/talk.entity.test.ts`
  - Test creates Talk with `speakers: ['Alice']`
  - Verifies `talk.speakers.length === 1`
  - **Expected**: Test FAILS (speakers array doesn't exist yet)

- [x] T004 [P] [US1] Write unit test: Accept talk with 2 speakers in `tests/unit/domain/talk.entity.test.ts`
  - Test creates Talk with `speakers: ['Alice', 'Bob']`
  - Verifies `talk.speakers.length === 2`
  - **Expected**: Test FAILS (speakers array doesn't exist yet)

- [x] T005 [P] [US1] Write unit test: Accept talk with 3 speakers (maximum) in `tests/unit/domain/talk.entity.test.ts`
  - Test creates Talk with `speakers: ['Alice', 'Bob', 'Carol']`
  - Verifies `talk.speakers.length === 3`
  - **Expected**: Test FAILS (speakers array doesn't exist yet)

- [x] T006 [P] [US1] Write unit test: Reject talk with 0 speakers in `tests/unit/domain/talk.entity.test.ts`
  - Test attempts to create Talk with `speakers: []`
  - Verifies generic Error is thrown with message "At least one speaker is required"
  - **Expected**: Test FAILS (validation doesn't exist yet)

- [x] T007 [P] [US1] Write unit test: Reject talk with 4 speakers in `tests/unit/domain/talk.entity.test.ts`
  - Test attempts to create Talk with `speakers: ['A', 'B', 'C', 'D']`
  - Verifies InvalidSpeakerCountError is thrown
  - **Expected**: Test FAILS (error class and validation don't exist yet)

- [x] T008 [P] [US1] Write unit test: Reject talk with 5 speakers in `tests/unit/domain/talk.entity.test.ts`
  - Test attempts to create Talk with `speakers: ['A', 'B', 'C', 'D', 'E']`
  - Verifies InvalidSpeakerCountError is thrown
  - **Expected**: Test FAILS (error class and validation don't exist yet)

- [x] T009 [US1] Run test suite to confirm all 6 new tests FAIL:
  ```bash
  npm test tests/unit/domain/talk.entity.test.ts
  ```
  - **Expected**: 6 failures (tests for new functionality that doesn't exist yet)
  - Document failure output for verification

**Checkpoint**: ✅ TDD Red phase complete - All tests fail as expected

### TDD Green: Implement Minimum Code

> **IMPORTANT**: Write ONLY enough code to make tests pass. No extra features.

- [x] T010 [US1] Create InvalidSpeakerCountError domain error in `src/domain/talk.entity.ts`
  - Add class after InvalidTitleLengthError (around line 36)
  - Constructor parameters: `actualCount: number, maxCount: number`
  - Error message format: `"Speaker count (${actualCount} speakers) exceeds the maximum allowed (${maxCount} speakers)"`
  - Set `this.name = 'InvalidSpeakerCountError'`
  - Follow existing error patterns in file

- [x] T011 [US1] Update Talk entity constructor signature in `src/domain/talk.entity.ts`
  - Replace `speakerName: string` (line 53) with `speakers: string[]`
  - Update property from `public readonly speakerName: string` to `public readonly speakers: string[]`
  - **Breaking change**: This affects all code instantiating Talk

- [x] T012 [US1] Add speaker count validation in Talk constructor in `src/domain/talk.entity.ts`
  - Add validation after title length check (around line 66)
  - Check 1: `if (!speakers || speakers.length === 0)` → throw generic Error
  - Check 2: `if (speakers.length > 3)` → throw InvalidSpeakerCountError(speakers.length, 3)
  - Place before duration validation to maintain validation order

- [x] T013 [US1] Update all existing Talk entity tests in `tests/unit/domain/talk.entity.test.ts`
  - Find all `new Talk(...)` constructor calls
  - Replace 4th parameter from `'John Doe'` to `['John Doe']` (wrap in array)
  - Update validTalkData object: `speakerName: 'John Doe'` → `speakers: ['John Doe']`
  - **Critical**: ALL existing tests must pass after this update

- [x] T014 [US1] Run test suite to verify all tests pass (both new and existing):
  ```bash
  npm test tests/unit/domain/talk.entity.test.ts
  ```
  - **Expected**: All 6 new tests PASS + all existing regression tests PASS
  - Verify no test failures

**Checkpoint**: ✅ TDD Green phase complete - All tests pass, validation enforced

### TDD Refactor: Clean Up

- [x] T015 [US1] Review InvalidSpeakerCountError implementation for code quality
  - Verify error message matches spec requirements (includes actual count and max count)
  - Verify error name is set correctly for type checking
  - Compare with existing error patterns (InvalidDurationError, InvalidTitleLengthError)

- [x] T016 [US1] Review Talk entity validation logic for clarity
  - Verify validation order is logical (id → title → speakers → duration)
  - Verify error messages are clear and actionable
  - Check for any code duplication

- [x] T017 [US1] Run full test suite to ensure no regressions:
  ```bash
  npm test
  ```
  - **Expected**: All tests pass (domain, application, infrastructure)
  - **Expected**: No TypeScript compilation errors

**Checkpoint**: ✅ User Story 1 complete - Speaker count validation fully functional and tested

---

## Phase 3: User Story 2 - Clear Error Messages for Invalid Speaker Count (Priority: P2)

**Goal**: Verify error messages are clear, actionable, and include both actual count and maximum allowed

**Independent Test**: Trigger validation errors and verify message content includes specific counts

**Note**: This functionality is already implemented in User Story 1 (InvalidSpeakerCountError constructor), but we add explicit tests to verify error message quality per spec requirements.

### Tests for User Story 2

- [x] T018 [P] [US2] Write unit test: Error message includes actual count and max for 4 speakers in `tests/unit/domain/talk.entity.test.ts`
  - Test attempts to create Talk with 4 speakers
  - Catches error and verifies message includes "4 speakers" and "3 speakers"
  - Verifies exact message format matches spec
  - **Expected**: Test should PASS (implemented in US1)

- [x] T019 [P] [US2] Write unit test: Error message includes actual count and max for 5 speakers in `tests/unit/domain/talk.entity.test.ts`
  - Test attempts to create Talk with 5 speakers
  - Catches error and verifies message includes "5 speakers" and "3 speakers"
  - Verifies message is clear and actionable
  - **Expected**: Test should PASS (implemented in US1)

- [x] T020 [P] [US2] Write unit test: Error is instance of InvalidSpeakerCountError in `tests/unit/domain/talk.entity.test.ts`
  - Test attempts to create Talk with 4+ speakers
  - Catches error and verifies `error instanceof InvalidSpeakerCountError`
  - Verifies `error.name === 'InvalidSpeakerCountError'`
  - **Expected**: Test should PASS (implemented in US1)

- [x] T021 [US2] Run test suite to verify error message quality tests pass:
  ```bash
  npm test tests/unit/domain/talk.entity.test.ts
  ```
  - **Expected**: All User Story 2 tests PASS
  - Verify error messages meet spec requirements (FR-004, FR-005)

**Checkpoint**: ✅ User Story 2 complete - Error messages verified to be clear and actionable

---

## Phase 4: Integration & Breaking Change Updates

**Purpose**: Update application and infrastructure layers to use new Talk entity API

**Breaking Change**: Constructor signature changed from `speakerName: string` to `speakers: string[]`

### Application Layer Updates

- [x] T022 [P] Check if submit-talk.usecase.ts needs updates in `src/application/submit-talk.usecase.ts`
  - Review if use case instantiates Talk entities
  - If yes: Update constructor calls to pass `speakers: string[]`
  - If no: No changes needed (use case may not instantiate Talk directly)

- [x] T023 [P] Check if list-talks.usecase.ts needs updates in `src/application/list-talks.usecase.ts`
  - Review if use case reads Talk entities
  - **Likely**: No changes needed (use case only reads, doesn't instantiate)

### Infrastructure Layer Updates

- [x] T024 [P] Check if in-memory-talk.repository.ts needs updates in `src/infrastructure/in-memory-talk.repository.ts`
  - Review if repository instantiates Talk entities
  - Update any test data or seed data to use `speakers: string[]`
  - **Note**: Repository stores Talk instances, may not instantiate them

- [x] T025 Check if cli.ts needs updates in `src/infrastructure/cli.ts`
  - Review if CLI prompts for speaker input
  - If single speaker input: Wrap in array `[speakerName]`
  - If multiple speakers: Parse comma-separated input into array
  - Update validation messages to mention "maximum 3 speakers"

### Integration Tests

- [x] T026 Run full integration test suite to verify no regressions:
  ```bash
  npm test
  ```
  - **Expected**: All tests pass across all layers
  - **Expected**: No breaking changes in application/infrastructure layers

**Checkpoint**: ✅ Integration complete - All layers updated for new Talk entity API

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Final validation and documentation

### Documentation

- [x] T027 [P] Verify quickstart.md examples are accurate in `specs/003-limit-speakers/quickstart.md`
  - All code examples use correct constructor signature
  - Error handling examples match actual error messages
  - Migration guide reflects actual breaking changes

- [x] T028 [P] Update CLAUDE.md if needed (already updated by update-agent-context.sh)
  - Verify feature is documented in "Recent Changes"
  - No additional updates needed (script already ran)

### Code Quality

- [x] T029 Run linting and formatting:
  ```bash
  npm run lint
  npm run format
  ```
  - **Expected**: No linting errors
  - **Expected**: Code follows project style guide

- [x] T030 Verify TypeScript strict mode compliance:
  ```bash
  npm run build
  ```
  - **Expected**: No TypeScript compilation errors
  - **Expected**: Strict mode violations caught and fixed

### Final Validation

- [ ] T031 Run all tests with coverage:
  ```bash
  npm run test:coverage
  ```
  - **Expected**: 100% coverage for domain layer (constitution requirement)
  - **Expected**: Talk entity validation fully covered

- [ ] T032 Manual validation: Test all acceptance scenarios from spec.md
  - Scenario 1: Talk with 1 speaker succeeds ✅
  - Scenario 2: Talk with 2 speakers succeeds ✅
  - Scenario 3: Talk with 3 speakers succeeds ✅
  - Scenario 4: Talk with 4 speakers throws InvalidSpeakerCountError ✅
  - Scenario 5: Talk with 5 speakers throws InvalidSpeakerCountError ✅
  - Scenario 6: Talk with 0 speakers throws Error ✅
  - Scenario 7: Error message includes "4 speakers" and "maximum 3 allowed" ✅
  - Scenario 8: Error message includes "5 speakers" and "maximum 3 allowed" ✅
  - Scenario 9: Error is instance of InvalidSpeakerCountError with correct name ✅

**Checkpoint**: ✅ Feature complete and validated - Ready for PR

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 0 (Governance)**: Can be done at any time before PR merge
- **Phase 1 (Setup)**: No dependencies - can start immediately
- **Phase 2 (User Story 1)**: Depends on Phase 1 completion - BLOCKS User Story 2
- **Phase 3 (User Story 2)**: Depends on Phase 2 completion (tests verify US1 implementation)
- **Phase 4 (Integration)**: Depends on Phase 2 completion (core implementation must exist)
- **Phase 5 (Polish)**: Depends on all previous phases

### User Story Dependencies

- **User Story 1 (P1)**: Independent - implements core validation
- **User Story 2 (P2)**: Depends on User Story 1 (tests error messages from US1 implementation)

**Note**: User Story 2 is essentially a verification phase for US1's error messages. Both stories are tightly coupled in this feature.

### Within Each Phase

- **Phase 2 (US1)**:
  - Tests T003-T008 can be written in parallel (marked [P])
  - Implementation T010-T012 must be sequential (error class → constructor → validation)
  - Test updates T013-T014 must be sequential (update tests → verify pass)

- **Phase 3 (US2)**:
  - All tests T018-T020 can be written in parallel (marked [P])
  - All tests should pass immediately (functionality exists from US1)

- **Phase 4 (Integration)**:
  - Application checks T022-T023 can be done in parallel (marked [P])
  - Infrastructure checks T024-T025 can be done in parallel (marked [P])

### Parallel Opportunities

- Within Phase 2 TDD Red: All 6 test writing tasks (T003-T008) can be written in parallel
- Within Phase 3: All 3 error message tests (T018-T020) can be written in parallel
- Within Phase 4: Application checks (T022-T023) and infrastructure checks (T024-T025) can be done in parallel
- Within Phase 5: Documentation tasks (T027-T028) and linting (T029-T030) can be done in parallel

---

## Parallel Example: User Story 1 (TDD Red)

```bash
# Launch all test writing tasks for User Story 1 together:
Task T003: "Write unit test: Accept talk with 1 speaker"
Task T004: "Write unit test: Accept talk with 2 speakers"
Task T005: "Write unit test: Accept talk with 3 speakers"
Task T006: "Write unit test: Reject talk with 0 speakers"
Task T007: "Write unit test: Reject talk with 4 speakers"
Task T008: "Write unit test: Reject talk with 5 speakers"

# All tests can be written in parallel since they're in the same file
# but testing different scenarios (different test cases)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (understand current implementation)
2. Complete Phase 2: User Story 1 (TDD Red → Green → Refactor)
3. **STOP and VALIDATE**: Run all tests, verify speaker count validation works
4. Skip User Story 2 if time-critical (it's just error message verification)
5. Complete Phase 4: Integration (update other layers)
6. Deploy/demo if ready

### Full Feature Delivery

1. Complete Phase 1: Setup
2. Complete Phase 2: User Story 1 (core validation)
3. Complete Phase 3: User Story 2 (error message quality verification)
4. Complete Phase 4: Integration (update application/infrastructure layers)
5. Complete Phase 5: Polish (documentation, linting, final validation)
6. Complete Phase 0: Governance (pre-PR checklist)
7. Create Pull Request

### TDD Workflow (Critical for Quality)

**Red Phase** (T003-T009):
- Write all failing tests FIRST
- Run tests to confirm they fail
- Do NOT write implementation yet

**Green Phase** (T010-T014):
- Write MINIMUM code to make tests pass
- Run tests frequently to see progress
- Stop when all tests pass

**Refactor Phase** (T015-T017):
- Improve code quality WITHOUT changing behavior
- Run tests after each refactor to ensure no breakage
- Clean up, remove duplication, improve naming

---

## Notes

- [P] tasks = different files or independent test cases, no dependencies
- [Story] label maps task to specific user story for traceability
- [GOV] label marks governance compliance tasks (mandatory for PR merge)
- Each user story should be independently testable
- TDD approach is MANDATORY per constitution (Principle V)
- Verify tests fail before implementing (Red phase)
- Commit after each logical group of tasks
- Stop at any checkpoint to validate independently
- Breaking change: All Talk instantiation must update to use speakers array

---

## Summary

**Total Tasks**: 32 tasks
- Phase 0 (Governance): 5 tasks (1 waived)
- Phase 1 (Setup): 2 tasks
- Phase 2 (User Story 1): 15 tasks (6 tests + 5 implementation + 4 refactor)
- Phase 3 (User Story 2): 4 tasks (3 tests + 1 verification)
- Phase 4 (Integration): 5 tasks
- Phase 5 (Polish): 6 tasks

**Parallel Opportunities**:
- Phase 2: 6 test tasks can run in parallel (T003-T008)
- Phase 3: 3 test tasks can run in parallel (T018-T020)
- Phase 4: 4 check tasks can run in parallel (T022-T025)
- Phase 5: 4 documentation/quality tasks can run in parallel (T027-T030)

**MVP Scope**: Phases 1 + 2 + 4 = Speaker count validation fully functional

**Critical Path**: Phase 1 → Phase 2 (TDD Red → Green → Refactor) → Phase 4 (Integration) → Phase 0 (Governance) → PR

**Estimated Complexity**: Low-Medium (domain-only change, well-defined requirements, clear test scenarios)

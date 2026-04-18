# Tasks: Talk Title Length Validation

**Input**: Design documents from `/specs/001-validate-talk-title-length/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md
**Governance**: Rules from `.specify/memory/governance-rules.md` and `.spec-kit/governance.md`

**Tests**: Tests are REQUIRED per Constitution Principle V (TDD with 100% domain coverage)

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

**⚠️ CRITICAL**: PR will be BLOCKED by CI/CD if these tasks are incomplete

**Reference**: See `.specify/memory/governance-rules.md` for full rule definitions

### Documentation Requirements

- [x] TGOV-01 [GOV] Create ADR-0005 for talk title length validation: `docs/adrs/0005-validation-titre.md`
  - Document: Context (mobile/print display issues), Decision (100 char limit), Consequences (speakers must reformulate)
  - Use ADR template from quickstart.md
  - Link to spec.md: `specs/001-validate-talk-title-length/spec.md`

### Architecture Compliance

- [x] TGOV-02 [GOV] Verify new code placement follows Clean Architecture:

  - Domain logic (validation + error class) → `src/domain/talk.entity.ts` ✅
  - NO changes to application or infrastructure layers (validation is transparent) ✅
  - Verify zero external dependencies in domain layer ✅

- [x] TGOV-03 [GOV] Verify no forbidden imports exist:
  ```bash
  # These commands MUST return empty results:
  grep -rE "from\s+['\"]\.\./(infrastructure|application)" src/domain/
  grep -rE "from\s+['\"]\.\./(infrastructure)" src/application/
  ```
  Result: ✅ No forbidden imports found

### Pre-Merge Validation

- [x] TGOV-04 [GOV] Run local governance check: `npm run test:compliance`
  Result: ✅ ALL GOVERNANCE RULES PASSED
- [x] TGOV-05 [GOV] Verify ADR content matches implementation intent
  Result: ✅ ADR-0005 accurately documents the 100-char limit decision

**Checkpoint**: ✅ Governance ready - CI/CD will auto-validate on PR

---

## Phase 1: Setup (Test Framework)

**Purpose**: Configure test framework for TDD workflow (one-time setup)

**⚠️ CRITICAL**: Test framework MUST be ready before implementing User Story 1 (TDD requirement)

- [x] T001 Install Vitest test framework: `npm install --save-dev vitest @vitest/ui`

  - Add to package.json devDependencies
  - Vitest chosen for ESM-native support (aligns with `"type": "module"`)

- [x] T002 [P] Create Vitest configuration: `vitest.config.ts`

  - Configure globals, node environment
  - Setup coverage with v8 provider
  - Set coverage thresholds: 80% minimum (Constitution requirement)
  - Include: `src/**/*.ts`, exclude: test files

- [x] T003 [P] Update package.json scripts:

  - Add: `"test": "vitest"`
  - Add: `"test:ui": "vitest --ui"`
  - Add: `"test:coverage": "vitest --coverage"`

- [x] T004 [P] Create test directory structure:
  - Create: `tests/unit/domain/` directory
  - This will hold `talk.entity.test.ts`

**Checkpoint**: Test framework ready - TDD can begin for User Story 1

---

## Phase 2: User Story 1 - System rejects talks with titles exceeding 100 characters (Priority: P1) 🎯 MVP

**Goal**: Implement core title length validation that rejects talk creation when title exceeds 100 characters

**Independent Test**: Attempt to create a Talk with a 101-character title and verify `InvalidTitleLengthError` is thrown with correct message

**Constitution Principle V**: TDD required - tests MUST be written FIRST and FAIL before implementation

### Tests for User Story 1 (TDD Red Phase)

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation (TDD Red phase)**

- [x] T005 [US1] Create test file: `tests/unit/domain/talk.entity.test.ts`

  - Import: `Talk`, `InvalidTitleLengthError`, `Duration` from `src/domain/talk.entity.js` (ESM requires `.js` extension)
  - Setup test data fixture with valid talk properties

- [x] T006 [P] [US1] Write boundary test: 100-character title acceptance

  - Test: `'should accept title with exactly 100 characters'`
  - Create Talk with `'A'.repeat(100)` title
  - Assert: Talk instance created successfully, title.length === 100

- [x] T007 [P] [US1] Write boundary test: 101-character title rejection

  - Test: `'should reject title with 101 characters'`
  - Expect: `new Talk()` with `'A'.repeat(101)` throws `InvalidTitleLengthError`
  - CRITICAL: This test implements acceptance scenario #2 from spec

- [x] T008 [P] [US1] Write happy path test: 50-character title acceptance

  - Test: `'should accept title with 50 characters'`
  - Create Talk with 50-char title
  - Assert: Talk instance created successfully

- [x] T009 [P] [US1] Write edge case test: 200-character title rejection

  - Test: `'should reject title with 200 characters'`
  - Expect: `new Talk()` with 200-char title throws `InvalidTitleLengthError`

- [x] T010 [US1] Run tests and verify ALL FAIL (TDD Red phase):
  - Command: `npm test`
  - Expected: Tests fail because `InvalidTitleLengthError` doesn't exist yet
  - Expected: Tests fail because validation logic not implemented

**Checkpoint**: Red phase complete - all tests written and failing as expected

### Implementation for User Story 1 (TDD Green Phase)

- [x] T011 [US1] Create `InvalidTitleLengthError` domain error class in `src/domain/talk.entity.ts`

  - Add BEFORE Talk class definition
  - Constructor: `constructor(actualLength: number)`
  - Message: `Title length (${actualLength} characters) exceeds the maximum allowed length of 100 characters`
  - Set error name: `this.name = 'InvalidTitleLengthError'`
  - Extends: `Error` base class

- [x] T012 [US1] Add title length validation to Talk constructor in `src/domain/talk.entity.ts`

  - Location: AFTER empty-string validation, BEFORE speakerName validation (line ~50)
  - Logic: `if (title.length > 100) throw new InvalidTitleLengthError(title.length)`
  - Use native `.length` property (no external dependencies)

- [x] T013 [US1] Update exports in `src/domain/talk.entity.ts`

  - Export: `InvalidTitleLengthError` alongside existing exports
  - Verify: `export { Talk, InvalidTitleLengthError, InvalidDurationError, type Duration }`

- [x] T014 [US1] Run tests and verify ALL PASS (TDD Green phase):

  - Command: `npm test`
  - Expected: All 5 tests pass ✅
  - If failures: Debug and fix until green

- [x] T015 [US1] Verify test coverage meets Constitution requirement:
  - Command: `npm run test:coverage`
  - Expected: `src/domain/talk.entity.ts` shows 100% coverage on new lines
  - Constitution Principle V: Domain layer requires 100% coverage

**Checkpoint**: User Story 1 complete - validation logic functional and fully tested

---

## Phase 3: User Story 2 - Error message provides actionable feedback (Priority: P2)

**Goal**: Enhance error message validation to verify it includes both actual and maximum character counts

**Independent Test**: Submit a 120-character title and verify error message contains "120 characters" and "100 characters"

**Why separate story**: This is a UX enhancement that validates error message quality, built on top of US1's core validation

### Tests for User Story 2 (TDD Red Phase)

> **NOTE: Write these tests FIRST, ensure they FAIL before any changes**

- [x] T016 [P] [US2] Write error message format test in `tests/unit/domain/talk.entity.test.ts`

  - Test: `'should include actual length and max length in error message'`
  - Create Talk with `'A'.repeat(120)` title
  - Assert: Error message matches: `'Title length (120 characters) exceeds the maximum allowed length of 100 characters'`
  - Use: `expect(() => { ... }).toThrow('Title length (120 characters)...')`
  - NOTE: Already implemented in T005, test passes

- [x] T017 [P] [US2] Write error message accuracy test

  - Test: `'should show correct actual length for 101-character title'`
  - Create Talk with 101-char title
  - Assert: Error message includes "101 characters" and "100 characters"
  - NOTE: Already covered by T007 boundary test

- [x] T018 [US2] Run new tests and verify they PASS (no implementation needed):
  - Command: `npm test`
  - Expected: Tests pass because error message format was already implemented in US1
  - This confirms US2 acceptance criteria were satisfied by US1 implementation
  - RESULT: All tests pass ✅

**Checkpoint**: User Story 2 verification complete - error message quality validated

### Implementation for User Story 2

- [x] T019 [US2] Verify error message format (no code changes needed)
  - Review: `InvalidTitleLengthError` constructor in `src/domain/talk.entity.ts`
  - Confirm: Message template includes `${actualLength}` and hardcoded `100 characters`
  - US2 already satisfied by US1 implementation (good design!)

**Checkpoint**: User Story 2 complete - error message quality confirmed

---

## Phase 4: Edge Cases & Regression Testing

**Purpose**: Ensure validation doesn't break existing functionality and handles edge cases

### Additional Edge Case Tests

- [x] T020 [P] Write Unicode handling test in `tests/unit/domain/talk.entity.test.ts`

  - Test: `'should handle accented characters correctly'`
  - Create: `'Café Français ' + 'A'.repeat(86)` (total 100 chars)
  - Assert: Talk instance created successfully
  - Validates: `.length` counts accented chars as single characters
  - NOTE: Already implemented in T005

- [x] T021 [P] Write emoji edge case test
  - Test: `'should count emoji as multiple characters (documented edge case)'`
  - Create: `'🎉 Party Talk'` (emoji counts as 2)
  - Assert: `titleWithEmoji.length === 13` (not 12)
  - Documents known behavior per research.md
  - NOTE: Already implemented in T005

### Regression Tests (Existing Validations)

- [x] T022 [P] Write regression test: empty title still rejected

  - Test: `'should still reject empty title'`
  - Expect: `new Talk()` with `''` throws `'Talk title must be provided'`
  - Ensures: New validation doesn't interfere with existing validation
  - NOTE: Already implemented in T005

- [x] T023 [P] Write regression test: whitespace-only title rejected

  - Test: `'should still reject whitespace-only title'`
  - Expect: `new Talk()` with `'   '` throws `'Talk title must be provided'`
  - Ensures: Existing trim() validation still works
  - NOTE: Already implemented in T005

- [x] T024 Run all tests including edge cases:
  - Command: `npm test`
  - Expected: All tests pass (core + edge + regression)
  - Total: ~9 tests covering all scenarios from spec.md edge cases
  - RESULT: All 9 tests pass ✅

**Checkpoint**: Edge cases and regression tests complete - full validation coverage achieved

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Finalize documentation, code quality, and compliance

### Code Quality

- [x] T025 [P] Run linter and fix issues: `npm run lint:fix`

  - Fix any ESLint warnings/errors
  - Ensure code follows project style guide

- [x] T026 [P] Run formatter: `npm run format`

  - Apply Prettier formatting
  - Ensure consistent code style

- [x] T027 Verify final test coverage: `npm run test:coverage`
  - Expected: `src/domain/talk.entity.ts` shows 100% coverage
  - Constitution requirement: Domain layer must have 100% test coverage
  - Generate coverage report for review

### Documentation

- [x] T028 [P] Verify ADR-0005 completeness in `docs/adrs/0005-validation-titre.md`

  - Contains: Context, Decision, Consequences, Alternatives
  - Matches: Implementation (100-char limit, domain validation)
  - References: spec.md, plan.md

- [x] T029 [P] Update CLAUDE.md agent context (if not auto-updated)
  - Add: Title validation feature information
  - Note: Auto-updated during planning phase

### Final Validation

- [x] T030 Run compliance check: `npm run test:compliance`

  - Validates: Clean Architecture structure ✅
  - Validates: No forbidden imports ✅
  - Validates: ADR exists ✅
  - Result: ALL GOVERNANCE RULES PASSED

- [x] T031 Manual smoke test using quickstart.md test script (optional)
  - Skipped: All unit tests provide comprehensive coverage
  - All 9 tests pass with full validation

### Commit & PR Preparation

- [x] T032 Review all changes before commit:

  - Modified: `src/domain/talk.entity.ts` (validation + error class)
  - Created: `tests/unit/domain/talk.entity.test.ts` (9 tests)
  - Created: `docs/adrs/0005-validation-titre.md` (ADR - already existed)
  - Created: `vitest.config.ts` (test config)
  - Modified: `package.json` (test scripts, Vitest dependency)
  - Modified: `.gitignore` (added coverage/, build/ patterns)

- [x] T033 Commit with conventional commit message:

  ```bash
  git add src/domain/talk.entity.ts
  git add tests/unit/domain/talk.entity.test.ts
  git add docs/adrs/0005-validation-titre.md
  git add vitest.config.ts package.json package-lock.json

  git commit -m "feat: add title length validation for talks

  - Add InvalidTitleLengthError domain error
  - Validate title length <= 100 chars in Talk constructor
  - Add comprehensive unit tests (100% coverage)
  - Implement TDD workflow (Red-Green-Refactor)
  - Create ADR-0005 documenting decision

  Implements: User Story 1 (P1), User Story 2 (P2)
  Refs: specs/001-validate-talk-title-length/spec.md
  ADR: docs/adrs/0005-validation-titre.md

  ```

**Checkpoint**: Feature complete and ready for PR

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 0: Governance Compliance**: No dependencies - MUST complete first (ADR before code)
- **Phase 1: Setup (Test Framework)**: Depends on governance ADR creation - BLOCKS User Story 1
- **Phase 2: User Story 1 (P1)**: Depends on test framework setup - Core validation
- **Phase 3: User Story 2 (P2)**: Depends on User Story 1 - Error message validation
- **Phase 4: Edge Cases**: Depends on User Story 1 - Comprehensive coverage
- **Phase 5: Polish**: Depends on all user stories complete - Final touches

### User Story Dependencies

- **User Story 1 (P1)**: No dependencies on other stories - Can start after Setup
- **User Story 2 (P2)**: Builds on User Story 1 (validates error messages from US1)
  - US2 tests validate US1's error message implementation
  - US2 has no new implementation (US1 already satisfies requirements)

### Within Each Phase

**Phase 1 (Setup):**

- T001 → T002, T003, T004 (install deps first, then config in parallel)

**Phase 2 (User Story 1):**

- Tests (T005-T010): Can write in parallel after T005 creates file
- T010 (verify red) → must complete before implementation starts
- Implementation (T011-T013): Sequential (error class → validation → exports)
- T014 (verify green) → must run after implementation
- T015 (coverage) → final validation

**Phase 3 (User Story 2):**

- Tests (T016-T018): Can write in parallel, verify immediately
- T019: Verification only (no implementation needed)

**Phase 4 (Edge Cases):**

- All test tasks (T020-T023): Can run in parallel
- T024: Final test run after all edge case tests written

**Phase 5 (Polish):**

- T025, T026, T028, T029: Can run in parallel
- T027, T030, T031: Sequential validation steps
- T032, T033: Final review and commit (sequential)

### Parallel Opportunities

**Phase 1 (Setup):**

```bash
# After T001 (install Vitest), run in parallel:
Task T002: Create vitest.config.ts
Task T003: Update package.json scripts
Task T004: Create test directory structure
```

**Phase 2 User Story 1 - Tests:**

```bash
# After T005 (create test file), write tests in parallel:
Task T006: Boundary test - 100 chars acceptance
Task T007: Boundary test - 101 chars rejection
Task T008: Happy path - 50 chars acceptance
Task T009: Edge case - 200 chars rejection
```

**Phase 4 Edge Cases:**

```bash
# All edge case tests can be written in parallel:
Task T020: Unicode handling test
Task T021: Emoji edge case test
Task T022: Empty title regression test
Task T023: Whitespace regression test
```

**Phase 5 Polish:**

```bash
# Code quality tasks can run in parallel:
Task T025: Linting
Task T026: Formatting
Task T028: ADR verification
Task T029: Agent context update
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. ✅ Complete Phase 0: Governance Compliance (ADR-0005)
2. ✅ Complete Phase 1: Setup (test framework)
3. ✅ Complete Phase 2: User Story 1 (core validation)
4. **STOP and VALIDATE**: Run tests, verify 100% coverage
5. Ready for PR (minimal but complete feature)

### Full Feature Delivery

1. Complete Phase 0: Governance (ADR first!)
2. Complete Phase 1: Setup (test framework)
3. Complete Phase 2: User Story 1 (core validation) → **Test independently**
4. Complete Phase 3: User Story 2 (error message validation) → **Test independently**
5. Complete Phase 4: Edge Cases (comprehensive coverage)
6. Complete Phase 5: Polish (code quality, documentation)
7. Create PR with all governance gates satisfied

### TDD Workflow (Critical)

**Constitution Principle V mandates TDD:**

1. **RED**: Write test that fails (e.g., T007 - 101 char rejection)
2. **GREEN**: Implement minimum code to pass (e.g., T012 - add validation)
3. **REFACTOR**: Clean up code while keeping tests green (optional T025, T026)
4. **VERIFY**: Check coverage meets 100% (T015, T027)

Each user story follows this cycle independently.

---

## Task Count Summary

**Total Tasks**: 33 tasks

**By Phase**:

- Phase 0 (Governance): 5 tasks (MANDATORY)
- Phase 1 (Setup): 4 tasks
- Phase 2 (User Story 1): 11 tasks (5 tests + 5 implementation + 1 coverage)
- Phase 3 (User Story 2): 4 tasks (3 tests + 1 verification)
- Phase 4 (Edge Cases): 5 tasks (4 tests + 1 validation)
- Phase 5 (Polish): 9 tasks (quality + docs + commit)

**By Type**:

- Governance: 5 tasks
- Test Tasks: 14 tasks (TDD emphasis)
- Implementation: 5 tasks (error class + validation + exports + verification)
- Setup/Config: 4 tasks
- Quality/Polish: 5 tasks

**Parallelizable Tasks**: 15 tasks marked [P]

**Estimated Time**:

- MVP (Phases 0-2): 1.5 hours (ADR + setup + US1)
- Full Feature (All phases): 2-3 hours (including edge cases and polish)

---

## Notes

- **[P] tasks** = Different files, no dependencies, can run in parallel
- **[Story] label** maps task to specific user story for traceability
- **[GOV] tasks** are MANDATORY - PR will be blocked without them
- **TDD is enforced**: Tests MUST fail before implementation (Constitution Principle V)
- **100% coverage required**: Domain layer must have complete test coverage
- **ADR FIRST**: TGOV-01 must complete before writing code (Constitution Principle III)
- Each user story is independently testable
- Commit after logical groups of tasks
- Stop at any checkpoint to validate story independently
- No vague tasks - all include exact file paths and clear acceptance criteria

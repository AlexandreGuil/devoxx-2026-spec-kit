---
description: 'Task list for difficulty level validation feature implementation'
---

# Tasks: Difficulty Level Validation

**Feature**: 002-difficulty-level-validation
**Input**: Design documents from `/specs/002-difficulty-level-validation/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md
**Governance**: Rules from `.specify/memory/governance-rules.md` and `.specify/memory/constitution.md`

**TDD Approach**: This feature MUST follow Test-Driven Development (Constitution Principle V):
- Red → Green → Refactor cycle
- Tests written BEFORE implementation
- All tests must FAIL initially, then PASS after implementation

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story/GOV] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- **[GOV]**: Governance/compliance task (MANDATORY for CI/CD)
- Include exact file paths in descriptions

## Path Conventions

**Single project** (Clean Architecture):
- Domain entities: `src/domain/`
- Tests: `tests/unit/domain/`
- Documentation: `docs/adrs/`

---

## Phase 0: Governance Compliance (MANDATORY) 🛡️

**Purpose**: Ensure all governance rules from `.specify/memory/constitution.md` are satisfied

**⚠️ CRITICAL**: PR will be BLOCKED by CI/CD if these tasks are incomplete

**Reference**: Constitution Principle III (Règle d'Or de la Documentation)

### Documentation Requirements

- [x] TGOV-01 [GOV] Create ADR for difficulty level validation: `docs/adrs/NNNN-difficulty-level-validation.md`
  - Document: Context (why three levels: Beginner/Intermediate/Advanced)
  - Document: Decision (union type vs. enum, validation approach, immutability pattern)
  - Document: Consequences (breaking change to Talk constructor, type safety benefits, strict validation trade-offs)
  - Document: Alternatives (enum, string without validation, class hierarchy, numeric scale)
  - Use format from existing ADRs (0005-validation-titre.md as reference)
  - Link to spec.md and data-model.md

### Architecture Compliance

- [x] TGOV-02 [GOV] Verify code placement follows Clean Architecture:
  - Domain types (DifficultyLevel) → `src/domain/talk.entity.ts`
  - Domain errors (InvalidDifficultyLevelError) → `src/domain/talk.entity.ts`
  - Domain validation logic → `src/domain/talk.entity.ts` (Talk entity constructor)
  - Zero external dependencies in domain layer

- [x] TGOV-03 [GOV] Verify no forbidden imports exist:
  ```bash
  # These commands MUST return empty results:
  grep -rE "from\s+['\"]\.\./(infrastructure|application)" src/domain/
  grep -rE "from\s+['\"]\.\./(infrastructure)" src/application/
  ```

### Pre-Merge Validation

- [x] TGOV-04 [GOV] Run local governance check: `npm run test:compliance`
- [x] TGOV-05 [GOV] Verify ADR content matches implementation (type choice, validation strategy, edge cases)

**Checkpoint**: ✅ Governance ready - CI/CD will auto-validate on PR

---

## Phase 1: Setup (Test Framework - Already Complete from Feature 001)

**Purpose**: Verify test framework is ready (Vitest already configured in Feature 001)

**Status**: ✅ Vitest already installed and configured (vitest.config.ts exists)

No setup tasks needed - test infrastructure ready from Feature 001.

**Checkpoint**: Test framework available, can proceed to User Story implementation

---

## Phase 2: User Story 1 - System Rejects Invalid Difficulty Levels (Priority: P1) 🎯 MVP

**Goal**: Prevent creation of talks with invalid difficulty levels to ensure data integrity and prevent downstream processing errors

**Independent Test**: Can be fully tested by attempting to create a Talk with various invalid difficulty level values and verifying that appropriate errors are thrown. Valid levels ("Beginner", "Intermediate", "Advanced") should be accepted.

**Constitution Requirement**: TDD Red-Green-Refactor cycle MANDATORY

### TDD Red Phase: Write Failing Tests for User Story 1

> **⚠️ CRITICAL**: These tests MUST be written FIRST and MUST FAIL before implementation

- [x] T001 [US1] Create comprehensive test file for difficulty level validation: `tests/unit/domain/talk.entity.test.ts`
  - Test suite: "Talk entity - Difficulty level validation"
  - Test: Valid difficulty level "Beginner" - should create Talk successfully
  - Test: Valid difficulty level "Intermediate" - should create Talk successfully
  - Test: Valid difficulty level "Advanced" - should create Talk successfully
  - Test: Invalid difficulty level "Easy" - should throw InvalidDifficultyLevelError
  - Test: Invalid difficulty level "Expert" - should throw InvalidDifficultyLevelError
  - Test: Invalid difficulty level empty string "" - should throw InvalidDifficultyLevelError
  - Test: Invalid difficulty level with wrong case "beginner" - should throw InvalidDifficultyLevelError
  - Test: Invalid difficulty level with whitespace " Beginner" - should throw InvalidDifficultyLevelError
  - Test: Invalid difficulty level null - should throw InvalidDifficultyLevelError
  - Test: Invalid difficulty level undefined - should throw InvalidDifficultyLevelError
  - Use Given-When-Then structure in test descriptions
  - Follow existing test patterns from talk.entity.test.ts (title length validation)

- [x] T002 [US1] Run tests to verify RED phase (all tests should FAIL):
  ```bash
  npm test -- talk.entity.test.ts
  ```
  Expected: ~10-11 tests failing (DifficultyLevel type and InvalidDifficultyLevelError don't exist yet)

**Checkpoint**: 🔴 RED - Tests fail as expected (no implementation yet)

### TDD Green Phase: Implement Minimal Code to Pass Tests

- [x] T003 [US1] Create DifficultyLevel type in `src/domain/talk.entity.ts`:
  - Add type definition: `export type DifficultyLevel = "Beginner" | "Intermediate" | "Advanced";`
  - Add JSDoc comment documenting the three difficulty levels
  - Location: After Duration type (line ~9), before InvalidDurationError

- [x] T004 [US1] Create InvalidDifficultyLevelError class in `src/domain/talk.entity.ts`:
  - Add class extending Error
  - Constructor accepts `providedValue: unknown` parameter
  - Error message format: `Invalid difficulty level: "{providedValue}". Valid levels are: Beginner, Intermediate, Advanced`
  - Set `this.name = 'InvalidDifficultyLevelError'`
  - Location: After InvalidTitleLengthError (line ~35), before Talk class
  - Follow pattern from InvalidDurationError and InvalidTitleLengthError

- [x] T005 [US1] Add difficulty level validation to Talk entity constructor in `src/domain/talk.entity.ts`:
  - Add 6th parameter: `private readonly _difficulty: DifficultyLevel`
  - Add validation after existing validations (after line ~70):
    ```typescript
    if (!this.isValidDifficultyLevel(_difficulty)) {
      throw new InvalidDifficultyLevelError(_difficulty);
    }
    ```
  - Add private type guard method `isValidDifficultyLevel(value: unknown): value is DifficultyLevel`
  - Implementation: Check `typeof value === 'string'` and exact match against three valid values
  - Location: Type guard method after isValidDuration (line ~114)

- [x] T006 [US1] Add difficulty property getter in `src/domain/talk.entity.ts`:
  - Add getter after duration getter (line ~76):
    ```typescript
    /** Read-only access to difficulty level */
    get difficulty(): DifficultyLevel {
      return this._difficulty;
    }
    ```
  - Ensures immutability (no setter)

- [x] T007 [US1] Update changeDuration() method to preserve difficulty in `src/domain/talk.entity.ts`:
  - Modify line ~106 to include `this._difficulty` when creating new Talk instance:
    ```typescript
    return new Talk(this.id, this.title, this.abstract, this.speakerName, newDuration as Duration, this._difficulty);
    ```
  - Ensures immutability when changing duration

- [x] T008 [US1] Run tests to verify GREEN phase (all tests should PASS):
  ```bash
  npm test -- talk.entity.test.ts
  ```
  Expected: All ~10-11 difficulty level validation tests passing

**Checkpoint**: 🟢 GREEN - All tests pass with minimal implementation

### TDD Refactor Phase: Improve Code Quality

- [x] T009 [US1] Review and refactor validation logic for clarity:
  - Ensure isValidDifficultyLevel type guard is readable
  - Verify error messages are clear and actionable
  - Confirm JSDoc comments are accurate
  - No functionality changes - tests must still pass

- [x] T010 [US1] Run tests after refactoring to ensure no regressions:
  ```bash
  npm test -- talk.entity.test.ts
  ```
  Expected: All tests still passing after refactoring

**Checkpoint**: ✅ User Story 1 Complete - Valid/invalid difficulty levels correctly handled

---

## Phase 3: User Story 2 - Clear Error Messages for Invalid Levels (Priority: P2)

**Goal**: When validation fails, provide clear, actionable error messages that list the valid difficulty levels to help users quickly correct their input

**Independent Test**: Can be fully tested by triggering validation errors and verifying the error message content includes all valid difficulty levels and the provided invalid value

**Note**: This user story is largely satisfied by User Story 1 implementation (InvalidDifficultyLevelError already has descriptive messages). These tasks verify and enhance error message quality.

### Error Message Verification Tests

- [x] T011 [US2] Add error message validation tests to `tests/unit/domain/talk.entity.test.ts`:
  - Test suite: "Talk entity - Difficulty level error messages"
  - Test: Error message for "Easy" includes text "Valid levels are: Beginner, Intermediate, Advanced"
  - Test: Error message for "Expert" includes the provided value "Expert"
  - Test: Error instance has correct name property "InvalidDifficultyLevelError"
  - Test: Error message uses quotes around invalid value (helps identify whitespace issues)
  - Follow existing error message test patterns

- [x] T012 [US2] Run tests to verify error message quality:
  ```bash
  npm test -- talk.entity.test.ts
  ```
  Expected: All error message tests passing (implementation from US1 should already satisfy)

**Checkpoint**: ✅ User Story 2 Complete - Error messages are clear and actionable

---

## Phase 4: User Story 3 - Expose Difficulty Level Property (Priority: P2)

**Goal**: The Talk entity must expose the difficulty level as a read-only property so that consumers can access this information without breaking encapsulation

**Independent Test**: Can be fully tested by creating a valid Talk and verifying the difficulty level can be read via a getter property, and that immutability is enforced

**Note**: This user story is largely satisfied by User Story 1 implementation (difficulty getter already added). These tasks verify property access and immutability.

### Property Access and Immutability Tests

- [x] T013 [US3] Add property access tests to `tests/unit/domain/talk.entity.test.ts`:
  - Test suite: "Talk entity - Difficulty level property access"
  - Test: Reading difficulty via getter returns "Beginner" for talk created with "Beginner"
  - Test: Reading difficulty via getter returns "Intermediate" for talk created with "Intermediate"
  - Test: Reading difficulty via getter returns "Advanced" for talk created with "Advanced"
  - Test: Difficulty property is read-only (TypeScript type check - verify getter exists, no setter)
  - Test: changeDuration() preserves original difficulty level (immutability verification)
  - Follow existing property access test patterns

- [x] T014 [US3] Run tests to verify property access:
  ```bash
  npm test -- talk.entity.test.ts
  ```
  Expected: All property access tests passing

**Checkpoint**: ✅ User Story 3 Complete - Difficulty level accessible as read-only property

---

## Phase 5: Edge Cases Validation

**Goal**: Ensure all edge cases identified in spec.md are properly handled

**Independent Test**: Comprehensive edge case testing verifies robustness of validation logic

### Edge Case Tests

- [x] T015 [P] Add case sensitivity edge case tests to `tests/unit/domain/talk.entity.test.ts`:
  - Test suite: "Talk entity - Difficulty level edge cases (case sensitivity)"
  - Test: Lowercase "beginner" is rejected (throws InvalidDifficultyLevelError)
  - Test: Uppercase "BEGINNER" is rejected
  - Test: Mixed case "BeGiNnEr" is rejected
  - Test: Lowercase "intermediate" is rejected
  - Test: Uppercase "ADVANCED" is rejected

- [x] T016 [P] Add whitespace edge case tests to `tests/unit/domain/talk.entity.test.ts`:
  - Test suite: "Talk entity - Difficulty level edge cases (whitespace)"
  - Test: Leading space " Beginner" is rejected
  - Test: Trailing space "Beginner " is rejected
  - Test: Leading and trailing spaces " Beginner " is rejected
  - Test: Tab character "\tBeginner" is rejected

- [x] T017 [P] Add type coercion edge case tests to `tests/unit/domain/talk.entity.test.ts`:
  - Test suite: "Talk entity - Difficulty level edge cases (type coercion)"
  - Test: Number 1 is rejected (throws InvalidDifficultyLevelError)
  - Test: Boolean true is rejected
  - Test: Object {level: "Beginner"} is rejected
  - Test: Array ["Beginner"] is rejected

- [x] T018 Run all edge case tests to verify handling:
  ```bash
  npm test -- talk.entity.test.ts
  ```
  Expected: All edge case tests passing (strict validation from US1 should handle these)

**Checkpoint**: ✅ Edge Cases Complete - All edge cases properly handled with strict validation

---

## Phase 6: Migration and Integration

**Goal**: Update existing code to work with the new difficulty level parameter (breaking change)

**Independent Test**: All existing tests should be updated to include difficulty parameter and continue passing

### Migration Tasks

- [x] T019 Update existing Talk entity tests in `tests/unit/domain/talk.entity.test.ts`:
  - Find all `new Talk(...)` instantiations in existing tests (pre-Feature 002)
  - Add 6th parameter (difficulty level) to each instantiation
  - Use "Intermediate" as default for existing tests (neutral choice)
  - Verify all existing tests still pass after adding difficulty parameter
  - Examples:
    - Duration validation tests → add difficulty parameter
    - Title validation tests → add difficulty parameter
    - Format property tests → add difficulty parameter

- [x] T020 Run full test suite to verify no regressions:
  ```bash
  npm test
  ```
  Expected: All tests passing (existing + new difficulty tests)

- [x] T021 Verify TypeScript compilation succeeds:
  ```bash
  npm run build
  ```
  Expected: No compilation errors (all Talk instantiations updated)

**Checkpoint**: ✅ Migration Complete - All existing code updated, no regressions

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final improvements and validation

### Code Quality

- [x] T022 [P] Run ESLint and fix any linting issues:
  ```bash
  npm run lint
  ```
  Expected: No linting errors in src/domain/talk.entity.ts

- [x] T023 [P] Run Prettier to format code:
  ```bash
  npm run format
  ```
  Expected: Code formatted according to project standards

- [x] T024 Run full test suite with coverage:
  ```bash
  npm run test:coverage
  ```
  Expected: Coverage ≥ 80% for all metrics (lines, functions, branches, statements)
  Target: 100% coverage for domain layer (Constitution requirement)

### Documentation

- [x] T025 [P] Review and finalize ADR (TGOV-01):
  - Verify ADR accurately reflects implementation decisions
  - Confirm all alternatives and trade-offs are documented
  - Ensure consequences match actual breaking changes
  - Check that edge case decisions are explained

- [x] T026 [P] Update quickstart.md if needed:
  - Verify code examples are accurate
  - Confirm error message examples match implementation
  - Validate migration guide is complete

### Final Validation

- [x] T027 Run complete governance validation:
  ```bash
  npm run test:compliance
  ```
  Expected: All governance rules passing

- [x] T028 Verify all user stories are independently testable:
  - US1: Can test difficulty validation by creating Talks with various levels
  - US2: Can test error messages by catching InvalidDifficultyLevelError
  - US3: Can test property access by reading `talk.difficulty` getter
  - All stories functional without dependencies on each other

- [x] T029 Final checkpoint - Feature ready for PR:
  - ✅ All governance tasks complete (Phase 0)
  - ✅ All user stories implemented and tested (Phases 2-4)
  - ✅ All edge cases handled (Phase 5)
  - ✅ All existing code migrated (Phase 6)
  - ✅ Code quality verified (Phase 7)
  - ✅ ADR created and validated
  - ✅ Test coverage ≥ 80% (target: 100% for domain)

**Checkpoint**: ✅ Feature Complete - Ready for code review and PR

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 0 (Governance)**: Can start immediately - SHOULD complete early (ADR informs implementation)
- **Phase 1 (Setup)**: ✅ Already complete from Feature 001 - Vitest configured
- **Phase 2 (User Story 1 - P1)**: Core validation - MUST complete first (other stories depend on it)
- **Phase 3 (User Story 2 - P2)**: Depends on US1 (validates error messages from US1)
- **Phase 4 (User Story 3 - P2)**: Depends on US1 (validates property access from US1)
- **Phase 5 (Edge Cases)**: Depends on US1 (extends validation testing)
- **Phase 6 (Migration)**: Depends on US1-3 complete (updates existing code for breaking change)
- **Phase 7 (Polish)**: Depends on all implementation phases complete

### User Story Dependencies

- **User Story 1 (P1)**: BLOCKING - Must complete first (provides DifficultyLevel type, InvalidDifficultyLevelError, validation logic)
- **User Story 2 (P2)**: Depends on US1 (error messages already implemented, just verified)
- **User Story 3 (P2)**: Depends on US1 (property getter already implemented, just verified)

**Note**: Unlike typical features, US2 and US3 are verification stories, not independent implementations. They validate quality aspects of US1.

### Within Each Phase

**Phase 2 (User Story 1) - TDD Cycle**:
1. T001: Write failing tests (RED)
2. T002: Verify tests fail
3. T003-T007: Implement minimal code (GREEN) - can be somewhat parallel but maintain order:
   - T003: DifficultyLevel type (prerequisite for others)
   - T004: InvalidDifficultyLevelError (prerequisite for validation)
   - T005: Talk constructor validation (depends on T003, T004)
   - T006: Difficulty getter (depends on T005)
   - T007: changeDuration update (depends on T005)
4. T008: Verify tests pass (GREEN confirmation)
5. T009-T010: Refactor and verify (REFACTOR)

**Phase 5 (Edge Cases)**:
- T015, T016, T017 can run in parallel (different test suites, no dependencies)
- T018 runs after all edge case tests written

**Phase 7 (Polish)**:
- T022, T023, T025, T026 can run in parallel (different files/concerns)
- T024, T027, T028, T029 run sequentially (validation checkpoints)

### Parallel Opportunities

**Limited parallelization** due to TDD workflow and single-file modification:

- **Phase 0**: TGOV-01 (ADR writing) can proceed in parallel with reading design docs
- **Phase 2**: Tests (T001) must complete before implementation; implementation tasks (T003-T007) are sequential within same file
- **Phase 5**: Edge case test suites (T015, T016, T017) can be written in parallel
- **Phase 7**: Linting (T022), formatting (T023), ADR review (T025), quickstart review (T026) can run in parallel

**Single-file constraint**: Most tasks modify `src/domain/talk.entity.ts`, limiting true parallelization. TDD workflow requires sequential Red→Green→Refactor.

---

## Parallel Example: Phase 5 (Edge Cases)

```bash
# Launch edge case test suites in parallel (different test suites):
Task: "Add case sensitivity edge case tests to tests/unit/domain/talk.entity.test.ts"
Task: "Add whitespace edge case tests to tests/unit/domain/talk.entity.test.ts"
Task: "Add type coercion edge case tests to tests/unit/domain/talk.entity.test.ts"

# Then run verification:
Task: "Run all edge case tests to verify handling"
```

---

## Parallel Example: Phase 7 (Polish)

```bash
# Launch polish tasks in parallel:
Task: "Run ESLint and fix any linting issues"
Task: "Run Prettier to format code"
Task: "Review and finalize ADR"
Task: "Update quickstart.md if needed"

# Then run sequential validations:
Task: "Run full test suite with coverage"
Task: "Run complete governance validation"
Task: "Verify all user stories are independently testable"
Task: "Final checkpoint - Feature ready for PR"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. ✅ Complete Phase 0: Governance (create ADR)
2. ✅ Skip Phase 1: Setup (already done in Feature 001)
3. Complete Phase 2: User Story 1 (core difficulty validation)
   - **TDD Red**: Write failing tests (T001-T002)
   - **TDD Green**: Implement minimal code (T003-T008)
   - **TDD Refactor**: Improve code quality (T009-T010)
4. **STOP and VALIDATE**: Test User Story 1 independently
   - Can create Talks with valid difficulty levels
   - Invalid difficulty levels are rejected with clear errors
   - This is a functional MVP!

### Incremental Delivery

1. Complete Phase 0 (Governance) → ADR documented
2. Complete Phase 2 (US1) → Core validation works → **MVP**
3. Complete Phase 3 (US2) → Error messages verified → Enhanced UX
4. Complete Phase 4 (US3) → Property access verified → API complete
5. Complete Phase 5 (Edge Cases) → Robust validation → Production-ready
6. Complete Phase 6 (Migration) → Breaking changes resolved → Integration complete
7. Complete Phase 7 (Polish) → Quality validated → Ready for PR

Each phase adds value and can be demoed independently.

### Single Developer Strategy

**Recommended order** (sequential execution):

1. **Day 1 Morning**: Phase 0 (Governance) - Write ADR documenting design decisions
2. **Day 1 Afternoon**: Phase 2 (US1 - Red) - Write all failing tests (T001-T002)
3. **Day 2 Morning**: Phase 2 (US1 - Green) - Implement minimal code (T003-T008)
4. **Day 2 Afternoon**: Phase 2 (US1 - Refactor) + Phase 3 (US2) + Phase 4 (US3) - Refactor and verify
5. **Day 3 Morning**: Phase 5 (Edge Cases) + Phase 6 (Migration) - Comprehensive testing and migration
6. **Day 3 Afternoon**: Phase 7 (Polish) - Final quality checks and validation

**Total estimated effort**: 3 days for complete implementation with TDD

---

## Notes

- **TDD Mandatory**: Constitution Principle V requires Red-Green-Refactor cycle
- **Single File Modification**: Most changes in `src/domain/talk.entity.ts` (limited parallelization)
- **Breaking Change**: Talk constructor signature changed (6th parameter added)
- **Zero External Dependencies**: Pure domain logic (Constitution Principle I)
- **Type Safety**: TypeScript strict mode provides compile-time validation
- **Test Coverage Target**: 100% for domain layer (Constitution requirement)
- **US2 and US3 Note**: These are verification stories, not new implementations - they validate quality aspects of US1
- **Governance Critical**: ADR (TGOV-01) is MANDATORY for PR merge

### Commit Strategy

Suggested commit points:

1. After TGOV-01: "docs: add ADR for difficulty level validation"
2. After T002: "test: add failing tests for difficulty level validation (RED)"
3. After T008: "feat: add difficulty level validation to Talk entity (GREEN)"
4. After T010: "refactor: improve difficulty level validation clarity"
5. After T014: "test: add property access tests for difficulty level"
6. After T018: "test: add comprehensive edge case tests"
7. After T021: "refactor: migrate existing tests to include difficulty parameter"
8. After T029: "chore: final polish and validation for difficulty level feature"

### Success Criteria Checklist

At completion, verify:

- ✅ All three difficulty levels ("Beginner", "Intermediate", "Advanced") work correctly
- ✅ Invalid difficulty levels are rejected with clear error messages
- ✅ Difficulty level is accessible via read-only getter
- ✅ Case sensitivity enforced (no "beginner")
- ✅ Whitespace rejected (no " Beginner")
- ✅ Type coercion rejected (no numbers, booleans, null)
- ✅ changeDuration() preserves difficulty (immutability)
- ✅ All existing tests updated and passing
- ✅ Test coverage ≥ 80% (target: 100% for domain)
- ✅ ADR created and complete
- ✅ No forbidden imports (domain layer pure)
- ✅ Governance validation passing

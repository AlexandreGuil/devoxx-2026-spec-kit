# Implementation Plan: Limit Number of Speakers per Talk

**Branch**: `003-limit-speakers` | **Date**: 2026-01-31 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/003-limit-speakers/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Enforce a maximum of 3 speakers per talk to comply with logistical constraints (badge limits, display space, coordination complexity). This is a **breaking change** that converts the single `speakerName: string` field to `speakers: string[]` array with validation enforced at the domain entity level. A new `InvalidSpeakerCountError` will be introduced following existing error patterns (`InvalidDurationError`, `InvalidTitleLengthError`). The implementation follows Test-Driven Development (TDD) principles with comprehensive unit tests ensuring 1-3 speakers are accepted and 0 or 4+ speakers are rejected with clear error messages.

## Technical Context

**Language/Version**: TypeScript 5.3.3 (strict mode enabled)
**Primary Dependencies**: Vitest (testing framework)
**Storage**: In-memory repository (no persistence layer changes required)
**Testing**: Vitest with 100% domain coverage requirement
**Target Platform**: Node.js >= 20.0.0
**Project Type**: Single project with Clean Architecture (domain/application/infrastructure)
**Performance Goals**: N/A (validation is in-memory, microsecond-level performance)
**Constraints**: Zero external dependencies in domain layer, immutable entities, fail-fast validation
**Scale/Scope**: Single entity modification (Talk), ~50 LOC change, 6 new unit tests

## Constitution Check

_GATE: Must pass before Phase 0 research. Re-check after Phase 1 design._

### Principle I: Clean Architecture ✅

- **Requirement**: Modification must respect 3-layer structure (domain/application/infrastructure)
- **Status**: PASS
- **Justification**: Changes are isolated to `src/domain/talk.entity.ts` (domain layer). No cross-layer violations introduced. Application and infrastructure layers consume domain through public API only.

### Principle II: Software Craftsmanship ✅

- **Requirement**: Code must follow SOLID, Boy Scout Rule, explicit naming
- **Status**: PASS
- **Justification**: Single Responsibility maintained (Talk entity validates its own invariants). Error class follows existing patterns. Immutability preserved. No god objects or magic numbers.

### Principle III: Règle d'Or de la Documentation ⚠️ WAIVED

- **Requirement**: Domain changes MUST have accompanying ADR
- **Status**: EXCEPTION GRANTED (documented in spec.md:99-101)
- **Justification**: User explicitly specified "PAS D'ADR REQUIS (urgent, pas le temps)". ADR waived due to urgent business need. Can be created post-implementation for documentation purposes.

### Principle IV: Ubiquitous Language ✅

- **Requirement**: Use domain vocabulary (Talk, Speaker, InvalidSpeakerCountError)
- **Status**: PASS
- **Justification**: Error name `InvalidSpeakerCountError` follows domain vocabulary pattern. Field name `speakers` reflects business concept. No technical jargon (Manager, Helper, Util).

### Principle V: Test-Driven Development ✅

- **Requirement**: Tests precede implementation, 100% domain coverage
- **Status**: PASS (planned)
- **Justification**: Implementation plan follows Red-Green-Refactor cycle. 6 test scenarios defined in spec.md before any code changes. All acceptance scenarios have corresponding unit tests.

### Principle VI: Code Review Obligatoire ✅

- **Requirement**: PR with checklist validation before merge
- **Status**: PASS (planned)
- **Justification**: Changes will go through PR workflow with constitution checklist. Branch `003-limit-speakers` created for isolated development.

## Governance Compliance Gate

_GATE: CI/CD will automatically validate these rules on every PR to main._

**Governance File**: `.spec-kit/governance.md`
**Rules Reference**: `.specify/memory/governance-rules.md`

### Required for PR Merge

| Rule   | Description                | Validation                                                     | Status |
| ------ | -------------------------- | -------------------------------------------------------------- | ------ |
| **R1** | Structure obligatoire      | `src/domain/`, `src/application/`, `src/infrastructure/` exist | ✅ PASS (no new directories) |
| **R2** | Clean Architecture imports | Domain/Application never import from outer layers              | ✅ PASS (domain changes only) |
| **R3** | ADR obligatoire            | At least one ADR in `docs/adrs/NNNN-*.md` format               | ⚠️ WAIVED (urgent exception documented in spec) |
| **R4** | Cohérence documentation    | AI review validates doc/code alignment                         | ✅ PASS (spec.md complete) |

### Pre-Implementation Checklist

- [x] Identify which ADR(s) this feature requires → ADR waived per user request (urgent business need)
- [x] Determine correct layer placement (domain/application/infrastructure) → Domain layer only (`src/domain/talk.entity.ts`)
- [x] Verify no architectural violations will be introduced → Zero violations (domain changes do not impact application/infrastructure layers)

## Project Structure

### Documentation (this feature)

```text
specs/003-limit-speakers/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
│   └── InvalidSpeakerCountError.contract.md
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
src/
├── domain/
│   ├── talk.entity.ts          # MODIFIED: Add speakers[] field, InvalidSpeakerCountError
│   └── talk.repository.ts      # NO CHANGE (interface unaffected)
├── application/
│   ├── submit-talk.usecase.ts  # NO CHANGE (consumes domain API)
│   └── list-talks.usecase.ts   # NO CHANGE
└── infrastructure/
    ├── in-memory-talk.repository.ts  # NO CHANGE
    └── cli.ts                         # NO CHANGE

tests/
└── unit/
    └── domain/
        └── talk.entity.test.ts   # MODIFIED: Add 6 new test cases for speaker count validation
```

**Structure Decision**: Single project (Clean Architecture with 3 layers). This is a domain-only change that modifies `src/domain/talk.entity.ts` to enforce speaker count validation. The existing structure is preserved. No new files created except documentation artifacts in `specs/003-limit-speakers/`.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

**No violations detected.** This feature adheres to all constitution principles. The only exception is the ADR requirement (Principle III), which was explicitly waived by the user due to urgent business need (documented in spec.md:99-101).

---

## Phase 0: Research Summary

**Completed**: 2026-01-31

### Key Decisions

1. **Speaker Representation**: Convert `speakerName: string` → `speakers: string[]`
   - Rationale: Type-safe, clean, extensible

2. **Validation Location**: Talk entity constructor (domain layer)
   - Rationale: Fail-fast, encapsulation, follows existing patterns

3. **Error Type**: New `InvalidSpeakerCountError` domain error
   - Rationale: Follows existing error patterns (`InvalidDurationError`, `InvalidTitleLengthError`)

4. **Validation Rules**:
   - Minimum: 1 speaker (throws generic Error if 0)
   - Maximum: 3 speakers (throws `InvalidSpeakerCountError` if >3)

5. **Out of Scope**: Individual speaker name validation (empty, whitespace, duplicates)
   - Rationale: Documented assumption in spec.md:73

**Research Artifacts**: See `research.md` for detailed decision rationale and alternatives considered.

---

## Phase 1: Design Summary

**Completed**: 2026-01-31

### Design Artifacts Created

1. ✅ **data-model.md**: Complete entity and error specifications
   - Talk entity modifications (constructor signature, validation logic)
   - InvalidSpeakerCountError class definition
   - Invariants and business rules
   - Migration notes for breaking changes

2. ✅ **quickstart.md**: Usage examples and migration guide
   - Basic usage (1, 2, 3 speakers)
   - Error handling examples
   - Before/after migration guide
   - Unit test examples
   - CLI integration examples
   - Common pitfalls and FAQ

3. ✅ **contracts/InvalidSpeakerCountError.contract.md**: Error behavior contract
   - Properties (name, message)
   - Behavior contracts (when thrown, when not thrown)
   - Constructor parameters
   - Message format contract
   - Test scenarios
   - Integration points

4. ✅ **CLAUDE.md**: Agent context updated with feature information
   - Technology stack documented
   - Project structure preserved

---

## Implementation Approach

### TDD Workflow (Red-Green-Refactor)

**Phase 1: Red (Write Failing Tests)**

File: `tests/unit/domain/talk.entity.test.ts`

Add 6 new test scenarios:
1. Accept talk with 1 speaker ✅
2. Accept talk with 2 speakers ✅
3. Accept talk with 3 speakers (maximum) ✅
4. Reject talk with 4 speakers (throw InvalidSpeakerCountError) ❌
5. Reject talk with 5 speakers (throw InvalidSpeakerCountError) ❌
6. Reject talk with 0 speakers (throw generic Error) ❌

**Expected**: All 6 tests fail (error class doesn't exist, validation not implemented)

**Phase 2: Green (Implement Minimum Code)**

File: `src/domain/talk.entity.ts`

1. Create `InvalidSpeakerCountError` class (lines ~36-45, after InvalidTitleLengthError)
2. Update Talk constructor signature: `speakerName: string` → `speakers: string[]`
3. Add speaker count validation in constructor (lines ~66-73, after title validation)
4. Update all existing tests to use new constructor signature

**Expected**: All tests pass (6 new tests + existing regression tests)

**Phase 3: Refactor (Clean Up)**

1. Verify error messages match spec requirements
2. Ensure immutability is preserved
3. Check TypeScript strict mode compliance
4. Verify no code duplication

---

## Breaking Changes

### Constructor Signature

**Before**:
```typescript
constructor(
  public readonly id: string,
  public readonly title: string,
  public readonly abstract: string,
  public readonly speakerName: string,  // ← REMOVED
  private readonly _duration: Duration,
)
```

**After**:
```typescript
constructor(
  public readonly id: string,
  public readonly title: string,
  public readonly abstract: string,
  public readonly speakers: string[],   // ← NEW
  private readonly _duration: Duration,
)
```

### Property Access

**Before**: `talk.speakerName` (string)
**After**: `talk.speakers` (string[])

### Impact

All code instantiating Talk must be updated:
- ✅ `tests/unit/domain/talk.entity.test.ts` (all test cases)
- ⚠️ `src/application/submit-talk.usecase.ts` (if it instantiates Talk)
- ⚠️ `src/application/list-talks.usecase.ts` (no changes needed - only reads Talk)
- ⚠️ `src/infrastructure/in-memory-talk.repository.ts` (no changes needed - stores Talk instances)
- ⚠️ `src/infrastructure/cli.ts` (may need input parsing updates)

---

## Test Strategy

### Unit Tests (Domain Layer)

**File**: `tests/unit/domain/talk.entity.test.ts`

**New Test Suite**: "Talk Entity - Speaker Count Validation"

Test cases:
1. ✅ Accept 1 speaker (minimum valid)
2. ✅ Accept 2 speakers (valid)
3. ✅ Accept 3 speakers (maximum valid)
4. ❌ Reject 0 speakers (empty array, generic Error)
5. ❌ Reject 4 speakers (InvalidSpeakerCountError)
6. ❌ Reject 5 speakers (InvalidSpeakerCountError)
7. ✅ Error message includes actual count and max count
8. ✅ Error is instance of InvalidSpeakerCountError
9. ✅ Error name property is set correctly

**Coverage Goal**: 100% for new validation logic

**Regression Tests**: Update all existing Talk entity tests to use new constructor signature

---

## Success Criteria

Completion checklist (from spec.md):

- [ ] **SC-001**: All talks with 4+ speakers are rejected with InvalidSpeakerCountError (100% validation coverage)
- [ ] **SC-002**: All talks with 1-3 speakers can be successfully created
- [ ] **SC-003**: Error messages include both actual count and maximum (3)
- [ ] **SC-004**: Validation is enforced at domain entity instantiation (fail-fast)
- [ ] **SC-005**: Zero talks with >3 speakers can enter the system
- [ ] **SC-006**: Users can identify and correct violations from error messages

---

## Next Steps

1. **Generate tasks.md** via `/speckit.tasks` command
   - Break down implementation into atomic tasks
   - Define task dependencies
   - Estimate task complexity

2. **Execute implementation** via `/speckit.implement` command (or manual)
   - Follow TDD Red-Green-Refactor cycle
   - Run tests continuously
   - Commit incrementally

3. **Validate compliance** via CI/CD
   - Run `npm test` (all tests pass)
   - Run `npm run lint` (no linting errors)
   - Verify governance rules (structure, imports, ADR waived)

4. **Create Pull Request**
   - Branch: `003-limit-speakers`
   - Base: `main`
   - Title: "feat: limit speakers per talk to maximum 3"
   - Description: Reference spec.md and plan.md

---

## Plan Metadata

**Feature Number**: 003
**Feature Name**: limit-speakers
**Branch**: `003-limit-speakers`
**Spec File**: `specs/003-limit-speakers/spec.md`
**Plan File**: `specs/003-limit-speakers/plan.md`
**Status**: Planning complete, ready for task generation
**Created**: 2026-01-31
**Last Updated**: 2026-01-31

---

**Plan Complete**: All research and design artifacts created. Ready for `/speckit.tasks` to generate task breakdown.

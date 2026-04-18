# Implementation Plan: Validate Abstract Length

**Branch**: `004-validate-abstract-length` | **Date**: 2026-01-31 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/004-validate-abstract-length/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Enforce a maximum of 500 characters for talk abstracts to prevent display issues on mobile applications. This validation follows the same pattern as existing title length validation (`InvalidTitleLengthError`). A new `InvalidAbstractLengthError` domain error will be introduced with validation enforced at the Talk entity constructor level, following TDD principles and the existing codebase patterns.

## Technical Context

**Language/Version**: TypeScript 5.3.3 (strict mode enabled)
**Primary Dependencies**: Vitest (testing framework)
**Storage**: In-memory repository (no persistence layer changes required)
**Testing**: Vitest with 100% domain coverage requirement
**Target Platform**: Node.js >= 20.0.0
**Project Type**: Single project with Clean Architecture (domain/application/infrastructure)
**Performance Goals**: N/A (validation is in-memory, microsecond-level performance)
**Constraints**: Zero external dependencies in domain layer, immutable entities, fail-fast validation
**Scale/Scope**: Single entity modification (Talk), ~30 LOC change, 5 new unit tests

## Constitution Check

_GATE: Must pass before Phase 0 research. Re-check after Phase 1 design._

### Principe I: Clean Architecture ✅

- **Requirement**: Modification must respect 3-layer structure (domain/application/infrastructure)
- **Status**: PASS
- **Justification**: Changes are isolated to `src/domain/talk.entity.ts` (domain layer). No cross-layer violations introduced. Application and infrastructure layers consume domain through public API only.

### Principe II: Software Craftsmanship ✅

- **Requirement**: Code must follow SOLID, Boy Scout Rule, explicit naming
- **Status**: PASS
- **Justification**: Single Responsibility maintained (Talk entity validates its own invariants). Error class follows existing patterns (`InvalidTitleLengthError`). Immutability preserved. No god objects or magic numbers.

### Principe III: Règle d'Or de la Documentation ✅

- **Requirement**: Domain changes MUST have accompanying ADR
- **Status**: PASS
- **Justification**: ADR required at `docs/adrs/0007-validate-abstract-length.md`. Will document mobile display constraints, 500 character limit decision, and alternatives considered.

### Principe IV: Ubiquitous Language ✅

- **Requirement**: Use domain vocabulary (Talk, Abstract, InvalidAbstractLengthError)
- **Status**: PASS
- **Justification**: Error name `InvalidAbstractLengthError` follows domain vocabulary pattern. Consistent with `InvalidTitleLengthError`. No technical jargon.

### Principe V: Test-Driven Development ✅

- **Requirement**: Tests precede implementation, 100% domain coverage
- **Status**: PASS (planned)
- **Justification**: Implementation plan follows Red-Green-Refactor cycle. 5 test scenarios defined in spec.md before any code changes. All acceptance scenarios have corresponding unit tests.

### Principe VI: Code Review Obligatoire ✅

- **Requirement**: PR with checklist validation before merge
- **Status**: PASS (planned)
- **Justification**: Changes will go through PR workflow with constitution checklist. Branch `004-validate-abstract-length` created for isolated development.

## Governance Compliance Gate

_GATE: CI/CD will automatically validate these rules on every PR to main._

**Governance File**: `.spec-kit/governance.md`
**Rules Reference**: `.specify/memory/governance-rules.md`

### Required for PR Merge

| Rule   | Description                | Validation                                                     | Status |
| ------ | -------------------------- | -------------------------------------------------------------- | ------ |
| **R1** | Structure obligatoire      | `src/domain/`, `src/application/`, `src/infrastructure/` exist | ✅ PASS (no new directories) |
| **R2** | Clean Architecture imports | Domain/Application never import from outer layers              | ✅ PASS (domain changes only) |
| **R3** | ADR obligatoire            | At least one ADR in `docs/adrs/NNNN-*.md` format               | ⚠️ REQUIRED (will be created) |
| **R4** | Cohérence documentation    | AI review validates doc/code alignment                         | ✅ PASS (spec.md complete) |

### Pre-Implementation Checklist

- [x] Identify which ADR(s) this feature requires → ADR 0007 for abstract length limit decision
- [x] Determine correct layer placement (domain/application/infrastructure) → Domain layer only (`src/domain/talk.entity.ts`)
- [x] Verify no architectural violations will be introduced → Zero violations (domain changes do not impact application/infrastructure layers)

## Project Structure

### Documentation (this feature)

```text
specs/004-validate-abstract-length/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
│   └── InvalidAbstractLengthError.contract.md
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
src/
├── domain/
│   ├── talk.entity.ts          # MODIFIED: Add InvalidAbstractLengthError, abstract validation
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
        └── talk.entity.test.ts   # MODIFIED: Add 5 new test cases for abstract length validation
```

**Structure Decision**: Single project (Clean Architecture with 3 layers). This is a domain-only change that modifies `src/domain/talk.entity.ts` to enforce abstract length validation. The existing structure is preserved. No new files created except documentation artifacts in `specs/004-validate-abstract-length/`.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

**No violations detected.** This feature adheres to all constitution principles. ADR will be created as required by Principle III.

---

## Phase 0: Research Summary

**Completed**: 2026-01-31

### Key Decisions

1. **Validation Location**: Talk entity constructor (domain layer)
   - Rationale: Fail-fast, encapsulation, follows existing patterns

2. **Error Pattern**: New `InvalidAbstractLengthError` domain error
   - Rationale: Follows existing error patterns (`InvalidTitleLengthError`, `InvalidSpeakerCountError`)

3. **Character Limit**: 500 characters maximum
   - Rationale: Mobile display constraints, business requirement

4. **Character Counting**: JavaScript's native `string.length` (UTF-16 code units)
   - Rationale: Consistent with title validation, zero dependencies

5. **No Minimum Length**: Validation only enforces maximum
   - Rationale: Out of scope, documented assumption

6. **Validation Order**: After title validation, before speaker validation
   - Rationale: Logical grouping of length validations

**Research Artifacts**: See `research.md` for detailed decision rationale and alternatives considered.

---

## Phase 1: Design Summary

**Completed**: 2026-01-31

### Design Artifacts Created

1. ✅ **data-model.md**: Complete entity and error specifications
   - Talk entity modifications (abstract length validation)
   - InvalidAbstractLengthError class definition
   - Invariants and business rules
   - Character counting behavior

2. ✅ **quickstart.md**: Usage examples and testing guide
   - Basic usage (400, 500 character abstracts)
   - Error handling examples
   - TDD workflow (Red-Green-Refactor)
   - Unit test examples (11 test cases)
   - Common pitfalls and FAQ

3. ✅ **contracts/InvalidAbstractLengthError.contract.md**: Error behavior contract
   - Properties (name, message)
   - Behavior contracts (when thrown, when not thrown)
   - Constructor parameters
   - Message format contract
   - Test scenarios and invariants
   - Integration points

4. ✅ **CLAUDE.md**: Agent context updated with feature information
   - Technology stack documented
   - Project structure preserved

---

## Implementation Approach

### TDD Workflow (Red-Green-Refactor)

**Phase 1: Red (Write Failing Tests)**

File: `tests/unit/domain/talk.entity.test.ts`

Add 5 new test scenarios:
1. Accept talk with 400-character abstract ✅
2. Accept talk with exactly 500 characters (maximum) ✅
3. Reject talk with 501-character abstract (throw InvalidAbstractLengthError) ❌
4. Reject talk with 600-character abstract (throw InvalidAbstractLengthError) ❌
5. Reject talk with 1000-character abstract (throw InvalidAbstractLengthError) ❌

**Expected**: All 5 tests fail (error class doesn't exist, validation not implemented)

**Phase 2: Green (Implement Minimum Code)**

File: `src/domain/talk.entity.ts`

1. Create `InvalidAbstractLengthError` class (after InvalidSpeakerCountError)
2. Add abstract length validation in constructor (after title validation)
3. Update all existing tests if needed

**Expected**: All tests pass (5 new tests + existing regression tests)

**Phase 3: Refactor (Clean Up)**

1. Verify error messages match spec requirements
2. Ensure validation order is logical
3. Check TypeScript strict mode compliance
4. Verify no code duplication

---

## Impact Analysis

### Files to Modify

**Domain Layer**:
- `src/domain/talk.entity.ts`: Add InvalidAbstractLengthError, add abstract validation (~20 LOC)

**Tests**:
- `tests/unit/domain/talk.entity.test.ts`: Add 5-11 new test cases (~100 LOC)

### Files NOT Modified

**Application Layer**:
- `src/application/submit-talk.usecase.ts`: No changes (consumes domain API)
- `src/application/list-talks.usecase.ts`: No changes

**Infrastructure Layer**:
- `src/infrastructure/in-memory-talk.repository.ts`: No changes
- `src/infrastructure/cli.ts`: No changes

**Total Impact**: 2 files modified, ~120 LOC added

---

## Success Criteria

Completion checklist (from spec.md):

- [ ] **SC-001**: All talks with abstracts exceeding 500 characters are rejected with InvalidAbstractLengthError (100% validation coverage)
- [ ] **SC-002**: All talks with abstracts of 500 characters or fewer can be successfully created
- [ ] **SC-003**: Error messages include both actual length and maximum (500)
- [ ] **SC-004**: Validation is enforced at domain entity instantiation (fail-fast)
- [ ] **SC-005**: Zero talks with abstracts longer than 500 characters can enter the system
- [ ] **SC-006**: Mobile app displays all talk abstracts without layout issues

---

## Next Steps

1. **Create ADR** (required by governance):
   - File: `docs/adrs/0007-validate-abstract-length.md`
   - Content: Mobile display constraints, 500 character limit, alternatives considered

2. **Generate tasks.md** via `/speckit.tasks` command
   - Break down implementation into atomic tasks
   - Define task dependencies
   - Estimate task complexity

3. **Execute implementation** via `/speckit.implement` command (or manual)
   - Follow TDD Red-Green-Refactor cycle
   - Run tests continuously
   - Commit incrementally

4. **Validate compliance** via CI/CD
   - Run `npm test` (all tests pass)
   - Run `npm run lint` (no linting errors)
   - Verify governance rules (structure, imports, ADR)

5. **Create Pull Request**
   - Branch: `004-validate-abstract-length`
   - Base: `main`
   - Title: "feat(domain): validate abstract length (max 500 chars)"
   - Description: Reference spec.md and plan.md

---

## Plan Metadata

**Feature Number**: 004
**Feature Name**: validate-abstract-length
**Branch**: `004-validate-abstract-length`
**Spec File**: `specs/004-validate-abstract-length/spec.md`
**Plan File**: `specs/004-validate-abstract-length/plan.md`
**Status**: Planning complete, ready for task generation
**Created**: 2026-01-31
**Last Updated**: 2026-01-31

---

**Plan Complete**: All research and design artifacts created. Ready for `/speckit.tasks` to generate task breakdown.

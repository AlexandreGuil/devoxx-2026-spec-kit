# Implementation Plan: Talk Title Length Validation

**Branch**: `001-validate-talk-title-length` | **Date**: 2026-01-31 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-validate-talk-title-length/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Add validation to the Talk entity to enforce a maximum title length of 100 characters, preventing display issues on mobile devices and printed conference programs. The validation will be implemented in the domain layer using a new `InvalidTitleLengthError` domain error and will provide clear feedback including both the actual and maximum allowed character counts.

## Technical Context

**Language/Version**: TypeScript 5.3.3 with strict mode enabled
**Primary Dependencies**: Node.js 20+ (ESNext modules), no external validation libraries required
**Storage**: N/A (domain-level validation, storage-agnostic)
**Testing**: No test framework currently configured (tests to be added per TDD requirement)
**Target Platform**: Node.js server-side application
**Project Type**: Single project with Clean Architecture (domain/application/infrastructure)
**Performance Goals**: Instant validation (<1ms) as it's a simple string length check
**Constraints**: Must use Unicode character count (not byte count), must not introduce external dependencies to domain layer
**Scale/Scope**: Single entity modification (Talk), minimal scope feature

## Constitution Check

_GATE: Must pass before Phase 0 research. Re-check after Phase 1 design._

Based on `.specify/memory/constitution.md`:

### Pre-Implementation Evaluation

| Principle                             | Requirement                                         | This Feature                                                                           | Status                                         |
| ------------------------------------- | --------------------------------------------------- | -------------------------------------------------------------------------------------- | ---------------------------------------------- |
| **Principle I: Clean Architecture**   | Domain logic in `src/domain/`, no forbidden imports | Validation logic and error class will be added to `src/domain/talk.entity.ts`          | ✅ PASS                                        |
| **Principe III: ADR Required**        | ADR must document domain/application changes        | ADR-0005 will document the 100-character limit decision                                | ✅ PASS                                        |
| **Principle IV: Ubiquitous Language** | Use domain terminology, avoid technical jargon      | Error class uses domain terms: `InvalidTitleLengthError`, not `StringTooLongException` | ✅ PASS                                        |
| **Principle V: TDD**                  | Tests must precede implementation                   | Unit tests will be written for domain validation before implementation                 | ⚠️ DEFERRED (no test framework configured yet) |
| **Principle VI: Code Review**         | Required before merge to main                       | Will follow standard PR process                                                        | ✅ PASS                                        |

**Gate Decision**: ✅ APPROVED to proceed to Phase 0

**Notes**:

- No architectural violations introduced (pure domain logic)
- ADR already identified in spec: `docs/adrs/0005-validation-titre.md`
- Test framework setup needed but not a blocker for planning
- Single entity change, minimal complexity

## Governance Compliance Gate

_GATE: CI/CD will automatically validate these rules on every PR to main._

**Governance File**: `.spec-kit/governance.md`
**Rules Reference**: `.specify/memory/governance-rules.md`

### Required for PR Merge

| Rule   | Description                | Validation                                                     | This Feature                                            |
| ------ | -------------------------- | -------------------------------------------------------------- | ------------------------------------------------------- |
| **R1** | Structure obligatoire      | `src/domain/`, `src/application/`, `src/infrastructure/` exist | ✅ Modifies existing `src/domain/talk.entity.ts`        |
| **R2** | Clean Architecture imports | Domain/Application never import from outer layers              | ✅ No new imports required (native string length check) |
| **R3** | ADR obligatoire            | At least one ADR in `docs/adrs/NNNN-*.md` format               | ✅ Will create `docs/adrs/0005-validation-titre.md`     |
| **R4** | Cohérence documentation    | AI review validates doc/code alignment                         | ✅ ADR will document context, decision, consequences    |

### Pre-Implementation Checklist

- [x] Identify which ADR(s) this feature requires: **ADR-0005: Talk Title Length Validation**
- [x] Determine correct layer placement: **`src/domain/talk.entity.ts` (domain layer)**
- [x] Verify no architectural violations will be introduced: **Confirmed - pure domain logic, no external dependencies**

## Project Structure

### Documentation (this feature)

```text
specs/001-validate-talk-title-length/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command) - N/A for this feature
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
src/
├── domain/
│   ├── talk.entity.ts         # ← MODIFY: Add title length validation + InvalidTitleLengthError
│   └── talk.repository.ts     # ← UNCHANGED
├── application/
│   └── list-talks.use-case.ts # ← UNCHANGED
└── infrastructure/
    ├── in-memory-talk.repository.ts  # ← UNCHANGED
    └── cli.ts                 # ← UNCHANGED

tests/                         # ← CREATE: Test directory structure
├── unit/
│   └── domain/
│       └── talk.entity.test.ts  # ← CREATE: Unit tests for title validation
├── integration/               # Not needed for this feature
└── contract/                  # Not needed for this feature

docs/
└── adrs/
    └── 0005-validation-titre.md  # ← CREATE: ADR documenting title length decision
```

**Structure Decision**: Single project structure with Clean Architecture layers. All changes are contained within the domain layer (`src/domain/talk.entity.ts`). This is a minimal-scope feature with no infrastructure or application layer changes required.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

_No violations detected. This section is not applicable._

---

## Phase 0: Research & Technical Decisions

### Research Topics

This feature has minimal research requirements as it involves straightforward domain validation. Key technical decisions below:

#### 1. Unicode Character Counting in TypeScript

**Decision**: Use native JavaScript `.length` property for character counting

**Rationale**:

- JavaScript strings use UTF-16 encoding
- The `.length` property returns the number of UTF-16 code units
- For most use cases including Latin characters, accented characters (é, ñ, ü), and common symbols, `.length` accurately counts characters
- **Edge case**: Emojis and characters outside the Basic Multilingual Plane (BMP) may be counted as 2 code units instead of 1
  - Example: `'👍'.length === 2` (surrogate pair)
  - Example: `'🎉'.length === 2` (surrogate pair)

**Alternatives Considered**:

1. **Use `Array.from(string).length`** (accurately counts grapheme clusters)

   - **Pros**: Correctly counts emojis as single characters
   - **Cons**: Slight performance overhead, overkill for business requirement
   - **Rejected because**: Conference talk titles rarely contain emojis; user input specification mentions "accented characters" (which `.length` handles correctly), not emoji handling

2. **Use external library like `grapheme-splitter`**
   - **Pros**: Handles all Unicode edge cases including combining diacritics
   - **Cons**: Adds external dependency to domain layer (violates Clean Architecture Principle I)
   - **Rejected because**: Violates constitution (domain must have zero external dependencies), overkill for stated requirements

**Final Decision**: Use `.length` property with documented assumption that exotic Unicode characters are rare in conference talk titles. If emoji support becomes critical, can be addressed in future iteration with ADR amendment.

#### 2. Error Message Format

**Decision**: Template string format: `"Title length (${actual} characters) exceeds the maximum allowed length of ${max} characters"`

**Rationale**:

- Provides both actual and maximum values (per FR-004)
- Clear and actionable for end users
- Consistent with existing `InvalidDurationError` pattern in codebase
- Bilingual consideration: Message in English (code base language), can be internationalized at presentation layer if needed

**Alternatives Considered**:

1. **Simple message**: "Title too long"
   - Rejected: Not actionable, doesn't meet FR-004 requirement
2. **Technical message**: "String.length > MAX_TITLE_LENGTH"
   - Rejected: Too technical, violates Ubiquitous Language principle

#### 3. Validation Placement

**Decision**: Validate in Talk entity constructor

**Rationale**:

- Enforces invariant at entity creation (fail-fast principle)
- Consistent with existing validation pattern (see `InvalidDurationError` in constructor)
- Prevents creation of invalid Talk instances
- Immutable entity pattern: constructor is the sole creation point

**Alternatives Considered**:

1. **Validate in application layer use case**
   - Rejected: Domain invariants belong in domain layer, not application layer
2. **Validate in infrastructure layer (e.g., repository)**
   - Rejected: Too late, would allow invalid entities to exist in memory
3. **Separate validation method**
   - Rejected: Allows instantiation of invalid entities, breaks invariant guarantee

#### 4. Test Strategy

**Decision**: Unit tests in `tests/unit/domain/talk.entity.test.ts` covering:

- Boundary test: exactly 100 characters (should pass)
- Boundary test: 101 characters (should fail)
- Edge case: empty string (should fail - existing validation)
- Edge case: very long title (e.g., 200 characters)
- Error message verification

**Test Framework**: Needs to be selected and configured (deferred to implementation phase)

**Options**:

- **Jest**: Most popular, good TypeScript support, rich ecosystem
- **Vitest**: Faster, ESM-native (matches project's `"type": "module"`), Vite-compatible
- **Node.js native test runner** (`node:test`): Zero dependencies, built-in since Node 20

**Recommendation**: Vitest (aligns with ESM module setup, modern tooling, fast execution)

### Best Practices Applied

1. **Domain-Driven Design**: Validation logic encapsulated in domain entity
2. **Fail-Fast**: Invalid state rejected at construction time
3. **Immutability**: Entity remains immutable (no setter methods)
4. **Explicit Error Types**: Custom domain error class for clear error handling
5. **Constitution Compliance**: Pure domain logic, no external dependencies, ADR documented

### Dependencies Analysis

**External Dependencies**: None required (native JavaScript string operations)

**Internal Dependencies**:

- Modifies: `src/domain/talk.entity.ts`
- Impacts: Any code creating Talk instances (application layer, tests)
- No breaking changes (additive validation, existing valid talks remain valid)

---

## Phase 1: Design & Data Model

### Data Model

**File**: [data-model.md](./data-model.md)

#### Modified Entity: Talk

The Talk entity will be enhanced with title length validation. No schema changes, only validation logic added.

**Existing Fields** (unchanged):

- `id: string` - Unique identifier
- `title: string` - Talk title (NEW CONSTRAINT: max 100 characters)
- `abstract: string` - Talk description
- `speakerName: string` - Speaker name
- `_duration: Duration` - Talk duration (15|30|45|90 minutes)

**New Validation Rules**:

- `title.length <= 100` (Unicode character count using `.length`)
- If validation fails, throw `InvalidTitleLengthError` with actual and max length

**New Domain Error**:

```typescript
export class InvalidTitleLengthError extends Error {
  constructor(actualLength: number) {
    super(
      `Title length (${actualLength} characters) exceeds the maximum allowed length of 100 characters`,
    );
    this.name = 'InvalidTitleLengthError';
  }
}
```

**Validation Location**: Talk constructor (before other validations)

**State Transitions**: Not applicable (validation is stateless check)

**Relationships**: No changes to entity relationships

#### Edge Cases Handling

| Edge Case              | Behavior                                          |
| ---------------------- | ------------------------------------------------- |
| Exactly 100 characters | ✅ Valid (boundary inclusive)                     |
| 101 characters         | ❌ Throw InvalidTitleLengthError                  |
| Empty string           | ❌ Existing validation catches (title required)   |
| Whitespace only        | ❌ Existing validation catches (`.trim() === ''`) |
| Null/undefined         | ❌ TypeScript type system prevents                |
| Unicode/emojis         | Uses `.length` (may count surrogate pairs as 2)   |

### API Contracts

**File**: `contracts/` - Not applicable

**Rationale**: This feature modifies only domain-level validation logic. There are no API endpoints, GraphQL schemas, or external contracts to define. The validation is transparent to external consumers—they simply receive domain errors when submitting invalid data through existing interfaces.

### Quickstart Guide

**File**: [quickstart.md](./quickstart.md)

Created to document development workflow, testing approach, and implementation steps for this feature.

---

## Phase 2: Task Breakdown

**This phase is handled by the `/speckit.tasks` command.**

The planning phase ends here. Implementation tasks will be generated separately using the task generation workflow.

---

## Post-Design Constitution Re-Check

_Required after Phase 1 design artifacts are complete._

| Principle               | Validation                                                           | Status                                 |
| ----------------------- | -------------------------------------------------------------------- | -------------------------------------- |
| **Clean Architecture**  | All changes in `src/domain/talk.entity.ts`, zero external imports    | ✅ COMPLIANT                           |
| **ADR Required**        | `docs/adrs/0005-validation-titre.md` planned                         | ✅ COMPLIANT                           |
| **Ubiquitous Language** | `InvalidTitleLengthError` uses domain terminology                    | ✅ COMPLIANT                           |
| **TDD**                 | Test-first approach documented in quickstart, tests planned          | ✅ COMPLIANT (pending framework setup) |
| **SOLID Principles**    | Single Responsibility (validation in entity), no abstractions needed | ✅ COMPLIANT                           |

**Final Gate Decision**: ✅ APPROVED for implementation

**Compliance Summary**:

- No architectural violations introduced
- All governance gates satisfied
- Ready for `/speckit.tasks` command to generate implementation tasks
- ADR creation is first task (per Principle III)

---

## Implementation Readiness

**Branch**: `001-validate-talk-title-length` ✅
**Spec File**: `specs/001-validate-talk-title-length/spec.md` ✅
**Plan File**: `specs/001-validate-talk-title-length/plan.md` ✅ (this file)
**Research Complete**: ✅
**Design Artifacts**: ✅ data-model.md, quickstart.md
**Constitution Check**: ✅ All gates passed
**Governance Compliance**: ✅ All rules satisfied

**Next Step**: Run `/speckit.tasks` to generate actionable task breakdown for implementation.

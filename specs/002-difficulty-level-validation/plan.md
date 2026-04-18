# Implementation Plan: Difficulty Level Validation

**Branch**: `002-difficulty-level-validation` | **Date**: 2026-01-31 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-difficulty-level-validation/spec.md`

## Summary

Add difficulty level validation to the Talk entity to ensure all talks have a valid difficulty level ("Beginner", "Intermediate", or "Advanced"). This extends the existing Talk domain entity with a new immutable property, following the same validation pattern used for Duration and Title. The implementation will include a type-safe union type, custom domain error, and comprehensive test coverage.

## Technical Context

**Language/Version**: TypeScript 5.3.3 (strict mode enabled)
**Primary Dependencies**: None (pure domain logic with zero external dependencies)
**Storage**: N/A (in-memory domain entity)
**Testing**: Vitest 4.0.18 with coverage thresholds (80% minimum)
**Target Platform**: Node.js >= 20.0.0
**Project Type**: Single project (Clean Architecture with src/domain, src/application, src/infrastructure)
**Performance Goals**: Instant validation at entity instantiation (<1ms)
**Constraints**: Zero external dependencies in domain layer, immutable entities, type-safe validation
**Scale/Scope**: Single entity modification affecting 1 file (src/domain/talk.entity.ts) + comprehensive test suite

## Constitution Check

_GATE: Must pass before Phase 0 research. Re-check after Phase 1 design._

### ✅ Principe I: Clean Architecture (NON-NÉGOCIABLE)

**Status**: PASS

- **Domain purity**: This feature adds validation logic to `src/domain/talk.entity.ts` with zero external dependencies
- **Layer isolation**: No imports from application or infrastructure layers
- **Dependency direction**: Feature is purely within the domain layer (innermost circle)
- **Justification**: Difficulty level is a domain concept that represents intrinsic talk properties, not technical concerns

### ✅ Principe II: Software Craftsmanship (CRAFT)

**Status**: PASS

- **SOLID principles**: Single Responsibility (validation logic isolated in domain error and type guard)
- **Naming**: Using ubiquitous language (`DifficultyLevel`, `InvalidDifficultyLevelError`, not technical jargon)
- **Readability**: Simple union type + validation logic following existing patterns (Duration, Title)
- **No anti-patterns**: No God Objects, no magic strings (type-safe union), explicit error messages

### ✅ Principe III: Règle d'Or de la Documentation (CRITIQUE)

**Status**: PASS - ADR REQUIRED

- **Modification structurante**: YES - Adding new property to domain entity + new domain error
- **ADR Required**: YES
  - **Path**: `docs/adrs/NNNN-difficulty-level-validation.md`
  - **Content Required**:
    - **Context**: Why three difficulty levels (Beginner/Intermediate/Advanced), alignment with conference standards
    - **Decision**: Union type vs. enum, validation approach (constructor vs. factory), type safety trade-offs
    - **Consequences**: Impact on existing code, migration strategy, type safety benefits
    - **Alternatives**: String without validation, enum type, class hierarchy, numeric scale

### ✅ Principe IV: Ubiquitous Language

**Status**: PASS

- **Domain terms**: `DifficultyLevel`, `Beginner`, `Intermediate`, `Advanced` match conference domain language
- **Error naming**: `InvalidDifficultyLevelError` follows domain error pattern (not `DifficultyLevelException` or technical naming)
- **Property exposure**: `difficulty` property uses domain terminology, read-only access via getter

### ✅ Principe V: Test-Driven Development (TDD)

**Status**: PASS - TDD WORKFLOW MANDATORY

- **TDD Cycle**: Red → Green → Refactor will be strictly followed
- **Coverage targets**:
  - Domain: 100% coverage (validation logic, error handling, property access)
  - Test types: Unit tests for validation, boundary tests, error message tests
- **Test-first**: Tests written before implementation in Phase 2

### ✅ Principe VI: Code Review Obligatoire

**Status**: PASS

- **Review checklist**: Clean Architecture ✓, ADR created ✓, Tests present ✓, Ubiquitous Language ✓
- **Approval required**: Minimum 1 approval before merge
- **Branch protection**: Merge to main blocked without approval

**GATE RESULT**: ✅ ALL GATES PASS - Proceed to Phase 0

## Governance Compliance Gate

_GATE: CI/CD will automatically validate these rules on every PR to main._

**Governance File**: `.spec-kit/governance.md`
**Rules Reference**: `.specify/memory/governance-rules.md`

### Required for PR Merge

| Rule   | Description                | Validation                                                     | Status        |
| ------ | -------------------------- | -------------------------------------------------------------- | ------------- |
| **R1** | Structure obligatoire      | `src/domain/`, `src/application/`, `src/infrastructure/` exist | ✅ Pre-exists |
| **R2** | Clean Architecture imports | Domain/Application never import from outer layers              | ✅ No imports |
| **R3** | ADR obligatoire            | At least one ADR in `docs/adrs/NNNN-*.md` format               | ⚠️ Required   |
| **R4** | Cohérence documentation    | AI review validates doc/code alignment                         | ✅ CI check   |

### Pre-Implementation Checklist

- [x] Identify which ADR(s) this feature requires
  - `docs/adrs/NNNN-difficulty-level-validation.md` documenting type choice and validation approach
- [x] Determine correct layer placement (domain/application/infrastructure)
  - **Layer**: `src/domain/` (difficulty level is pure domain concept)
- [x] Verify no architectural violations will be introduced
  - **Verification**: Zero external imports, extends existing Talk entity following established patterns

## Project Structure

### Documentation (this feature)

```text
specs/002-difficulty-level-validation/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output - type system research, validation patterns
├── data-model.md        # Phase 1 output - DifficultyLevel type, Talk entity schema
├── quickstart.md        # Phase 1 output - usage examples, migration guide
├── contracts/           # Phase 1 output - N/A for domain-only feature
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
src/
├── domain/
│   └── talk.entity.ts              # MODIFIED: Add DifficultyLevel type,
│                                   #           InvalidDifficultyLevelError class,
│                                   #           difficulty property + validation
├── application/                    # NO CHANGES
└── infrastructure/                 # NO CHANGES

tests/
└── unit/
    └── domain/
        └── talk.entity.test.ts     # MODIFIED: Add difficulty level test suite
                                    #           (~10 new tests covering validation,
                                    #           error messages, property access,
                                    #           edge cases)

docs/
└── adrs/
    └── NNNN-difficulty-level-validation.md  # NEW: ADR documenting type choice
```

**Structure Decision**: This is a single-entity modification within the domain layer. The existing Clean Architecture structure (domain/application/infrastructure) is preserved. No new files are created except the ADR. The Talk entity is extended following the immutable entity pattern established by Duration and Title validations.

## Complexity Tracking

**No violations** - All Constitution gates pass. This feature follows existing architectural patterns and introduces no new complexity or dependencies.

---

## Phase 0: Research & Decisions

### Research Tasks

**R1: TypeScript Type System for Validation**
- **Objective**: Determine the best approach for type-safe difficulty level validation
- **Questions**:
  - Union type (`"Beginner" | "Intermediate" | "Advanced"`) vs. enum vs. const assertion?
  - Runtime validation strategy for constructor parameters?
  - Type guard pattern for validation?
- **Deliverable**: Decision on type system approach with rationale

**R2: Domain Error Patterns**
- **Objective**: Follow established error handling patterns in the codebase
- **Questions**:
  - How do existing domain errors (InvalidDurationError, InvalidTitleLengthError) structure error messages?
  - Should error message include invalid value + list of valid values?
  - Error inheritance strategy (extend Error directly)?
- **Deliverable**: Error class specification matching existing patterns

**R3: Immutability and Property Exposure**
- **Objective**: Maintain immutability guarantees of the Talk entity
- **Questions**:
  - How are other immutable properties exposed (duration uses getter, title uses readonly)?
  - Should difficulty be constructor parameter or private field with getter?
  - Naming convention for private fields vs. public getters?
- **Deliverable**: Property design following existing Talk entity patterns

**R4: Edge Case Handling**
- **Objective**: Define behavior for edge cases identified in spec
- **Questions**:
  - How to handle case sensitivity ("beginner" vs. "Beginner")?
  - How to handle whitespace (leading/trailing spaces)?
  - How to handle type coercion (number, boolean, null, undefined)?
- **Deliverable**: Edge case decision matrix with test scenarios

### Research Output Location

`specs/002-difficulty-level-validation/research.md`

---

## Phase 1: Design & Contracts

### 1.1 Data Model Design

**Output**: `specs/002-difficulty-level-validation/data-model.md`

**Contents**:

#### DifficultyLevel Type

```typescript
// Type definition
export type DifficultyLevel = "Beginner" | "Intermediate" | "Advanced";

// Validation
const VALID_DIFFICULTY_LEVELS: ReadonlyArray<DifficultyLevel> = [
  "Beginner",
  "Intermediate",
  "Advanced"
] as const;
```

#### InvalidDifficultyLevelError Class

```typescript
export class InvalidDifficultyLevelError extends Error {
  constructor(providedValue: unknown) {
    super(
      `Invalid difficulty level: "${providedValue}". Valid levels are: Beginner, Intermediate, Advanced`
    );
    this.name = 'InvalidDifficultyLevelError';
  }
}
```

#### Talk Entity Extension

**Modified constructor signature**:
```typescript
constructor(
  public readonly id: string,
  public readonly title: string,
  public readonly abstract: string,
  public readonly speakerName: string,
  private readonly _duration: Duration,
  private readonly _difficulty: DifficultyLevel  // NEW
)
```

**New property getter**:
```typescript
get difficulty(): DifficultyLevel {
  return this._difficulty;
}
```

**New validation method**:
```typescript
private isValidDifficultyLevel(value: unknown): value is DifficultyLevel {
  return typeof value === 'string' &&
    (value === 'Beginner' || value === 'Intermediate' || value === 'Advanced');
}
```

**Validation in constructor** (after line 70):
```typescript
if (!this.isValidDifficultyLevel(_difficulty)) {
  throw new InvalidDifficultyLevelError(_difficulty);
}
```

**Impact on existing methods**:
- `changeDuration()`: Update to pass difficulty parameter when creating new instance
- No breaking changes to public API (difficulty is additive)

### 1.2 API Contracts

**N/A** - This is a domain-only feature with no API exposure. No REST endpoints or GraphQL schemas are affected. Contract validation happens at the TypeScript type level.

### 1.3 Quickstart Guide

**Output**: `specs/002-difficulty-level-validation/quickstart.md`

**Contents**:

#### Creating Talks with Difficulty Levels

```typescript
import { Talk } from './domain/talk.entity';

// Valid difficulty levels
const beginnerTalk = new Talk(
  '1',
  'Introduction to TypeScript',
  'Learn the basics',
  'John Doe',
  45,
  'Beginner'  // NEW parameter
);

const intermediateTalk = new Talk(
  '2',
  'Advanced TypeScript Patterns',
  'Deep dive into types',
  'Jane Smith',
  90,
  'Intermediate'
);

const advancedTalk = new Talk(
  '3',
  'Compiler Internals',
  'How TypeScript compiles',
  'Expert Dev',
  90,
  'Advanced'
);

// Access difficulty level
console.log(beginnerTalk.difficulty); // "Beginner"
```

#### Error Handling

```typescript
import { InvalidDifficultyLevelError } from './domain/talk.entity';

try {
  const invalidTalk = new Talk(
    '4',
    'Some Talk',
    'Description',
    'Speaker',
    45,
    'Expert'  // ❌ Invalid - will throw
  );
} catch (error) {
  if (error instanceof InvalidDifficultyLevelError) {
    console.error(error.message);
    // "Invalid difficulty level: "Expert". Valid levels are: Beginner, Intermediate, Advanced"
  }
}
```

#### Migration Guide for Existing Code

```typescript
// BEFORE (Feature 001 - no difficulty level)
const talk = new Talk('1', 'Title', 'Abstract', 'Speaker', 45);

// AFTER (Feature 002 - difficulty level required)
const talk = new Talk('1', 'Title', 'Abstract', 'Speaker', 45, 'Intermediate');

// Breaking change: Constructor signature changed
// Action required: Add difficulty level to all Talk instantiations
```

### 1.4 Agent Context Update

Run the agent context update script to add new type information:

```bash
.specify/scripts/bash/update-agent-context.sh claude
```

**New entries to add**:
- `DifficultyLevel` type (union of three string literals)
- `InvalidDifficultyLevelError` domain error class
- Updated `Talk` constructor signature with difficulty parameter

---

## Phase 2: Implementation (Handled by /speckit.tasks)

**Note**: Phase 2 is NOT executed by `/speckit.plan`. The implementation will be generated by `/speckit.tasks` command, which produces `tasks.md` with TDD workflow.

**Expected task structure** (for reference only, not created here):

1. **Governance**: Create ADR documenting type choice
2. **TDD Red**: Write failing tests for difficulty level validation
3. **TDD Green**: Implement DifficultyLevel type + InvalidDifficultyLevelError
4. **TDD Refactor**: Extend Talk entity with difficulty property
5. **Edge Cases**: Handle case sensitivity, whitespace, type coercion
6. **Migration**: Update existing tests to include difficulty parameter
7. **Polish**: Run linting, formatting, coverage checks

---

## ADR Requirements

**Required ADR**: `docs/adrs/NNNN-difficulty-level-validation.md`

**Template structure**:

```markdown
# ADR-NNNN: Difficulty Level Validation for Talks

**Statut**: Accepté
**Date**: 2026-01-31

## Contexte

Devoxx conference talks need to be categorized by difficulty level to help attendees choose appropriate sessions. The system currently validates talk duration and title length but lacks difficulty level validation.

**Requirements**:
- Three difficulty levels: Beginner, Intermediate, Advanced
- Type-safe validation at compile time and runtime
- Clear error messages for invalid levels
- Immutable property following existing Talk entity patterns

## Décision

### Type System Choice: Union Type over Enum

**Decision**: Use TypeScript union type `type DifficultyLevel = "Beginner" | "Intermediate" | "Advanced"`

**Rationale**:
1. **Simplicity**: No runtime code generation (enums generate JavaScript objects)
2. **Type safety**: Compile-time checking with autocomplete
3. **Serialization**: String values serialize naturally to JSON without conversion
4. **Pattern consistency**: Matches Duration type pattern (numeric literals)

**Alternatives considered**:
- **Enum**: Rejected due to runtime overhead and serialization complexity
- **String without type**: Rejected due to lack of type safety
- **Class hierarchy**: Rejected as over-engineering for simple value type

### Validation Strategy: Constructor Validation

**Decision**: Validate difficulty level in Talk entity constructor using type guard

**Rationale**:
1. **Fail-fast**: Invalid talks cannot be constructed (domain invariant)
2. **Consistency**: Matches existing validation patterns (Duration, Title)
3. **Single responsibility**: Validation logic co-located with entity

### Property Exposure: Private Field + Getter

**Decision**: Use private `_difficulty` field with public `difficulty` getter (readonly)

**Rationale**:
1. **Immutability**: Prevents external modification after construction
2. **Encapsulation**: Internal representation hidden
3. **Pattern consistency**: Matches `_duration` property pattern

### Edge Case Handling

**Decision**: Strict validation, no implicit coercion

- **Case sensitivity**: REJECT "beginner" (only "Beginner" valid)
- **Whitespace**: REJECT " Beginner " (no trimming)
- **Type coercion**: REJECT numbers, booleans, null, undefined

**Rationale**: Explicit validation reduces ambiguity and prevents silent errors

## Conséquences

### Positives
- ✅ Type-safe difficulty level validation at compile time and runtime
- ✅ Clear, actionable error messages listing valid levels
- ✅ Zero external dependencies (pure domain logic)
- ✅ Consistent with existing Talk entity patterns
- ✅ Minimal performance impact (instant validation)

### Negatives
- ⚠️ Breaking change: Talk constructor signature modified (5th parameter added)
- ⚠️ Migration effort: All existing Talk instantiations must be updated
- ⚠️ Strict validation may surprise users expecting case-insensitive matching

### Mitigation Strategies
- **Breaking change**: Leverage TypeScript compiler to find all affected call sites
- **Migration guide**: Provide clear examples in quickstart.md
- **Documentation**: ADR documents rationale for strict validation
```

---

## Next Steps

1. ✅ **Phase 0 Complete**: Research completed (decisions documented above)
2. ✅ **Phase 1 Complete**: Data model, contracts, and quickstart designed
3. ⏭️ **Next Command**: Run `/speckit.tasks` to generate actionable implementation tasks
4. ⏭️ **After Tasks**: Run `/speckit.implement` to execute TDD workflow

**Output Artifacts**:
- ✅ `specs/002-difficulty-level-validation/plan.md` (this file)
- ✅ Research decisions documented inline (no separate research.md needed - decisions are straightforward)
- ✅ Data model design specified
- ✅ Quickstart guide specified
- ⏭️ `specs/002-difficulty-level-validation/tasks.md` (created by /speckit.tasks)

**Branch**: `002-difficulty-level-validation` (already created)
**Ready for**: Task generation via `/speckit.tasks`

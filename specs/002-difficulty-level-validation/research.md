# Research: Difficulty Level Validation

**Feature**: 002-difficulty-level-validation
**Date**: 2026-01-31
**Status**: Complete

## Overview

This document captures research findings for implementing difficulty level validation in the Talk domain entity. The feature extends the existing Talk entity with a new immutable property following established patterns.

---

## R1: TypeScript Type System for Validation

### Research Question
How should we implement type-safe difficulty level validation in TypeScript?

### Options Evaluated

#### Option 1: Union Type (String Literals)
```typescript
export type DifficultyLevel = "Beginner" | "Intermediate" | "Advanced";
```

**Pros**:
- Zero runtime overhead (pure type system)
- Excellent IDE autocomplete support
- Natural JSON serialization (no conversion needed)
- Matches existing Duration pattern in codebase

**Cons**:
- No runtime enumeration of values without explicit array
- Requires runtime validation in addition to compile-time checking

#### Option 2: TypeScript Enum
```typescript
export enum DifficultyLevel {
  Beginner = "Beginner",
  Intermediate = "Intermediate",
  Advanced = "Advanced"
}
```

**Pros**:
- Runtime enumeration available (Object.values)
- Type-safe at compile time

**Cons**:
- Generates JavaScript code (adds bundle size)
- More complex serialization to JSON
- Not consistent with Duration type pattern

#### Option 3: Const Assertion
```typescript
const DIFFICULTY_LEVELS = ["Beginner", "Intermediate", "Advanced"] as const;
export type DifficultyLevel = typeof DIFFICULTY_LEVELS[number];
```

**Pros**:
- Runtime array available for validation
- Type derived from single source of truth

**Cons**:
- More complex type derivation
- Less readable type signature

### Decision

**Selected**: Option 1 (Union Type)

**Rationale**:
1. **Consistency**: Matches existing `Duration` type pattern (`15 | 30 | 45 | 90`)
2. **Simplicity**: No runtime code generation, straightforward type definition
3. **Zero dependencies**: Pure type system without additional constructs
4. **Developer experience**: Best autocomplete and type inference

**Implementation**:
```typescript
export type DifficultyLevel = "Beginner" | "Intermediate" | "Advanced";

// Helper for runtime validation (if needed)
const VALID_DIFFICULTY_LEVELS: ReadonlyArray<DifficultyLevel> = [
  "Beginner",
  "Intermediate",
  "Advanced"
] as const;
```

**Reference**: Existing codebase pattern in `src/domain/talk.entity.ts:9` (Duration type)

---

## R2: Domain Error Patterns

### Research Question
How should InvalidDifficultyLevelError be structured to match existing domain error patterns?

### Existing Patterns Analysis

**InvalidDurationError** (lines 15-22):
```typescript
export class InvalidDurationError extends Error {
  constructor(value: number) {
    super(
      `Invalid duration: ${value}. Duration must be 15 (Quickie), 30 (Tools-in-Action), 45 (Conference), or 90 (Deep Dive) minutes.`,
    );
    this.name = 'InvalidDurationError';
  }
}
```

**InvalidTitleLengthError** (lines 28-35):
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

### Pattern Observations

1. **Inheritance**: All domain errors extend Error directly
2. **Naming convention**: `Invalid{Property}{Constraint}Error` format, set via `this.name`
3. **Error messages**: Descriptive, include provided value + constraint explanation
4. **Constructor parameters**: Accept the invalid value for error message construction
5. **Message format**: `{Problem description}. {Valid values or constraints}`

### Decision

**InvalidDifficultyLevelError specification**:

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

**Key choices**:
- **Parameter type**: `unknown` (not `string`) to handle edge cases (numbers, null, undefined)
- **Message format**: `Invalid difficulty level: "{value}". Valid levels are: {list}`
- **Quotes around value**: Helps visualize whitespace and empty strings in error messages
- **List format**: Comma-separated, human-readable (not JSON array)

**Consistency check**: ✅ Matches existing error patterns

---

## R3: Immutability and Property Exposure

### Research Question
How should the difficulty property be implemented to maintain immutability?

### Existing Property Patterns

**Duration property** (lines 54, 74-76):
```typescript
// Constructor parameter
constructor(
  public readonly id: string,
  public readonly title: string,
  public readonly abstract: string,
  public readonly speakerName: string,
  private readonly _duration: Duration,  // <-- Private field
) { ... }

// Getter
get duration(): Duration {
  return this._duration;
}
```

**Immutable properties** (id, title, abstract, speakerName):
```typescript
public readonly id: string,
public readonly title: string,
public readonly abstract: string,
public readonly speakerName: string,
```

### Pattern Analysis

**Two patterns observed**:
1. **Public readonly**: For properties that don't need validation or transformation (id, title, abstract, speakerName)
2. **Private + getter**: For properties that may need future validation or transformation (duration)

**Why duration uses private + getter**:
- Encapsulation: Internal representation can change without breaking API
- Future-proofing: Can add validation or transformation in getter if needed
- Consistent with `format` computed property pattern

### Decision

**Selected**: Private field + getter pattern (matching duration)

**Implementation**:
```typescript
constructor(
  public readonly id: string,
  public readonly title: string,
  public readonly abstract: string,
  public readonly speakerName: string,
  private readonly _duration: Duration,
  private readonly _difficulty: DifficultyLevel,  // NEW
) { ... }

get difficulty(): DifficultyLevel {
  return this._difficulty;
}
```

**Rationale**:
1. **Consistency**: Matches existing `_duration` pattern
2. **Encapsulation**: Hides internal representation
3. **Future-proofing**: Can add computed properties (e.g., `difficultyScore: number`) if needed
4. **Immutability**: Private + readonly prevents modification

**Alternative rejected**: Public readonly would work but breaks pattern consistency with duration

---

## R4: Edge Case Handling

### Research Question
How should edge cases (case sensitivity, whitespace, type coercion) be handled?

### Edge Case Scenarios

| Scenario                        | Input                  | Expected Behavior          |
| ------------------------------- | ---------------------- | -------------------------- |
| Valid Beginner                  | `"Beginner"`           | ✅ Accept                  |
| Valid Intermediate              | `"Intermediate"`       | ✅ Accept                  |
| Valid Advanced                  | `"Advanced"`           | ✅ Accept                  |
| Lowercase                       | `"beginner"`           | ❌ Reject                  |
| Uppercase                       | `"BEGINNER"`           | ❌ Reject                  |
| Mixed case                      | `"BeGiNnEr"`           | ❌ Reject                  |
| Leading whitespace              | `" Beginner"`          | ❌ Reject                  |
| Trailing whitespace             | `"Beginner "`          | ❌ Reject                  |
| Leading + trailing whitespace   | `" Beginner "`         | ❌ Reject                  |
| Empty string                    | `""`                   | ❌ Reject                  |
| Invalid string                  | `"Easy"`               | ❌ Reject                  |
| Invalid string                  | `"Expert"`             | ❌ Reject                  |
| Number                          | `1`                    | ❌ Reject                  |
| Boolean                         | `true`                 | ❌ Reject                  |
| Null                            | `null`                 | ❌ Reject                  |
| Undefined                       | `undefined`            | ❌ Reject                  |
| Object                          | `{level: "Beginner"}`  | ❌ Reject                  |

### Design Alternatives

#### Alternative A: Strict Validation (No Normalization)
- Exact string match required
- No trimming, no case normalization
- Type coercion rejected

**Pros**:
- Predictable behavior (no magic)
- Type safety enforced strictly
- Clear contract: exactly "Beginner", "Intermediate", or "Advanced"

**Cons**:
- Less forgiving for user input errors
- May surprise developers expecting case-insensitive matching

#### Alternative B: Lenient Validation (Case-Insensitive + Trim)
- Accept "beginner", "BEGINNER", " Beginner "
- Normalize to canonical form

**Pros**:
- More user-friendly for interactive input
- Reduces validation errors

**Cons**:
- Introduces implicit behavior (magic normalization)
- Complicates validation logic
- Inconsistent with Duration validation (no normalization)

### Decision

**Selected**: Alternative A (Strict Validation)

**Rationale**:
1. **Consistency**: Matches existing Duration validation (no normalization)
2. **Type safety**: Enforces exact type contract at all boundaries
3. **Simplicity**: No implicit transformations, predictable behavior
4. **Domain purity**: Validation logic is straightforward and explicit

**Implementation**:
```typescript
private isValidDifficultyLevel(value: unknown): value is DifficultyLevel {
  return typeof value === 'string' &&
    (value === 'Beginner' || value === 'Intermediate' || value === 'Advanced');
}
```

**Error handling**:
```typescript
if (!this.isValidDifficultyLevel(_difficulty)) {
  throw new InvalidDifficultyLevelError(_difficulty);
}
```

**Test coverage**:
- ✅ Valid values: "Beginner", "Intermediate", "Advanced"
- ❌ Case variations: "beginner", "BEGINNER"
- ❌ Whitespace: " Beginner", "Beginner "
- ❌ Type coercion: numbers, booleans, null, undefined, objects

---

## Impact on Existing Code

### Breaking Changes

**Constructor signature change**:
```typescript
// BEFORE
new Talk(id, title, abstract, speakerName, duration)

// AFTER
new Talk(id, title, abstract, speakerName, duration, difficulty)
```

**Impact**: All existing Talk instantiations must be updated

**Mitigation**:
1. TypeScript compiler will flag all call sites (compile-time error)
2. Existing tests will fail, forcing updates
3. Migration guide in quickstart.md

### Method Updates

**changeDuration() method** (line 102):
```typescript
// BEFORE
changeDuration(newDuration: number): Talk {
  if (!this.isValidDuration(newDuration)) {
    throw new InvalidDurationError(newDuration);
  }
  return new Talk(this.id, this.title, this.abstract, this.speakerName, newDuration as Duration);
}

// AFTER
changeDuration(newDuration: number): Talk {
  if (!this.isValidDuration(newDuration)) {
    throw new InvalidDurationError(newDuration);
  }
  return new Talk(this.id, this.title, this.abstract, this.speakerName, newDuration as Duration, this._difficulty);
}
```

**Impact**: Internal implementation detail, no breaking change to public API

---

## References

### Existing Code Patterns

- `src/domain/talk.entity.ts:9` - Duration type definition (union type pattern)
- `src/domain/talk.entity.ts:15-22` - InvalidDurationError (error pattern)
- `src/domain/talk.entity.ts:28-35` - InvalidTitleLengthError (error pattern)
- `src/domain/talk.entity.ts:74-76` - duration getter (private field + getter pattern)
- `src/domain/talk.entity.ts:112-114` - isValidDuration type guard (validation pattern)

### Constitution Principles

- Principle I: Clean Architecture - Zero external dependencies in domain
- Principle II: Software Craftsmanship - SOLID principles, explicit naming
- Principle IV: Ubiquitous Language - Domain terminology (Beginner, Intermediate, Advanced)
- Principle V: TDD - Tests written before implementation

---

## Summary

All research questions resolved:

1. ✅ **Type System**: Union type (`"Beginner" | "Intermediate" | "Advanced"`)
2. ✅ **Error Pattern**: `InvalidDifficultyLevelError extends Error` with descriptive message
3. ✅ **Property Exposure**: Private `_difficulty` field + public `difficulty` getter
4. ✅ **Edge Cases**: Strict validation, no normalization, reject invalid types

**Ready for**: Data model design (Phase 1) and task generation (Phase 2)

**Next artifacts**: `data-model.md`, `quickstart.md`, then `tasks.md` via `/speckit.tasks`

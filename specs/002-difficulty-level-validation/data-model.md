# Data Model: Difficulty Level Validation

**Feature**: 002-difficulty-level-validation
**Date**: 2026-01-31
**Status**: Design Complete

## Overview

This document specifies the data model changes for adding difficulty level validation to the Talk domain entity. All changes are constrained to the domain layer with zero external dependencies.

---

## Type Definitions

### DifficultyLevel (New Type)

**Location**: `src/domain/talk.entity.ts`

**Definition**:
```typescript
/**
 * DifficultyLevel (Value Object)
 * Represents the difficulty level of a conference talk.
 * Valid values:
 *  - "Beginner" = Introductory content, no prior knowledge required
 *  - "Intermediate" = Some prior knowledge expected
 *  - "Advanced" = Expert-level content, significant prior knowledge required
 */
export type DifficultyLevel = "Beginner" | "Intermediate" | "Advanced";
```

**Characteristics**:
- **Type**: Union of string literals (TypeScript type alias)
- **Runtime representation**: JavaScript string
- **Serialization**: No conversion needed (native JSON string)
- **Validation**: Type guard required for runtime validation

**Domain Semantics**:
- **Beginner**: Talks suitable for attendees new to the topic
- **Intermediate**: Talks requiring some familiarity with the topic
- **Advanced**: Talks for experienced practitioners with deep knowledge

---

## Domain Errors

### InvalidDifficultyLevelError (New Class)

**Location**: `src/domain/talk.entity.ts` (after InvalidTitleLengthError, before Talk class)

**Definition**:
```typescript
/**
 * InvalidDifficultyLevelError (Domain Error)
 * Thrown when an invalid difficulty level is provided during Talk entity instantiation.
 */
export class InvalidDifficultyLevelError extends Error {
  constructor(providedValue: unknown) {
    super(
      `Invalid difficulty level: "${providedValue}". Valid levels are: Beginner, Intermediate, Advanced`
    );
    this.name = 'InvalidDifficultyLevelError';
  }
}
```

**Properties**:
- **name**: `"InvalidDifficultyLevelError"` (set explicitly for stack traces)
- **message**: Template string including provided value and valid options
- **Parameter type**: `unknown` (handles all edge cases: strings, numbers, null, undefined, objects)

**Error Message Format**:
```
Invalid difficulty level: "{providedValue}". Valid levels are: Beginner, Intermediate, Advanced
```

**Examples**:
- `new InvalidDifficultyLevelError("Easy")` → `"Invalid difficulty level: "Easy". Valid levels are: Beginner, Intermediate, Advanced"`
- `new InvalidDifficultyLevelError(1)` → `"Invalid difficulty level: "1". Valid levels are: Beginner, Intermediate, Advanced"`
- `new InvalidDifficultyLevelError(null)` → `"Invalid difficulty level: "null". Valid levels are: Beginner, Intermediate, Advanced"`

---

## Entity Modifications

### Talk Entity (Extended)

**Location**: `src/domain/talk.entity.ts`

#### Constructor Signature (MODIFIED)

**Before**:
```typescript
constructor(
  public readonly id: string,
  public readonly title: string,
  public readonly abstract: string,
  public readonly speakerName: string,
  private readonly _duration: Duration,
)
```

**After**:
```typescript
constructor(
  public readonly id: string,
  public readonly title: string,
  public readonly abstract: string,
  public readonly speakerName: string,
  private readonly _duration: Duration,
  private readonly _difficulty: DifficultyLevel,  // NEW PARAMETER
)
```

**Breaking Change**: ⚠️ All existing Talk instantiations must add difficulty parameter

#### Validation Logic (NEW)

**Location**: Inside constructor, after existing validations (after line 70)

**Implementation**:
```typescript
// Inside constructor, after duration validation
if (!this.isValidDifficultyLevel(_difficulty)) {
  throw new InvalidDifficultyLevelError(_difficulty);
}
```

**Validation order**:
1. id validation (existing)
2. title validation (existing)
3. title length validation (existing, feature 001)
4. speakerName validation (existing)
5. duration validation (existing)
6. **difficulty validation (NEW)** ← Added here

#### Property Getter (NEW)

**Location**: After duration getter (after line 76)

**Implementation**:
```typescript
/** Read-only access to difficulty level */
get difficulty(): DifficultyLevel {
  return this._difficulty;
}
```

**Behavior**:
- Returns the immutable difficulty level set during construction
- Read-only: No setter provided (immutability guarantee)
- Type-safe: Return type enforced by TypeScript

#### Type Guard Method (NEW)

**Location**: After isValidDuration method (after line 114)

**Implementation**:
```typescript
/**
 * Type guard for valid difficulty levels
 */
private isValidDifficultyLevel(value: unknown): value is DifficultyLevel {
  return typeof value === 'string' &&
    (value === 'Beginner' || value === 'Intermediate' || value === 'Advanced');
}
```

**Behavior**:
- Type guard pattern: `value is DifficultyLevel` narrows type in caller
- Runtime validation: Checks exact string match (case-sensitive)
- Strict validation: No trimming, no normalization
- Type safety: Handles `unknown` parameter type safely

#### Modified Methods

**changeDuration() method** (line 102-107):

**Before**:
```typescript
changeDuration(newDuration: number): Talk {
  if (!this.isValidDuration(newDuration)) {
    throw new InvalidDurationError(newDuration);
  }
  return new Talk(this.id, this.title, this.abstract, this.speakerName, newDuration as Duration);
}
```

**After**:
```typescript
changeDuration(newDuration: number): Talk {
  if (!this.isValidDuration(newDuration)) {
    throw new InvalidDurationError(newDuration);
  }
  return new Talk(
    this.id,
    this.title,
    this.abstract,
    this.speakerName,
    newDuration as Duration,
    this._difficulty  // NEW: Pass difficulty to maintain immutability
  );
}
```

**Rationale**: When creating a new Talk instance via `changeDuration()`, must preserve difficulty level to maintain immutability contract.

---

## Entity Schema

### Talk Entity (Complete Schema)

```typescript
{
  // Existing properties
  id: string                      // Unique identifier (readonly, public)
  title: string                   // Talk title, max 100 chars (readonly, public)
  abstract: string                // Talk description (readonly, public)
  speakerName: string             // Speaker name (readonly, public)
  _duration: Duration             // Duration: 15|30|45|90 (private, accessed via getter)

  // NEW property
  _difficulty: DifficultyLevel    // Difficulty: "Beginner"|"Intermediate"|"Advanced" (private, accessed via getter)

  // Computed properties (getters)
  duration: Duration              // Read-only access to _duration
  format: 'Quickie' | 'Tools-in-Action' | 'Conference' | 'Deep Dive'  // Computed from duration
  difficulty: DifficultyLevel     // NEW: Read-only access to _difficulty

  // Methods
  changeDuration(newDuration: number): Talk  // Returns new Talk instance with updated duration
}
```

### Invariants

**Existing invariants** (preserved):
1. `id` must be non-empty string
2. `title` must be non-empty string
3. `title.length` must be ≤ 100 characters
4. `speakerName` must be non-empty string
5. `duration` must be exactly 15, 30, 45, or 90

**NEW invariant**:
6. **`difficulty` must be exactly "Beginner", "Intermediate", or "Advanced" (case-sensitive)**

**Enforcement**: All invariants validated in constructor, throwing domain errors on violation.

---

## Validation Rules

### Difficulty Level Validation Matrix

| Input                | Type      | Valid? | Error                             |
| -------------------- | --------- | ------ | --------------------------------- |
| `"Beginner"`         | string    | ✅ Yes | -                                 |
| `"Intermediate"`     | string    | ✅ Yes | -                                 |
| `"Advanced"`         | string    | ✅ Yes | -                                 |
| `"beginner"`         | string    | ❌ No  | InvalidDifficultyLevelError       |
| `"BEGINNER"`         | string    | ❌ No  | InvalidDifficultyLevelError       |
| `"Easy"`             | string    | ❌ No  | InvalidDifficultyLevelError       |
| `"Expert"`           | string    | ❌ No  | InvalidDifficultyLevelError       |
| `" Beginner"`        | string    | ❌ No  | InvalidDifficultyLevelError       |
| `"Beginner "`        | string    | ❌ No  | InvalidDifficultyLevelError       |
| `""`                 | string    | ❌ No  | InvalidDifficultyLevelError       |
| `1`                  | number    | ❌ No  | InvalidDifficultyLevelError       |
| `true`               | boolean   | ❌ No  | InvalidDifficultyLevelError       |
| `null`               | null      | ❌ No  | InvalidDifficultyLevelError       |
| `undefined`          | undefined | ❌ No  | InvalidDifficultyLevelError       |
| `{level: "Beginner"}` | object   | ❌ No  | InvalidDifficultyLevelError       |

**Validation strategy**: Exact string match, no normalization, no type coercion

---

## Migration Impact

### Code Changes Required

**All Talk instantiations** must be updated to include difficulty parameter:

**Example 1: Tests**
```typescript
// BEFORE
const talk = new Talk('1', 'TypeScript Basics', 'Learn TS', 'John Doe', 45);

// AFTER
const talk = new Talk('1', 'TypeScript Basics', 'Learn TS', 'John Doe', 45, 'Beginner');
```

**Example 2: Application Layer**
```typescript
// BEFORE
const talk = this.talkRepository.create(
  id,
  data.title,
  data.abstract,
  data.speakerName,
  data.duration
);

// AFTER
const talk = this.talkRepository.create(
  id,
  data.title,
  data.abstract,
  data.speakerName,
  data.duration,
  data.difficulty  // NEW parameter
);
```

### Type Safety

**Compile-time detection**: TypeScript will flag all call sites missing difficulty parameter

**Error example**:
```
Expected 6 arguments, but got 5.
An argument for '_difficulty' was not provided.
```

**Benefit**: Impossible to miss migration spots - compiler enforces completeness

---

## Relationships and Dependencies

### Domain Layer Dependencies

```
DifficultyLevel (type)
      ↓
InvalidDifficultyLevelError (error class)
      ↓
Talk (entity) ← uses type and error
```

**External dependencies**: ZERO ✅
- No imports from application layer
- No imports from infrastructure layer
- No external libraries
- Pure TypeScript domain logic

### Interaction with Existing Types

**No conflicts with existing types**:
- `Duration` type: Numeric literals (15|30|45|90)
- `DifficultyLevel` type: String literals ("Beginner"|"Intermediate"|"Advanced")
- Different type spaces, no overlap

**Composed in Talk entity**:
```typescript
Talk {
  _duration: Duration,            // Existing
  _difficulty: DifficultyLevel    // NEW
}
```

---

## Testing Considerations

### Test Coverage Requirements

**Validation tests** (boundary conditions):
- ✅ Valid difficulty levels: "Beginner", "Intermediate", "Advanced"
- ❌ Invalid case variations: "beginner", "BEGINNER"
- ❌ Invalid with whitespace: " Beginner", "Beginner "
- ❌ Invalid strings: "Easy", "Expert", ""
- ❌ Wrong types: numbers, booleans, null, undefined, objects

**Property access tests**:
- ✅ Read difficulty via getter
- ✅ Immutability: No setter exists

**Integration tests**:
- ✅ changeDuration() preserves difficulty
- ✅ Multiple validations: difficulty + title length + duration

**Error message tests**:
- ✅ Error message includes provided value
- ✅ Error message lists valid levels
- ✅ Error instance type correct

**Target coverage**: 100% for domain entity (constitution requirement)

---

## Summary

### New Artifacts

- **Type**: `DifficultyLevel` (string literal union)
- **Error**: `InvalidDifficultyLevelError` (domain error class)
- **Property**: `_difficulty: DifficultyLevel` (private field)
- **Getter**: `difficulty` (read-only accessor)
- **Validator**: `isValidDifficultyLevel()` (type guard)

### Modified Artifacts

- **Talk constructor**: Added 6th parameter `_difficulty: DifficultyLevel`
- **changeDuration()**: Updated to pass difficulty when creating new instance

### Breaking Changes

⚠️ **Constructor signature change**: All Talk instantiations require difficulty parameter

### Compliance

- ✅ Clean Architecture: Zero external dependencies
- ✅ Immutability: Private readonly field + getter
- ✅ Type safety: Union type + type guard
- ✅ Domain errors: InvalidDifficultyLevelError follows established patterns
- ✅ Ubiquitous Language: Domain terminology (Beginner, Intermediate, Advanced)

**Ready for**: Task generation (`/speckit.tasks`) and implementation (`/speckit.implement`)

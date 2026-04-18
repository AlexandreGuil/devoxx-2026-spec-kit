# Phase 1: Data Model - Validate Abstract Length

**Feature**: 004-validate-abstract-length
**Date**: 2026-01-31
**Phase**: Design (Data Model Specification)

## Domain Entities

### Talk Entity (MODIFIED)

**File**: `src/domain/talk.entity.ts`

#### Changes

| Property | Before | After | Change Type |
|----------|--------|-------|-------------|
| `abstract` | `string` (no length limit) | `string` (max 500 chars) | Modified validation |

#### Updated Invariants (Business Rules)

1. **Existing Invariants** (preserved):
   - `id` must be non-empty string
   - `title` must be non-empty string
   - `title` must be ≤ 100 characters (throws `InvalidTitleLengthError`)
   - `speakers` array must contain 1-3 elements (throws `InvalidSpeakerCountError`)
   - `duration` must be 15, 30, 45, or 90 minutes (throws `InvalidDurationError`)

2. **New Invariants** (added):
   - **INV-1**: `abstract` must be ≤ 500 characters
     - Violation: Throws `InvalidAbstractLengthError` with actual length and maximum

#### Validation Logic (Constructor)

```typescript
constructor(
  public readonly id: string,
  public readonly title: string,
  public readonly abstract: string,
  public readonly speakers: string[],
  private readonly _duration: Duration,
) {
  // Existing validations
  if (!id || id.trim() === '') {
    throw new Error('Talk id must be provided');
  }
  if (!title || title.trim() === '') {
    throw new Error('Talk title must be provided');
  }
  if (title.length > 100) {
    throw new InvalidTitleLengthError(title.length);
  }

  // NEW: Abstract length validation
  if (abstract.length > 500) {
    throw new InvalidAbstractLengthError(abstract.length, 500);
  }

  // Existing validations (speakers, duration)
  if (!speakers || speakers.length === 0) {
    throw new Error('At least one speaker is required');
  }
  if (speakers.length > 3) {
    throw new InvalidSpeakerCountError(speakers.length, 3);
  }
  if (!this.isValidDuration(_duration)) {
    throw new InvalidDurationError(_duration);
  }
}
```

---

## Domain Errors

### InvalidAbstractLengthError (NEW)

**File**: `src/domain/talk.entity.ts`
**Location**: Export at top of file (after `InvalidSpeakerCountError`, before `Talk` class)

#### Type Definition

```typescript
/**
 * InvalidAbstractLengthError (Domain Error)
 * Thrown when a talk abstract exceeds the maximum allowed length of 500 characters.
 */
export class InvalidAbstractLengthError extends Error {
  constructor(actualLength: number, maxLength: number) {
    super(
      `Abstract length (${actualLength} characters) exceeds the maximum allowed length of ${maxLength} characters`,
    );
    this.name = 'InvalidAbstractLengthError';
  }
}
```

#### Error Properties

| Property | Type | Value | Description |
|----------|------|-------|-------------|
| `name` | `string` | `"InvalidAbstractLengthError"` | Error class name for type checking |
| `message` | `string` | `"Abstract length (X characters) exceeds the maximum allowed length of 500 characters"` | Human-readable error message |

#### Usage Example

```typescript
// Throwing the error
if (abstract.length > 500) {
  throw new InvalidAbstractLengthError(abstract.length, 500);
}

// Catching the error
try {
  const talk = new Talk(id, title, longAbstract, speakers, 45);
} catch (error) {
  if (error instanceof InvalidAbstractLengthError) {
    console.error("Abstract too long:", error.message);
    // Output: "Abstract length (600 characters) exceeds the maximum allowed length of 500 characters"
  }
}
```

---

## Value Objects

### Duration (NO CHANGE)

**File**: `src/domain/talk.entity.ts`

No changes to existing `Duration` type:
```typescript
export type Duration = 15 | 30 | 45 | 90;
```

---

## Repository Interfaces

### TalkRepository (NO CHANGE)

**File**: `src/domain/talk.repository.ts`

No changes to repository interface. The interface accepts and returns `Talk` entities. Since the validation is internal to the entity constructor, repository implementations do not need any updates.

```typescript
export interface TalkRepository {
  save(talk: Talk): Promise<void>;
  findById(id: string): Promise<Talk | undefined>;
  findAll(): Promise<Talk[]>;
}
```

**Impact**: Repository implementations will automatically enforce the new validation rule when instantiating Talk entities. No code changes needed in repositories.

---

## Data Flow

### Before (Current)

```
User Input → Use Case → Talk Entity (no abstract length check) → Store
```

**Constructor Call**:
```typescript
const talk = new Talk(id, title, veryLongAbstract, speakers, 45);
// No error even if abstract > 500 chars
```

### After (New)

```
User Input → Use Case → Talk Entity (validates abstract ≤ 500 chars) → Store
```

**Constructor Call**:
```typescript
const talk = new Talk(id, title, longAbstract, speakers, 45);
// Throws InvalidAbstractLengthError if abstract > 500 chars
```

**Validation Point**:
- If `abstract.length > 500`: Throw `InvalidAbstractLengthError`
- If `abstract.length ≤ 500`: Success

---

## Immutability

**Preserved**: The Talk entity remains fully immutable.

- All properties are `readonly`
- No setters or mutation methods for `abstract`
- No changes to existing mutation methods (e.g., `changeDuration` remains unchanged)

---

## Test Data Examples

### Valid Cases

```typescript
// 400 characters (valid)
const abstract400 = 'A'.repeat(400);
new Talk("1", "Title", abstract400, ["Alice"], 45);

// 500 characters (maximum, valid)
const abstract500 = 'B'.repeat(500);
new Talk("2", "Title", abstract500, ["Bob"], 45);

// Short abstract (valid)
new Talk("3", "Title", "Brief description", ["Carol"], 90);

// Empty abstract (valid - no minimum enforced)
new Talk("4", "Title", "", ["Dave"], 15);
```

### Invalid Cases

```typescript
// 501 characters (exceeds maximum)
const abstract501 = 'A'.repeat(501);
new Talk("5", "Title", abstract501, ["Eve"], 45);
// Throws: InvalidAbstractLengthError(501, 500)

// 600 characters (exceeds maximum)
const abstract600 = 'B'.repeat(600);
new Talk("6", "Title", abstract600, ["Frank"], 45);
// Throws: InvalidAbstractLengthError(600, 500)

// 1000 characters (far exceeds maximum)
const abstract1000 = 'C'.repeat(1000);
new Talk("7", "Title", abstract1000, ["Grace"], 90);
// Throws: InvalidAbstractLengthError(1000, 500)
```

---

## Character Counting Behavior

### Standard Characters

```typescript
const abstract = "This is a standard abstract."; // 29 characters
expect(abstract.length).toBe(29);
```

### Special Characters (Emoji)

```typescript
// Emoji counts as 2 characters (UTF-16 surrogate pair)
const abstractEmoji = "🎉 Great talk!"; // 14 characters (not 13)
expect(abstractEmoji.length).toBe(14);
```

### Accented Characters

```typescript
// Accented characters count as 1 character each
const abstractAccent = "Café français"; // 13 characters
expect(abstractAccent.length).toBe(13);
```

### Newlines

```typescript
// Newlines count as 1 character
const abstractNewline = "First line\nSecond line"; // 22 characters
expect(abstractNewline.length).toBe(22);
```

**Note**: Character counting behavior is consistent with existing `InvalidTitleLengthError` validation (uses JavaScript's native `string.length`).

---

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| Validate in constructor | Fail-fast principle. Entity cannot exist in invalid state. |
| Maximum 500 characters | Business constraint (mobile display, user experience). |
| Separate error class | Follows existing patterns (`InvalidTitleLengthError`, `InvalidSpeakerCountError`). |
| Use string.length | Consistent with title validation. Zero dependencies. |
| No minimum length | Out of scope (documented assumption). |
| Validation order after title | Logical grouping of length validations. |

---

**Data Model Complete**: Entity and error specifications finalized. Ready for quickstart examples.

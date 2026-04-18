# Phase 1: Data Model - Limit Number of Speakers per Talk

**Feature**: 003-limit-speakers
**Date**: 2026-01-31
**Phase**: Design (Data Model Specification)

## Domain Entities

### Talk Entity (MODIFIED)

**File**: `src/domain/talk.entity.ts`

#### Changes

| Property | Before | After | Change Type |
|----------|--------|-------|-------------|
| `speakerName` | `string` | REMOVED | Breaking |
| `speakers` | N/A | `string[]` | New |

#### Updated Type Definition

```typescript
export class Talk {
  constructor(
    public readonly id: string,
    public readonly title: string,
    public readonly abstract: string,
    public readonly speakers: string[],  // ← CHANGED: was speakerName: string
    private readonly _duration: Duration,
  )
}
```

#### Invariants (Business Rules)

1. **Existing Invariants** (preserved):
   - `id` must be non-empty string
   - `title` must be non-empty string
   - `title` must be ≤ 100 characters (throws `InvalidTitleLengthError`)
   - `duration` must be 15, 30, 45, or 90 minutes (throws `InvalidDurationError`)

2. **New Invariants** (added):
   - **INV-1**: `speakers` array must contain at least 1 element
     - Violation: Throws generic `Error` with message "At least one speaker is required"
   - **INV-2**: `speakers` array must contain at most 3 elements
     - Violation: Throws `InvalidSpeakerCountError` with actual count and maximum

#### Validation Logic (Constructor)

```typescript
constructor(
  public readonly id: string,
  public readonly title: string,
  public readonly abstract: string,
  public readonly speakers: string[],
  private readonly _duration: Duration,
) {
  // Existing validations (lines 56-70 in current file)
  if (!id || id.trim() === '') {
    throw new Error('Talk id must be provided');
  }
  if (!title || title.trim() === '') {
    throw new Error('Talk title must be provided');
  }
  if (title.length > 100) {
    throw new InvalidTitleLengthError(title.length);
  }

  // NEW: Speaker count validation
  if (!speakers || speakers.length === 0) {
    throw new Error('At least one speaker is required');
  }
  if (speakers.length > 3) {
    throw new InvalidSpeakerCountError(speakers.length, 3);
  }

  // Existing duration validation (lines 68-70)
  if (!this.isValidDuration(_duration)) {
    throw new InvalidDurationError(_duration);
  }
}
```

---

## Domain Errors

### InvalidSpeakerCountError (NEW)

**File**: `src/domain/talk.entity.ts`
**Location**: Export at top of file (after `InvalidTitleLengthError`, before `Talk` class)

#### Type Definition

```typescript
/**
 * InvalidSpeakerCountError (Domain Error)
 * Thrown when a talk has more than the maximum allowed number of speakers (3).
 */
export class InvalidSpeakerCountError extends Error {
  constructor(actualCount: number, maxCount: number) {
    super(
      `Speaker count (${actualCount} speakers) exceeds the maximum allowed (${maxCount} speakers)`,
    );
    this.name = 'InvalidSpeakerCountError';
  }
}
```

#### Error Properties

| Property | Type | Value | Description |
|----------|------|-------|-------------|
| `name` | `string` | `"InvalidSpeakerCountError"` | Error class name for type checking |
| `message` | `string` | `"Speaker count (X speakers) exceeds the maximum allowed (3 speakers)"` | Human-readable error message |

#### Usage Example

```typescript
// Throwing the error
if (speakers.length > 3) {
  throw new InvalidSpeakerCountError(speakers.length, 3);
}

// Catching the error
try {
  const talk = new Talk(id, title, abstract, ["A", "B", "C", "D"], 45);
} catch (error) {
  if (error instanceof InvalidSpeakerCountError) {
    console.error("Too many speakers:", error.message);
    // Output: "Speaker count (4 speakers) exceeds the maximum allowed (3 speakers)"
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

No changes to repository interface. The interface accepts and returns `Talk` entities. Since the entity's public API remains compatible (immutable, readonly properties), repository implementations do not need updates beyond adjusting Talk instantiation code.

```typescript
export interface TalkRepository {
  save(talk: Talk): Promise<void>;
  findById(id: string): Promise<Talk | undefined>;
  findAll(): Promise<Talk[]>;
}
```

**Impact**: Repository implementations (e.g., `InMemoryTalkRepository`) will need to update Talk instantiation calls to pass `speakers: string[]` instead of `speakerName: string`, but the interface contract itself is unchanged.

---

## Data Flow

### Before (Current)

```
User Input → Use Case → Talk Entity
             (speakerName: "John Doe") → Store
```

**Constructor Call**:
```typescript
const talk = new Talk(id, title, abstract, "John Doe", 45);
```

### After (New)

```
User Input → Use Case → Talk Entity
             (speakers: ["John Doe", "Jane Smith"]) → Store
```

**Constructor Call**:
```typescript
const talk = new Talk(id, title, abstract, ["John Doe", "Jane Smith"], 45);
```

**Validation Point**:
- If `speakers.length === 0`: Throw generic `Error`
- If `speakers.length > 3`: Throw `InvalidSpeakerCountError`
- If `1 <= speakers.length <= 3`: Success

---

## Immutability

**Preserved**: The Talk entity remains fully immutable.

- All properties are `readonly`
- `speakers` array is exposed as readonly (no mutation methods provided)
- No setters or mutation methods for `speakers`
- Future consideration: If mutation is needed, add method like `addSpeaker(name: string): Talk` that returns new instance (following existing `changeDuration` pattern on line 102)

---

## Test Data Examples

### Valid Cases

```typescript
// 1 speaker (minimum)
new Talk("1", "Title", "Abstract", ["Alice"], 45);

// 2 speakers
new Talk("2", "Title", "Abstract", ["Alice", "Bob"], 45);

// 3 speakers (maximum)
new Talk("3", "Title", "Abstract", ["Alice", "Bob", "Charlie"], 90);
```

### Invalid Cases

```typescript
// 0 speakers (empty array)
new Talk("4", "Title", "Abstract", [], 45);
// Throws: Error("At least one speaker is required")

// 4 speakers (exceeds maximum)
new Talk("5", "Title", "Abstract", ["A", "B", "C", "D"], 45);
// Throws: InvalidSpeakerCountError(4, 3)

// 5 speakers (exceeds maximum)
new Talk("6", "Title", "Abstract", ["A", "B", "C", "D", "E"], 45);
// Throws: InvalidSpeakerCountError(5, 3)
```

---

## Migration Notes

### Breaking Changes

1. **Constructor Signature**: 4th parameter changed from `string` to `string[]`
2. **Property Access**: `talk.speakerName` → `talk.speakers`

### Code Updates Required

**Application Layer** (`src/application/submit-talk.usecase.ts`):
```typescript
// Before
const talk = new Talk(id, title, abstract, speakerName, duration);

// After
const talk = new Talk(id, title, abstract, [speakerName], duration);
// OR if multiple speakers:
const talk = new Talk(id, title, abstract, speakerNames, duration);
```

**Tests** (`tests/unit/domain/talk.entity.test.ts`):
- All `new Talk(...)` calls must update 4th parameter to array
- Existing tests for title/duration validation remain valid (just update constructor calls)

---

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| Store `speakers` as `string[]` | Type-safe, simple, extensible. Avoids parsing complexity. |
| Validate in constructor | Fail-fast principle. Entity cannot exist in invalid state. |
| Minimum 1 speaker | Talks without speakers are logically invalid (assumption from spec.md:73). |
| Maximum 3 speakers | Business constraint (badge limits, display space, coordination). |
| Separate error class | Follows existing patterns (`InvalidDurationError`, `InvalidTitleLengthError`). |
| No name validation | Out of scope (deferred to future feature, assumption documented). |

---

**Data Model Complete**: Entity and error specifications finalized. Ready for quickstart examples.

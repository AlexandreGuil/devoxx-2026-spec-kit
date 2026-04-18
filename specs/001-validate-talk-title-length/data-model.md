# Data Model: Talk Title Length Validation

**Feature**: 001-validate-talk-title-length
**Date**: 2026-01-31
**Layer**: Domain

## Overview

This feature adds title length validation to the existing Talk entity. No schema changes or new entities are introduced—only validation logic enhancement.

---

## Modified Entity: Talk

**File**: `src/domain/talk.entity.ts`

### Current State (Before Changes)

```typescript
export class Talk {
  constructor(
    public readonly id: string,
    public readonly title: string,
    public readonly abstract: string,
    public readonly speakerName: string,
    private readonly _duration: Duration,
  ) {
    if (!id || id.trim() === '') {
      throw new Error('Talk id must be provided');
    }
    if (!title || title.trim() === '') {
      throw new Error('Talk title must be provided');
    }
    if (!speakerName || speakerName.trim() === '') {
      throw new Error('Talk speakerName must be provided');
    }
    if (!this.isValidDuration(_duration)) {
      throw new InvalidDurationError(_duration);
    }
  }

  // ... rest of implementation
}
```

### Future State (After Changes)

**New Validation Logic**:

```typescript
export class Talk {
  constructor(
    public readonly id: string,
    public readonly title: string,
    public readonly abstract: string,
    public readonly speakerName: string,
    private readonly _duration: Duration,
  ) {
    // ✅ EXISTING: ID validation
    if (!id || id.trim() === '') {
      throw new Error('Talk id must be provided');
    }

    // ✅ EXISTING: Title required validation
    if (!title || title.trim() === '') {
      throw new Error('Talk title must be provided');
    }

    // ⭐ NEW: Title length validation
    if (title.length > 100) {
      throw new InvalidTitleLengthError(title.length);
    }

    // ✅ EXISTING: Speaker validation
    if (!speakerName || speakerName.trim() === '') {
      throw new Error('Talk speakerName must be provided');
    }

    // ✅ EXISTING: Duration validation
    if (!this.isValidDuration(_duration)) {
      throw new InvalidDurationError(_duration);
    }
  }

  // ... rest of implementation unchanged
}
```

**New Domain Error Class**:

```typescript
/**
 * InvalidTitleLengthError (Domain Error)
 * Thrown when a talk title exceeds the maximum allowed length of 100 characters.
 */
export class InvalidTitleLengthError extends Error {
  constructor(actualLength: number) {
    super(
      `Title length (${actualLength} characters) exceeds the maximum allowed length of 100 characters`,
    );
    this.name = 'InvalidTitleLengthError';
  }
}
```

---

## Entity Specification

### Talk Entity

**Purpose**: Represents a conference presentation submitted to Devoxx.

**Layer**: Domain (`src/domain/`)

**Immutability**: Fully immutable (no setters, constructor-only creation)

#### Fields

| Field         | Type       | Constraint                                           | Validation | Change            |
| ------------- | ---------- | ---------------------------------------------------- | ---------- | ----------------- |
| `id`          | `string`   | Non-empty, non-whitespace                            | Existing   | Unchanged         |
| `title`       | `string`   | **NEW**: Non-empty, non-whitespace, ≤ 100 characters | Enhanced   | ⭐ New constraint |
| `abstract`    | `string`   | None                                                 | None       | Unchanged         |
| `speakerName` | `string`   | Non-empty, non-whitespace                            | Existing   | Unchanged         |
| `_duration`   | `Duration` | Must be 15 \| 30 \| 45 \| 90                         | Existing   | Unchanged         |

#### Validation Rules

| Rule ID    | Field         | Validation                                | Error Type                    | Priority   |
| ---------- | ------------- | ----------------------------------------- | ----------------------------- | ---------- |
| VR-001     | `id`          | Must be non-empty and non-whitespace      | Generic `Error`               | Existing   |
| VR-002     | `title`       | Must be non-empty and non-whitespace      | Generic `Error`               | Existing   |
| **VR-003** | **`title`**   | **Length must be ≤ 100 characters**       | **`InvalidTitleLengthError`** | **⭐ New** |
| VR-004     | `speakerName` | Must be non-empty and non-whitespace      | Generic `Error`               | Existing   |
| VR-005     | `_duration`   | Must be valid Devoxx format (15/30/45/90) | `InvalidDurationError`        | Existing   |

**Validation Order** (in constructor):

1. ID validation (VR-001)
2. Title non-empty validation (VR-002)
3. ⭐ **NEW**: Title length validation (VR-003)
4. Speaker validation (VR-004)
5. Duration validation (VR-005)

**Rationale for Ordering**: Title length check comes after empty-string check to avoid redundant error messages. If title is empty, we throw "must be provided" error, not "exceeds length" error.

---

## Domain Errors

### Existing Errors

| Error Class            | Trigger                | Message Format                                                                                                   |
| ---------------------- | ---------------------- | ---------------------------------------------------------------------------------------------------------------- |
| Generic `Error`        | Empty id/title/speaker | `"Talk {field} must be provided"`                                                                                |
| `InvalidDurationError` | Invalid duration value | `"Invalid duration: ${value}. Duration must be 15 (Quickie), 30 (Tools-in-Action), or 45 (Conference) minutes."` |

### New Error

| Error Class                   | Trigger              | Message Format                                                                                     | HTTP Equivalent |
| ----------------------------- | -------------------- | -------------------------------------------------------------------------------------------------- | --------------- |
| **`InvalidTitleLengthError`** | `title.length > 100` | `"Title length (${actualLength} characters) exceeds the maximum allowed length of 100 characters"` | 400 Bad Request |

**Error Hierarchy**:

```
Error (base class)
├── InvalidDurationError (existing)
└── InvalidTitleLengthError (new)
```

**Error Handling**: Application/Infrastructure layers should catch domain errors and translate to appropriate responses (HTTP 400, CLI error message, etc.)

---

## Edge Cases & Boundary Conditions

| Scenario               | Input                             | Expected Behavior                                 | Test Priority          |
| ---------------------- | --------------------------------- | ------------------------------------------------- | ---------------------- |
| **Exact boundary**     | Title with exactly 100 characters | ✅ Valid - Talk instance created                  | P1 (critical)          |
| **Just over boundary** | Title with 101 characters         | ❌ Throws `InvalidTitleLengthError`               | P1 (critical)          |
| **Way over boundary**  | Title with 200 characters         | ❌ Throws `InvalidTitleLengthError`               | P2 (important)         |
| **Normal case**        | Title with 50 characters          | ✅ Valid - Talk instance created                  | P2 (important)         |
| **Empty title**        | `""`                              | ❌ Existing validation catches (VR-002)           | P2 (existing coverage) |
| **Whitespace-only**    | `"   "`                           | ❌ Existing validation catches (`.trim() === ""`) | P3 (existing coverage) |
| **Unicode/accented**   | `"Café Français 2026"`            | ✅ Counted correctly by `.length`                 | P2 (important)         |
| **Emoji in title**     | `"🎉 Party Talk"`                 | ⚠️ Emoji counts as 2 chars (documented edge case) | P3 (acceptable)        |
| **Null title**         | `null`                            | ❌ TypeScript prevents (compile-time error)       | N/A (type safety)      |
| **Undefined title**    | `undefined`                       | ❌ TypeScript prevents (compile-time error)       | N/A (type safety)      |

---

## Invariants

**Domain Invariants** (conditions that MUST always be true for a Talk entity):

1. ✅ **Existing**: Talk must have a non-empty id
2. ✅ **Existing**: Talk must have a non-empty title
3. ⭐ **NEW**: Talk title must be 100 characters or less
4. ✅ **Existing**: Talk must have a non-empty speaker name
5. ✅ **Existing**: Talk duration must be a valid Devoxx format (15/30/45/90)

**Enforcement**: All invariants enforced in constructor. Entity is immutable post-construction.

---

## State Transitions

**N/A** - Talk entity is immutable. No state transitions occur after construction.

**Note**: If future requirements introduce title updates, they would require creating a new Talk instance, which would automatically re-validate the title length.

---

## Relationships

**No changes** to entity relationships. Talk entity relationships remain:

- **Talk → Speaker** (via `speakerName` field) - Unchanged
- **Talk → Duration** (value object) - Unchanged
- **TalkRepository → Talk** (repository interface) - Unchanged

---

## Impact Analysis

### Layer Impact

| Layer              | Files Modified                                | Changes                      | Breaking |
| ------------------ | --------------------------------------------- | ---------------------------- | -------- |
| **Domain**         | `src/domain/talk.entity.ts`                   | Add validation + error class | No\*     |
| **Application**    | None                                          | Transparent validation       | No       |
| **Infrastructure** | None                                          | Transparent validation       | No       |
| **Tests**          | `tests/unit/domain/talk.entity.test.ts` (new) | Create test suite            | No       |

**Breaking Change Analysis**:

- ❌ **Not Breaking**: Existing valid talks (title ≤ 100 chars) remain valid
- ❌ **Not Breaking**: No API signature changes
- ⚠️ **Behavior Change**: New talks with titles > 100 chars will now be rejected (intended feature)

---

## Testing Strategy

### Unit Tests Required

**File**: `tests/unit/domain/talk.entity.test.ts`

**Test Suite**: Talk Title Length Validation

| Test Case                                         | Input             | Expected Output                                              | Type             |
| ------------------------------------------------- | ----------------- | ------------------------------------------------------------ | ---------------- |
| `should accept title with exactly 100 characters` | 100-char title    | ✅ Talk instance created                                     | Boundary         |
| `should reject title with 101 characters`         | 101-char title    | ❌ Throws `InvalidTitleLengthError`                          | Boundary         |
| `should accept title with 50 characters`          | 50-char title     | ✅ Talk instance created                                     | Happy Path       |
| `should reject title with 200 characters`         | 200-char title    | ❌ Throws `InvalidTitleLengthError`                          | Edge Case        |
| `should include actual length in error message`   | 120-char title    | Error message contains "120 characters" and "100 characters" | Error Validation |
| `should handle accented characters correctly`     | `"Café Français"` | ✅ Counted as 14 characters                                  | Unicode          |
| `should count emoji as multiple characters`       | `"🎉 Party"`      | ⚠️ Counted as 8 characters (emoji = 2)                       | Unicode Edge     |
| `should still reject empty title`                 | `""`              | ❌ Existing validation (VR-002)                              | Regression       |

**Coverage Target**: 100% (per Constitution Principle V)

---

## Constants

**Proposed Constant** (optional refactoring):

```typescript
const MAX_TITLE_LENGTH = 100;

// Usage in validation:
if (title.length > MAX_TITLE_LENGTH) {
  throw new InvalidTitleLengthError(title.length);
}
```

**Rationale**:

- ✅ Single source of truth (DRY principle)
- ✅ Easy to update if requirement changes (unlikely given ADR documentation)
- ⚠️ Adds abstraction for a single-use constant

**Decision**: Deferred to implementation. Inline value (`100`) is acceptable given it's referenced only twice (validation check + error message).

---

## Migration Considerations

**Existing Data**: No migration required

- Validation is forward-looking (applies only to new Talk creation/updates)
- Existing talks in any data store are unaffected
- If data cleanup needed (existing talks > 100 chars), separate migration task required

**Recommendation**: Run analytics query to check for existing talks > 100 chars:

```sql
SELECT id, title, LENGTH(title) AS len
FROM talks
WHERE LENGTH(title) > 100
ORDER BY len DESC;
```

If any found, create follow-up task to notify speakers and update titles.

---

## Documentation References

- **ADR**: `docs/adrs/0005-validation-titre.md` (decision rationale)
- **Spec**: `specs/001-validate-talk-title-length/spec.md` (requirements)
- **Research**: `specs/001-validate-talk-title-length/research.md` (technical decisions)
- **Existing Entity**: `src/domain/talk.entity.ts:1-106` (current implementation)

---

**Data Model Status**: ✅ Complete

**Ready for**: Implementation (after test framework setup)

# Phase 0: Research - Limit Number of Speakers per Talk

**Feature**: 003-limit-speakers
**Date**: 2026-01-31
**Phase**: Research (Technical Decisions)

## Research Questions

### RQ1: How should speakers be represented in the Talk entity?

**Current State**: Single string field `speakerName: string` (talk.entity.ts:53)

**Options Considered**:

1. **Keep single string, parse later** (e.g., "John Doe, Jane Smith, Alice Johnson")
   - ❌ Rejected: Parsing logic is error-prone, violates domain clarity
   - ❌ Split responsibility (who validates count? parser or entity?)

2. **Convert to array of strings** `speakers: string[]` ✅ SELECTED
   - ✅ Type-safe: Array length directly enforces count
   - ✅ Clean separation: Each speaker is a distinct value
   - ✅ Validation is trivial: `speakers.length >= 1 && speakers.length <= 3`
   - ✅ Future-proof: Easy to add speaker metadata later (convert to objects)

3. **Create Speaker value object** (e.g., `Speaker { name: string }`)
   - ❌ Rejected for now: Over-engineering for current requirements
   - ⚠️ Consider later if speaker metadata is needed (email, bio, etc.)

**Decision**: Convert `speakerName: string` → `speakers: string[]`

**Breaking Change**: YES
- Constructor signature changes from 4 parameters to 4 parameters (replace `speakerName` with `speakers`)
- All existing code instantiating Talk must be updated
- Repository implementations may need migration logic (future consideration)

**Migration Strategy** (for reference, not implemented in this feature):
```typescript
// Old code
const talk = new Talk(id, title, abstract, "John Doe", duration);

// New code
const talk = new Talk(id, title, abstract, ["John Doe"], duration);
```

---

### RQ2: Where should speaker count validation occur?

**Options Considered**:

1. **Application layer** (in use cases)
   - ❌ Rejected: Validation is a business invariant, not use-case logic
   - ❌ Would allow invalid Talk entities to exist temporarily

2. **Infrastructure layer** (in repositories)
   - ❌ Rejected: Too late - entity already constructed
   - ❌ Violates Clean Architecture (domain rules leak to infrastructure)

3. **Domain layer** (Talk entity constructor) ✅ SELECTED
   - ✅ Fail-fast: Invalid talks cannot be instantiated
   - ✅ Encapsulation: Entity enforces its own invariants
   - ✅ Follows existing patterns (duration, title length validation in constructor)
   - ✅ Single source of truth for validation rules

**Decision**: Enforce validation in Talk entity constructor (domain layer)

**Validation Logic**:
```typescript
constructor(
  public readonly id: string,
  public readonly title: string,
  public readonly abstract: string,
  public readonly speakers: string[],
  private readonly _duration: Duration,
) {
  // Existing validations (id, title, duration)...

  // NEW: Speaker count validation
  if (!speakers || speakers.length === 0) {
    throw new Error('At least one speaker is required');
  }
  if (speakers.length > 3) {
    throw new InvalidSpeakerCountError(speakers.length, 3);
  }
}
```

---

### RQ3: How should speaker count errors be structured?

**Existing Error Patterns** (observed in talk.entity.ts):
- `InvalidDurationError` (line 15): Custom error class with descriptive message
- `InvalidTitleLengthError` (line 28): Custom error class with actual/max values

**Options Considered**:

1. **Generic Error** with custom message
   - ❌ Rejected: Not type-safe, hard to catch specifically
   - ❌ Doesn't follow existing codebase patterns

2. **Custom InvalidSpeakerCountError class** ✅ SELECTED
   - ✅ Follows existing error patterns in codebase
   - ✅ Type-safe: Can be caught specifically in try/catch
   - ✅ Clear intent: Error name documents the violation
   - ✅ Consistent message format with actual/max values

**Decision**: Create `InvalidSpeakerCountError` following existing error patterns

**Error Class Design**:
```typescript
export class InvalidSpeakerCountError extends Error {
  constructor(actualCount: number, maxCount: number) {
    super(
      `Speaker count (${actualCount} speakers) exceeds the maximum allowed (${maxCount} speakers)`,
    );
    this.name = 'InvalidSpeakerCountError';
  }
}
```

**Message Format** (from spec.md FR-004, FR-005):
- Must include actual speaker count: `4 speakers`
- Must include maximum allowed: `3 speakers`
- Must be actionable: User knows what to fix

---

### RQ4: Should individual speaker names be validated?

**Spec Assumption** (spec.md:73): "Assuming individual speaker names are validated elsewhere (non-empty, proper format)"

**Options Considered**:

1. **Validate names in Talk entity** (e.g., reject empty strings, whitespace-only)
   - ⚠️ Mixed signals: Adds responsibility beyond "speaker count"
   - ⚠️ Feature scope creep: Spec is about COUNT, not name quality

2. **Skip name validation** ✅ SELECTED
   - ✅ Out of scope: Feature spec focuses solely on COUNT validation
   - ✅ Separation of concerns: Name validation is a separate requirement
   - ✅ Assumption documented: Spec.md:73 explicitly states this

**Decision**: Do NOT validate individual speaker names in this feature

**Rationale**:
- Feature requirement (spec.md FR-001 through FR-007) focuses exclusively on COUNT
- Individual name validation is a separate concern (possibly future feature)
- Assumption explicitly documented in spec.md:73

**Edge Cases Deferred** (spec.md:47-51):
- Empty speaker names → Out of scope
- Whitespace-only names → Out of scope
- Duplicate speaker names → Out of scope
- Very long names → Out of scope

These edge cases should be addressed in a separate feature if needed.

---

### RQ5: How should the constructor signature change?

**Current Signature** (talk.entity.ts:49-55):
```typescript
constructor(
  public readonly id: string,
  public readonly title: string,
  public readonly abstract: string,
  public readonly speakerName: string,  // ← Single string
  private readonly _duration: Duration,
)
```

**New Signature** (proposed):
```typescript
constructor(
  public readonly id: string,
  public readonly title: string,
  public readonly abstract: string,
  public readonly speakers: string[],  // ← Array of strings
  private readonly _duration: Duration,
)
```

**Parameter Ordering**: Keep existing order, replace `speakerName` with `speakers` in 4th position

**Impact Analysis**:
- `src/application/submit-talk.usecase.ts`: Must pass array instead of string ✅ Expected
- `src/infrastructure/in-memory-talk.repository.ts`: No change (stores Talk instances) ✅ Safe
- `tests/unit/domain/talk.entity.test.ts`: All test cases must update constructor calls ✅ Expected

---

## Summary of Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Speaker representation | `speakers: string[]` | Type-safe, clean, future-proof |
| Validation location | Talk entity constructor | Fail-fast, encapsulation, follows existing patterns |
| Error type | `InvalidSpeakerCountError` | Follows existing error patterns, type-safe |
| Name validation | Not implemented | Out of scope (documented assumption) |
| Breaking change | Accept | Necessary for type safety and clarity |

---

## Next Steps (Phase 1)

1. Create `data-model.md` with detailed entity and error specifications
2. Create `quickstart.md` with usage examples (before/after)
3. Create `contracts/InvalidSpeakerCountError.contract.md` for error behavior
4. Update `.claude/CLAUDE.md` with new domain concepts
5. Generate `tasks.md` via `/speckit.tasks` command (Phase 2)

---

**Research Complete**: All technical decisions made. Ready for Phase 1 (design artifacts).

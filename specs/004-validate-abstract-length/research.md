# Phase 0: Research - Validate Abstract Length

**Feature**: 004-validate-abstract-length
**Date**: 2026-01-31
**Phase**: Research (Technical Decisions)

## Research Questions

### RQ1: Where should abstract length validation be placed?

**Current State**: Abstract field exists in Talk entity but has no length validation (talk.entity.ts:51)

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
   - ✅ Follows existing patterns (title length validation in constructor)
   - ✅ Single source of truth for validation rules

**Decision**: Enforce validation in Talk entity constructor (domain layer)

**Validation Logic**:
```typescript
constructor(...) {
  // Existing validations...

  // NEW: Abstract length validation
  if (abstract.length > 500) {
    throw new InvalidAbstractLengthError(abstract.length, 500);
  }
}
```

---

### RQ2: What error pattern should be used?

**Existing Error Patterns** (observed in talk.entity.ts):
- `InvalidDurationError` (line 14): Custom error class with descriptive message
- `InvalidTitleLengthError` (line 27): Custom error class with actual/max values
- `InvalidSpeakerCountError` (Feature 003): Custom error class with actual/max values

**Options Considered**:

1. **Generic Error** with custom message
   - ❌ Rejected: Not type-safe, hard to catch specifically
   - ❌ Doesn't follow existing codebase patterns

2. **Reuse InvalidTitleLengthError**
   - ❌ Rejected: Title and abstract are different concepts
   - ❌ Error name would be misleading
   - ❌ Violates Single Responsibility Principle

3. **Custom InvalidAbstractLengthError class** ✅ SELECTED
   - ✅ Follows existing error patterns in codebase
   - ✅ Type-safe: Can be caught specifically in try/catch
   - ✅ Clear intent: Error name documents the violation
   - ✅ Consistent message format with actual/max values (like InvalidTitleLengthError)

**Decision**: Create `InvalidAbstractLengthError` following existing error patterns

**Error Class Design**:
```typescript
export class InvalidAbstractLengthError extends Error {
  constructor(actualLength: number, maxLength: number) {
    super(
      `Abstract length (${actualLength} characters) exceeds the maximum allowed length of ${maxLength} characters`,
    );
    this.name = 'InvalidAbstractLengthError';
  }
}
```

**Message Format** (from spec.md FR-004, FR-005):
- Must include actual abstract length: `501 characters`
- Must include maximum allowed: `500 characters`
- Must be actionable: User knows what to fix

**Consistency with Existing Patterns**:
- Matches `InvalidTitleLengthError` format exactly
- Uses same parameter order: `actualLength, maxLength`
- Uses same message structure: `"X length (Y characters) exceeds the maximum allowed length of Z characters"`

---

### RQ3: What is the maximum character limit?

**Requirement from spec.md**: 500 characters maximum

**Rationale** (from context):
- Mobile app display constraints
- Screen space limitations on mobile devices
- Prevents layout overflow and broken UI

**Options Considered**:

1. **Shorter limit (300-400 characters)**
   - ❌ Rejected: Too restrictive for detailed talk descriptions
   - ❌ Would require existing abstracts to be truncated

2. **Longer limit (800-1000 characters)**
   - ❌ Rejected: Defeats mobile display purpose
   - ❌ Would still cause overflow issues

3. **500 characters** ✅ SELECTED
   - ✅ Specified in requirements (FR-001)
   - ✅ Balances mobile display constraints with content needs
   - ✅ Industry standard for similar mobile app scenarios
   - ✅ Approximately 2-3 sentences of description

**Decision**: 500 character maximum limit

**Justification**: This limit ensures abstracts fit comfortably on mobile screens while allowing sufficient space for meaningful talk descriptions. Based on mobile UX best practices and specified business requirements.

---

### RQ4: How should character counting work?

**Requirement from spec.md FR-007**: Use JavaScript's standard string length (UTF-16 code units)

**Options Considered**:

1. **Grapheme cluster counting** (user-perceived characters)
   - ❌ Rejected: Complex, requires external library
   - ❌ Inconsistent with existing title validation
   - ❌ Violates "zero external dependencies" constraint

2. **Byte length counting** (UTF-8 bytes)
   - ❌ Rejected: Inconsistent with JavaScript's string.length
   - ❌ Different from existing title validation

3. **JavaScript string.length** (UTF-16 code units) ✅ SELECTED
   - ✅ Consistent with existing `InvalidTitleLengthError` validation
   - ✅ Native JavaScript, zero dependencies
   - ✅ Simple and predictable behavior
   - ✅ Same as title validation (spec.md assumption)

**Decision**: Use `abstract.length` (JavaScript's native string length property)

**Known Edge Cases** (documented, not handled differently):
- Emoji count as 2 characters (UTF-16 surrogate pairs)
- Accented characters count as 1 character each
- Newline characters (`\n`) count as 1 character
- **Consistent with existing title validation behavior**

---

### RQ5: Should there be a minimum length requirement?

**Spec.md Assumption** (line 72): "Assuming empty abstracts are allowed (validation only enforces maximum)"

**Options Considered**:

1. **Enforce minimum length** (e.g., 50 characters)
   - ❌ Rejected: Not specified in requirements
   - ❌ Out of scope for this feature
   - ❌ May prevent legitimate short abstracts

2. **No minimum length** ✅ SELECTED
   - ✅ Requirement only specifies maximum (FR-001: "exceeding 500 characters")
   - ✅ Assumption explicitly documented in spec.md
   - ✅ Existing abstract validation handles null/empty cases
   - ✅ Simpler implementation

**Decision**: No minimum length validation in this feature

**Rationale**: The spec only requires maximum length enforcement. Minimum length validation is a separate concern that can be addressed in a future feature if needed.

---

### RQ6: Should validation order be changed?

**Current Validation Order** (in Talk constructor):
1. id validation
2. title validation (including title length)
3. speakerName validation
4. duration validation

**New Validation Order** (proposed):
1. id validation
2. title validation (including title length)
3. **abstract length validation** ← NEW
4. speakerName validation
5. duration validation

**Decision**: Insert abstract validation after title validation

**Rationale**:
- Logical grouping: Keep length validations together (title length, then abstract length)
- Fail-fast: Check format/length constraints before business rule validations
- Maintains readability: Similar validations are adjacent

---

## Summary of Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Validation location | Talk entity constructor | Fail-fast, encapsulation, follows existing patterns |
| Error type | `InvalidAbstractLengthError` | Follows existing error patterns, type-safe |
| Character limit | 500 characters | Mobile display constraints, business requirement |
| Character counting | JavaScript `string.length` | Consistent with title validation, zero dependencies |
| Minimum length | Not enforced | Out of scope, documented assumption |
| Validation order | After title, before speaker | Logical grouping with other length validations |

---

## Next Steps (Phase 1)

1. Create `data-model.md` with detailed entity and error specifications
2. Create `quickstart.md` with usage examples
3. Create `contracts/InvalidAbstractLengthError.contract.md` for error behavior
4. Update `.claude/CLAUDE.md` with new domain concepts
5. Generate `tasks.md` via `/speckit.tasks` command (Phase 2)

---

**Research Complete**: All technical decisions made. Ready for Phase 1 (design artifacts).

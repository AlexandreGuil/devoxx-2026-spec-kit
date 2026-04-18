# Research: Talk Title Length Validation

**Feature**: 001-validate-talk-title-length
**Date**: 2026-01-31
**Status**: Complete

## Overview

Research conducted to support implementation of title length validation for Talk entities. This document consolidates technical decisions and rationale for the validation approach.

## Technical Decisions

### 1. Unicode Character Counting

**Context**: Need to count characters in talk titles to enforce 100-character limit. Must handle accented characters (é, ñ, ü) correctly as mentioned in feature requirements.

**Research Question**: What method should we use to count characters in TypeScript strings?

**Options Evaluated**:

| Method                                 | Pros                                                                                     | Cons                                                                   | Verdict                              |
| -------------------------------------- | ---------------------------------------------------------------------------------------- | ---------------------------------------------------------------------- | ------------------------------------ |
| Native `.length` property              | Simple, zero dependencies, fast, handles BMP characters correctly (Latin, accented, CJK) | Counts surrogate pairs (emojis) as 2 code units                        | ✅ **SELECTED**                      |
| `Array.from(str).length`               | Correctly counts surrogate pairs as single characters                                    | Slight performance overhead, still doesn't handle combining diacritics | ❌ Rejected (overkill)               |
| `Intl.Segmenter` API                   | Accurate grapheme cluster counting                                                       | Browser/Node 16+ only, adds complexity                                 | ❌ Rejected (unnecessary)            |
| External library (`grapheme-splitter`) | Handles all Unicode edge cases                                                           | Violates Clean Architecture (domain dependency)                        | ❌ Rejected (constitution violation) |

**Decision**: Use native `.length` property

**Rationale**:

- **Simplicity**: No external dependencies, aligns with Clean Architecture Principle I (domain must have zero external dependencies)
- **Sufficient for use case**: Conference talk titles rarely contain emojis or exotic Unicode characters
- **Specification alignment**: User spec mentions "accented characters" which `.length` handles correctly
- **Performance**: Instant validation (<1ms) with zero overhead
- **Documented edge case**: Emojis may be counted as 2 characters (acceptable trade-off given low frequency)

**Code Example**:

```typescript
'Hello World'.length === 11; // ✅ Works
'Café Français'.length === 14; // ✅ Works (accented characters)
'日本語のタイトル'.length === 8; // ✅ Works (CJK characters)
'🎉 Party'.length === 8; // ⚠️ Emoji counts as 2 (acceptable edge case)
```

**Assumption Documented**: `ASMP-001` in spec - Character counting uses Unicode character count (`.length`), not byte count. Exotic Unicode characters (emoji, combining diacritics) may count differently, but this is acceptable for conference talk title use case.

---

### 2. Error Message Design

**Context**: Per FR-004, error message must include both actual character count and maximum allowed length.

**Research Question**: What's the optimal error message format for user clarity?

**User Story Reference**: P2 - "Error message provides actionable feedback"

**Message Template Options**:

| Template                                                                                        | Clarity                 | Actionability                                | Consistency with Codebase                     | Verdict                                    |
| ----------------------------------------------------------------------------------------------- | ----------------------- | -------------------------------------------- | --------------------------------------------- | ------------------------------------------ |
| `"Title length (${actual} characters) exceeds the maximum allowed length of ${max} characters"` | High - explicit numbers | High - tells user exactly how much to reduce | High - matches `InvalidDurationError` pattern | ✅ **SELECTED**                            |
| `"Title too long (max ${max} characters)"`                                                      | Medium                  | Low - doesn't show actual length             | Low - too terse                               | ❌ Rejected                                |
| `"Title must be ${max} characters or less (currently ${actual})"`                               | High                    | High                                         | Medium - different phrasing                   | ❌ Rejected (inconsistent)                 |
| Technical: `"String.length > MAX_TITLE_LENGTH"`                                                 | Low - technical jargon  | Low - not user-friendly                      | N/A                                           | ❌ Rejected (violates Ubiquitous Language) |

**Decision**: `"Title length (${actualLength} characters) exceeds the maximum allowed length of 100 characters"`

**Rationale**:

- **User-centric**: Clear, non-technical language
- **Actionable**: User knows exact current length and target length
- **Consistent**: Matches existing error pattern in `InvalidDurationError`
- **Ubiquitous Language**: Uses domain terms ("title", "length", "maximum"), not technical jargon

**Example Output**:

```
InvalidTitleLengthError: Title length (120 characters) exceeds the maximum allowed length of 100 characters
```

---

### 3. Validation Placement Strategy

**Context**: Where should title length validation logic reside?

**Architectural Options**:

| Location                      | Pros                                                      | Cons                                                 | Constitution Compliance             | Verdict         |
| ----------------------------- | --------------------------------------------------------- | ---------------------------------------------------- | ----------------------------------- | --------------- |
| **Domain Entity Constructor** | Fail-fast, enforces invariant, prevents invalid instances | N/A                                                  | ✅ Principle I (Clean Architecture) | ✅ **SELECTED** |
| Application Layer Use Case    | Could aggregate multiple validations                      | Domain invariants leak into application layer        | ❌ Violates separation of concerns  | ❌ Rejected     |
| Infrastructure Repository     | Validates before persistence                              | Too late - invalid entities exist in memory          | ❌ Violates domain-first principle  | ❌ Rejected     |
| Separate Validator Class      | Reusable validation logic                                 | Allows invalid entity instantiation, adds complexity | ⚠️ Overkill for single check        | ❌ Rejected     |

**Decision**: Validate in Talk entity constructor

**Rationale**:

- **Domain Invariant**: Title length <= 100 is a business rule that must ALWAYS be true for a Talk entity
- **Fail-Fast Principle**: Reject invalid state at creation time (constructor)
- **Consistency**: Matches existing pattern (`InvalidDurationError` thrown in constructor)
- **Immutability**: Talk entities are immutable; constructor is the sole creation point
- **Clean Architecture**: Domain logic stays in domain layer (Principle I compliance)

**Code Location**: `src/domain/talk.entity.ts` constructor, line ~47 (after existing validations)

---

### 4. Test Strategy & Framework Selection

**Context**: Constitution Principle V requires TDD with 100% domain layer coverage. No test framework currently configured.

**Test Framework Options**:

| Framework                    | Pros                                                       | Cons                                            | Alignment with Project                   | Verdict                       |
| ---------------------------- | ---------------------------------------------------------- | ----------------------------------------------- | ---------------------------------------- | ----------------------------- |
| **Vitest**                   | Fast, ESM-native, modern tooling, Vite-compatible          | Newer (less mature than Jest)                   | ✅ Project uses `"type": "module"` (ESM) | ✅ **RECOMMENDED**            |
| Jest                         | Most popular, rich ecosystem, excellent TypeScript support | ESM support requires config, slower than Vitest | ⚠️ Needs ESM config (`jest.config.mjs`)  | ⚠️ Alternative choice         |
| Node.js native (`node:test`) | Zero dependencies, built-in since Node 20+                 | Limited features, no coverage built-in          | ✅ Node 20+ requirement met              | ❌ Too basic for TDD workflow |
| Mocha + Chai                 | Flexible, established                                      | Requires multiple packages, verbose setup       | ❌ Old-school, not modern                | ❌ Rejected                   |

**Decision**: Recommend Vitest (deferred to implementation)

**Rationale**:

- **ESM-native**: Zero friction with project's `"type": "module"` configuration
- **Fast execution**: HMR-like test re-runs, important for TDD red-green-refactor cycle
- **Modern**: Aligns with TypeScript 5.3, ESNext module resolution
- **Coverage built-in**: `vitest --coverage` with c8/istanbul

**Test Coverage Plan**:

| Test Case                            | Type             | Priority | Expected Outcome                                          |
| ------------------------------------ | ---------------- | -------- | --------------------------------------------------------- |
| Title with exactly 100 characters    | Boundary         | P1       | ✅ Talk instance created successfully                     |
| Title with 101 characters            | Boundary         | P1       | ❌ Throws InvalidTitleLengthError                         |
| Title with 50 characters             | Happy Path       | P2       | ✅ Talk instance created successfully                     |
| Title with 200 characters            | Edge Case        | P2       | ❌ Throws InvalidTitleLengthError with correct message    |
| Empty title                          | Edge Case        | P3       | ❌ Existing validation catches (title required)           |
| Error message includes actual length | Error Validation | P1       | ✅ Message includes "120 characters" and "100 characters" |
| Unicode title (accented chars)       | Unicode          | P2       | ✅ Counts characters correctly                            |
| Emoji in title                       | Unicode Edge     | P3       | ⚠️ Counts emoji as 2 (documented behavior)                |

**Test File Location**: `tests/unit/domain/talk.entity.test.ts`

---

### 5. ADR Structure & Content

**Context**: Constitution Principle III requires ADR for all domain/application changes.

**ADR Number**: 0005 (next sequential number)

**ADR Format** (per constitution):

```markdown
# ADR-0005 : Talk Title Length Validation

**Statut** : Accepté
**Date** : 2026-01-31

## Contexte

Les titres de talks trop longs posent des problèmes d'affichage sur :

- Les applications mobiles (largeur d'écran limitée)
- Les programmes papier imprimés (contraintes de mise en page)

## Décision

Limiter la longueur des titres de talks à 100 caractères maximum.

La validation sera implémentée dans le constructeur de l'entité Talk (src/domain/talk.entity.ts).
Le comptage utilise la propriété native `.length` de JavaScript (comptage UTF-16 code units).

## Conséquences

**Positives** :

- Affichage cohérent sur tous les supports (mobile, web, papier)
- Validation fail-fast (rejet à la création de l'entité)
- Aucune dépendance externe (logique pure domaine)

**Négatives** :

- Les speakers doivent reformuler les titres trop longs
- Emojis comptent comme 2 caractères (cas rare, acceptable)

## Alternatives Considérées

- Limites plus longues (150 chars) : Rejetées car problème mobile persiste
- Validation au niveau application : Rejetée (invariant domaine)
- Librairie grapheme-splitter : Rejetée (viole Clean Architecture)
```

**ADR Location**: `docs/adrs/0005-validation-titre.md` (already documented in spec GR-004)

---

## Best Practices Applied

1. **Domain-Driven Design**: Validation encapsulated in domain entity (Talk)
2. **Fail-Fast**: Invalid state rejected at construction time
3. **Clean Architecture**: Zero external dependencies in domain layer
4. **Ubiquitous Language**: Error class uses domain terms (`InvalidTitleLengthError`)
5. **TDD**: Test strategy planned before implementation
6. **Constitution Compliance**: All 6 principles respected

---

## Dependencies Summary

**External Dependencies**: None required ✅

**Internal Dependencies**:

- Modifies: `src/domain/talk.entity.ts` (Talk constructor)
- Creates: `src/domain/talk.entity.ts` (InvalidTitleLengthError class)
- Tests: `tests/unit/domain/talk.entity.test.ts` (new test file)
- Documentation: `docs/adrs/0005-validation-titre.md` (ADR)

**Breaking Changes**: None

- Existing valid talks (title <= 100 chars) remain valid
- Only new validation constraint added
- Additive change, backward compatible

---

## Implementation Impact Analysis

| Layer              | Changes Required                   | Effort                   | Risk                     |
| ------------------ | ---------------------------------- | ------------------------ | ------------------------ |
| **Domain**         | Add validation logic + error class | Low (20 lines)           | Low (isolated change)    |
| **Application**    | None (transparent validation)      | None                     | None                     |
| **Infrastructure** | None (domain-level validation)     | None                     | None                     |
| **Tests**          | Create unit tests (8 test cases)   | Medium (setup framework) | Low (pure logic testing) |
| **Documentation**  | Create ADR-0005                    | Low (1 file)             | None                     |

**Total Effort Estimate**: Small feature (1-2 hours including tests and ADR)

**Risk Assessment**: Very low

- Isolated domain change
- No breaking changes
- Well-defined requirements
- Simple string length validation

---

## Open Questions

**Q1: Should we trim whitespace before checking length?**

- **Answer**: No. Existing validation already trims whitespace for empty-string check. Users should see exact character count including intentional spaces.

**Q2: Should we support internationalization for error messages?**

- **Answer**: Deferred. Error messages in English (codebase language). Presentation layer can translate if needed in future.

**Q3: Should we validate on title updates (if entity becomes mutable)?**

- **Answer**: Not applicable. Talk entity is immutable (no setter methods). Future title updates would require new Talk instance via constructor, automatically validated.

---

**Research Status**: ✅ Complete

**Ready for**: Phase 1 (Design & Data Model)

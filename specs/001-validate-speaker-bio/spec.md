# Feature Specification: Validate Speaker Bio

**Feature Branch**: `001-validate-speaker-bio`
**Created**: 2026-03-17
**Status**: Draft
**Input**: User description: "Lors de la soumission d'un talk au CFP Devoxx, le speaker doit obligatoirement fournir une biographie professionnelle. La bio doit contenir entre 50 et 500 caractères. Une bio trop courte ou trop longue doit être rejetée avec un message d'erreur explicite indiquant la contrainte violée et la longueur fournie. La validation est une règle métier du domaine, suivant le pattern existant (InvalidDurationError, InvalidTitleLengthError)."

## User Scenarios & Testing _(mandatory)_

### User Story 1 - Submit talk with valid bio (Priority: P1)

A speaker submits a talk to the Devoxx CFP with a bio containing between 50 and 500 characters. The submission is accepted and the talk is created successfully.

**Why this priority**: This is the happy path — the core functionality that must work for any speaker to successfully submit a talk.

**Independent Test**: Can be fully tested by submitting a talk with a 50-character bio and a 500-character bio, both resulting in successful talk creation.

**Acceptance Scenarios**:

1. **Given** a speaker provides a bio of exactly 50 characters, **When** they submit the talk, **Then** the talk is created successfully with no error
2. **Given** a speaker provides a bio of exactly 500 characters, **When** they submit the talk, **Then** the talk is created successfully with no error
3. **Given** a speaker provides a bio of 200 characters, **When** they submit the talk, **Then** the talk is created successfully

---

### User Story 2 - Submit talk with bio too short (Priority: P2)

A speaker provides a bio that is too short (fewer than 50 characters). The submission is rejected with an explicit error message indicating that the bio is too short, the minimum required length (50), and the actual length provided.

**Why this priority**: Bio-too-short is the most common error case — speakers may submit a placeholder or abbreviated bio. Clear feedback is essential to guide correction.

**Independent Test**: Can be fully tested by submitting a talk with a 10-character bio and verifying the rejection message contains the "too short" constraint, the minimum (50), and the actual length (10).

**Acceptance Scenarios**:

1. **Given** a speaker provides a bio of 10 characters, **When** they submit the talk, **Then** the submission is rejected with an error indicating the bio is too short (minimum 50) and the actual length (10)
2. **Given** a speaker provides an empty bio, **When** they submit the talk, **Then** the submission is rejected with an error indicating the bio is too short and the actual length (0)
3. **Given** a speaker provides a bio of exactly 49 characters, **When** they submit the talk, **Then** the submission is rejected with an error indicating the bio is too short

---

### User Story 3 - Submit talk with bio too long (Priority: P3)

A speaker provides a bio that exceeds 500 characters. The submission is rejected with an explicit error message indicating that the bio is too long, the maximum allowed length (500), and the actual length provided.

**Why this priority**: Bio-too-long is less frequent but must be handled symmetrically with the too-short case to ensure complete boundary enforcement.

**Independent Test**: Can be fully tested by submitting a talk with a 600-character bio and verifying the rejection message contains the "too long" constraint, the maximum (500), and the actual length (600).

**Acceptance Scenarios**:

1. **Given** a speaker provides a bio of 600 characters, **When** they submit the talk, **Then** the submission is rejected with an error indicating the bio is too long (maximum 500) and the actual length (600)
2. **Given** a speaker provides a bio of exactly 501 characters, **When** they submit the talk, **Then** the submission is rejected with an error indicating the bio is too long

---

### Edge Cases

- What happens when the bio is exactly at the lower boundary (50 characters)? → Accepted
- What happens when the bio is exactly at the upper boundary (500 characters)? → Accepted
- What happens when the bio is one character below the lower boundary (49 characters)? → Rejected with "too short" error including actual length
- What happens when the bio is one character above the upper boundary (501 characters)? → Rejected with "too long" error including actual length
- What happens when the bio field is absent (null or missing)? → Rejected, treated as length 0 (too short)
- What happens when the bio contains only whitespace? → Treated as empty (length 0 after trimming), rejected as too short

## Requirements _(mandatory)_

### Functional Requirements

- **FR-001**: The system MUST require a speaker bio when submitting a talk to the CFP
- **FR-002**: The system MUST reject a bio shorter than 50 characters with an error message that specifies the violated constraint ("too short"), the minimum required length (50), and the actual length provided
- **FR-003**: The system MUST reject a bio longer than 500 characters with an error message that specifies the violated constraint ("too long"), the maximum allowed length (500), and the actual length provided
- **FR-004**: The system MUST accept a bio containing between 50 and 500 characters (inclusive) without error
- **FR-005**: Bio validation MUST be enforced as a domain rule, consistent with existing domain validation patterns (duration, title length)
- **FR-006**: A missing or blank-only bio MUST be treated as a length-zero bio and rejected with the "too short" error

### Key Entities

- **Speaker Bio**: A professional biography text submitted by the speaker at CFP submission time; constrained to 50–500 characters; describes the speaker's background and expertise
- **InvalidBioLengthError**: A domain error encoding the constraint violation (too short or too long), the applicable boundary (minimum 50 or maximum 500), and the actual length provided

## Success Criteria _(mandatory)_

### Measurable Outcomes

- **SC-001**: 100% of talk submissions with a bio shorter than 50 characters are rejected with an error that names the "too short" constraint and the actual length provided
- **SC-002**: 100% of talk submissions with a bio longer than 500 characters are rejected with an error that names the "too long" constraint and the actual length provided
- **SC-003**: 100% of talk submissions with a bio between 50 and 500 characters (inclusive) are accepted without bio-related errors
- **SC-004**: A speaker who receives a bio validation error can identify the exact correction needed (add or remove characters, and how many) from the error message alone, without consulting documentation
- **SC-005**: The bio validation error follows the same structure and naming convention as existing domain errors, requiring no new patterns for developers to learn

## Governance Requirements _(auto-filled by /speckit.specify)_

### Architecture Compliance

- [ ] **GR-001**: This feature MUST place domain logic in `src/domain/`
- [ ] **GR-002**: This feature MUST NOT introduce forbidden imports (domain → infrastructure)
- [ ] **GR-003**: Implementation MUST follow Clean Architecture layers

### Documentation Compliance

- [ ] **GR-004**: An ADR MUST be created documenting the key decision(s) for this feature
  - ADR Path: `docs/adrs/NNNN-validate-speaker-bio.md`
  - Content: Context, Decision, Consequences, Alternatives

### CI/CD Gate

This specification will be validated automatically on PR:

| Gate      | Validation                 |
| --------- | -------------------------- |
| Structure | Required directories exist |
| Imports   | No layer violations        |
| ADR       | At least one ADR exists    |
| Coherence | AI review passes           |

# Feature Specification: Talk Title Length Validation

**Feature Branch**: `001-validate-talk-title-length`
**Created**: 2026-01-31
**Status**: Draft
**Input**: User description: "Ajouter une validation de longueur du titre des talks.

Contexte:

- Les titres trop longs posent probleme sur mobile et dans le programme papier
- Limite: 100 caracteres maximum

Implementation requise:

- Nouvelle erreur domaine: InvalidTitleLengthError dans src/domain/talk.entity.ts
- Validation dans le constructeur de Talk: if (title.length > 100) throw new InvalidTitleLengthError(title.length)
- Message d'erreur explicite indiquant la longueur actuelle et la limite

ADR requis: docs/adrs/0005-validation-titre.md documentant:

- Le contexte (probleme d'affichage mobile/papier)
- La decision (limite 100 chars)
- Les consequences (speakers doivent reformuler si trop long)

User Stories:

1. [P1] Le systeme rejette un talk dont le titre depasse 100 caracteres
2. [P2] Le message d'erreur indique clairement la longueur actuelle et la limite"

## User Scenarios & Testing

### User Story 1 - System rejects talks with titles exceeding 100 characters (Priority: P1)

When a speaker or administrator attempts to create or update a talk with a title longer than 100 characters, the system must reject the operation and provide clear feedback about the violation.

**Why this priority**: This is the core validation requirement that prevents display issues on mobile devices and in printed conference programs. Without this, the primary business problem remains unsolved.

**Independent Test**: Can be fully tested by attempting to create a talk with a 101-character title and verifying that the system rejects it with an appropriate error message. This delivers immediate value by preventing overly long titles from entering the system.

**Acceptance Scenarios**:

1. **Given** a speaker is creating a new talk, **When** they provide a title with exactly 100 characters, **Then** the system accepts the talk successfully
2. **Given** a speaker is creating a new talk, **When** they provide a title with 101 characters, **Then** the system rejects the talk with an error indicating the title is too long
3. **Given** an existing talk with a valid title, **When** a speaker updates it to 105 characters, **Then** the system rejects the update with an error
4. **Given** a speaker is creating a new talk, **When** they provide a title with 50 characters, **Then** the system accepts the talk successfully

---

### User Story 2 - Error message provides actionable feedback (Priority: P2)

When a title validation fails, the error message must clearly communicate both the current title length and the maximum allowed length, enabling speakers to quickly understand and fix the issue.

**Why this priority**: While the validation itself (P1) is essential for preventing the problem, clear error messaging significantly improves user experience and reduces friction for speakers who encounter the limit. It's a user experience enhancement to the core validation.

**Independent Test**: Can be fully tested by submitting a title that exceeds the limit and verifying the error message includes both the actual length and the 100-character limit. This delivers value by reducing speaker frustration and support requests.

**Acceptance Scenarios**:

1. **Given** a speaker submits a talk with a 120-character title, **When** the validation fails, **Then** the error message states "Title length (120 characters) exceeds the maximum allowed length of 100 characters"
2. **Given** a speaker submits a talk with a 101-character title, **When** the validation fails, **Then** the error message includes both numbers: current length (101) and limit (100)

---

### Edge Cases

- What happens when a title is exactly 100 characters (boundary test)?
- What happens with empty titles (0 characters)?
- What happens with titles containing special characters, emojis, or multi-byte Unicode characters (do they count correctly)?
- What happens when whitespace padding brings a title over the limit?
- How does the system handle null or undefined title values?

## Requirements

### Functional Requirements

- **FR-001**: System MUST reject any talk whose title exceeds 100 characters
- **FR-002**: System MUST validate title length when creating a new talk
- **FR-003**: System MUST validate title length when updating an existing talk's title
- **FR-004**: System MUST provide an error message that includes both the actual character count and the maximum allowed length (100 characters) when validation fails
- **FR-005**: System MUST accept talks with titles of 100 characters or fewer
- **FR-006**: Character counting MUST handle Unicode characters correctly (e.g., emojis, accented characters count as single characters)

### Key Entities

- **Talk**: Represents a conference presentation submitted by a speaker. Key attributes include title (string, max 100 characters), speaker information, format, and description. The title is a critical display element used across mobile apps, web interfaces, and printed programs.

## Success Criteria

### Measurable Outcomes

- **SC-001**: 100% of talks with titles exceeding 100 characters are rejected at submission time
- **SC-002**: Error messages consistently display both actual and maximum character counts in all validation failure cases
- **SC-003**: No talks with titles exceeding 100 characters exist in the system after feature deployment
- **SC-004**: Speakers can quickly identify and fix title length issues without requiring support assistance

## Dependencies and Assumptions

### Assumptions

- **ASMP-001**: Character counting uses Unicode character count, not byte count (i.e., emojis and accented characters count as single characters)
- **ASMP-002**: Validation occurs at the domain entity level when talks are created or updated
- **ASMP-003**: The existing Talk entity structure supports adding validation logic to the title field

### Dependencies

- **DEP-001**: Existing Talk entity must have a title field that can be validated
- **DEP-002**: System must have error handling mechanisms to surface validation failures to users

## Governance Requirements

### Architecture Compliance

- [ ] **GR-001**: This feature MUST place domain logic in `src/domain/`
- [ ] **GR-002**: This feature MUST NOT introduce forbidden imports (domain → infrastructure)
- [ ] **GR-003**: Implementation MUST follow Clean Architecture layers

### Documentation Compliance

- [ ] **GR-004**: An ADR MUST be created documenting the key decision(s) for this feature
  - ADR Path: `docs/adrs/0005-validation-titre.md`
  - Content: Context (mobile/print display issues), Decision (100 character limit), Consequences (speakers must reformulate overly long titles), Alternatives considered

### CI/CD Gate

This specification will be validated automatically on PR:

| Gate      | Validation                 |
| --------- | -------------------------- |
| Structure | Required directories exist |
| Imports   | No layer violations        |
| ADR       | ADR 0005 exists            |
| Coherence | AI review passes           |

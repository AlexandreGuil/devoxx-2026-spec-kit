# Feature Specification: Validate Abstract Length

**Feature Branch**: `004-validate-abstract-length`
**Created**: 2026-01-31
**Status**: Draft
**Input**: User description: "Ajouter une validation de longueur de l'abstract des talks. Contexte: Les abstracts trop longs posent probleme dans l'app mobile. Limite: 500 caracteres maximum. Implementation requise: Nouvelle erreur domaine: InvalidAbstractLengthError dans src/domain/talk.entity.ts. Validation dans le constructeur de Talk. User Stories: 1. [P1] Le systeme rejette un talk dont l'abstract depasse 500 caracteres 2. [P2] Le message d'erreur indique la longueur actuelle et la limite"

## User Scenarios & Testing _(mandatory)_

### User Story 1 - System Rejects Talks with Abstracts Exceeding 500 Characters (Priority: P1)

The system must prevent submission of talks with abstracts longer than 500 characters to ensure proper display on mobile applications where screen space is limited.

**Why this priority**: This is the core validation requirement. Without this limit, long abstracts will break the mobile app layout, cause display overflow, and degrade user experience. Mobile users represent a significant portion of conference attendees who need to browse talks on-the-go.

**Independent Test**: Can be fully tested by attempting to create a Talk with abstracts of various lengths (400, 500, 501, 600 characters) and verifying that talks with 501+ characters are rejected with appropriate errors while talks with ≤500 characters are accepted.

**Acceptance Scenarios**:

1. **Given** a talk with an abstract of 400 characters, **When** the Talk entity is instantiated, **Then** it should succeed
2. **Given** a talk with an abstract of exactly 500 characters (maximum), **When** the Talk entity is instantiated, **Then** it should succeed
3. **Given** a talk with an abstract of 501 characters, **When** the Talk entity is instantiated, **Then** it should throw InvalidAbstractLengthError
4. **Given** a talk with an abstract of 600 characters, **When** the Talk entity is instantiated, **Then** it should throw InvalidAbstractLengthError
5. **Given** a talk with an abstract of 1000 characters, **When** the Talk entity is instantiated, **Then** it should throw InvalidAbstractLengthError

---

### User Story 2 - Clear Error Messages for Invalid Abstract Length (Priority: P2)

When validation fails, the system must provide clear, actionable error messages that indicate the current abstract length and the maximum allowed (500 characters) to help users quickly correct their submission.

**Why this priority**: Good error messages improve user experience and reduce support burden. Users should immediately understand what went wrong (abstract too long) and how to fix it (reduce to 500 characters maximum).

**Independent Test**: Can be fully tested by triggering validation errors with different abstract lengths and verifying the error message content includes both the actual length and the limit.

**Acceptance Scenarios**:

1. **Given** a talk with a 501-character abstract, **When** validation fails, **Then** the error message includes "501 characters" and "maximum 500 characters"
2. **Given** a talk with a 600-character abstract, **When** validation fails, **Then** the error message clearly states "600 characters" and "maximum 500 characters"
3. **Given** a talk with invalid abstract length, **When** validation fails, **Then** the error is an instance of InvalidAbstractLengthError with name property set correctly

---

### Edge Cases

- What happens when the abstract is exactly 500 characters (boundary test)?
- How does the system handle abstracts with special characters (emojis, accents, newlines)?
- What happens if the abstract contains only whitespace characters?
- How does the system count multi-byte Unicode characters (emoji, Chinese characters)?
- What happens if the abstract is null or undefined?

## Requirements _(mandatory)_

### Functional Requirements

- **FR-001**: System MUST reject talks with abstracts exceeding 500 characters
- **FR-002**: System MUST accept talks with abstracts of 500 characters or fewer
- **FR-003**: System MUST throw InvalidAbstractLengthError when abstract length exceeds 500 characters
- **FR-004**: System MUST include the actual abstract length in the error message
- **FR-005**: System MUST include the maximum allowed length (500) in the error message
- **FR-006**: System MUST enforce abstract length validation at the domain layer (Talk entity constructor)
- **FR-007**: System MUST count characters using JavaScript's standard string length (UTF-16 code units)

### Key Entities

- **Talk**: Existing domain entity that will be extended with abstract length validation logic
- **InvalidAbstractLengthError**: New domain error thrown when abstract exceeds 500 characters

### Assumptions

- **Character counting**: Using JavaScript's native `string.length` property (UTF-16 code units), consistent with existing title length validation
- **No minimum length**: Assuming empty abstracts are allowed (validation only enforces maximum)
- **Whitespace handling**: Assuming whitespace-only abstracts are validated elsewhere or allowed
- **Existing validations**: Assuming abstract non-null validation already exists in constructor

## Success Criteria _(mandatory)_

### Measurable Outcomes

- **SC-001**: All talks with abstracts exceeding 500 characters are rejected with appropriate errors (100% validation coverage)
- **SC-002**: All talks with abstracts of 500 characters or fewer can be successfully created
- **SC-003**: Error messages for invalid abstract lengths include both the actual length and the maximum allowed (500)
- **SC-004**: Abstract length validation is enforced at domain entity instantiation (fail-fast principle)
- **SC-005**: Zero talks with abstracts longer than 500 characters can enter the system
- **SC-006**: Mobile app displays all talk abstracts without layout issues or text overflow

## Governance Requirements _(auto-filled by /speckit.specify)_

### Architecture Compliance

- [ ] **GR-001**: This feature MUST place domain logic in `src/domain/`
- [ ] **GR-002**: This feature MUST NOT introduce forbidden imports (domain → infrastructure)
- [ ] **GR-003**: Implementation MUST follow Clean Architecture layers

### Documentation Compliance

- [ ] **GR-004**: An ADR MUST be created documenting the key decision(s) for this feature
  - ADR Path: `docs/adrs/0007-validate-abstract-length.md`
  - Content: Context (mobile display constraints), Decision (500 character limit), Consequences (improved mobile UX), Alternatives (shorter/longer limits considered)

### CI/CD Gate

This specification will be validated automatically on PR:

| Gate      | Validation                 | Status |
| --------- | -------------------------- | ------ |
| Structure | Required directories exist | Active |
| Imports   | No layer violations        | Active |
| ADR       | At least one ADR exists    | Active |
| Coherence | AI review passes           | Active |

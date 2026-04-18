# Feature Specification: Difficulty Level Validation

**Feature Branch**: `002-difficulty-level-validation`
**Created**: 2026-01-31
**Status**: Draft
**Input**: User description: "Ajouter une validation du niveau de difficulté des talks"

## User Scenarios & Testing _(mandatory)_

### User Story 1 - System Rejects Invalid Difficulty Levels (Priority: P1)

The system must prevent creation of talks with invalid difficulty levels to ensure data integrity and prevent downstream processing errors.

**Why this priority**: This is the core validation requirement. Without this, invalid data can enter the system, causing bugs, confusion, and potential runtime errors in dependent systems.

**Independent Test**: Can be fully tested by attempting to create a Talk with various invalid difficulty level values and verifying that appropriate errors are thrown.

**Acceptance Scenarios**:

1. **Given** a talk with all valid properties except difficulty level is set to "Easy", **When** the Talk entity is instantiated, **Then** an InvalidDifficultyLevelError is thrown
2. **Given** a talk with all valid properties except difficulty level is set to "Expert", **When** the Talk entity is instantiated, **Then** an InvalidDifficultyLevelError is thrown
3. **Given** a talk with all valid properties except difficulty level is set to an empty string, **When** the Talk entity is instantiated, **Then** an InvalidDifficultyLevelError is thrown
4. **Given** a talk with all valid properties except difficulty level is set to null or undefined, **When** the Talk entity is instantiated, **Then** an InvalidDifficultyLevelError is thrown
5. **Given** a talk with difficulty level set to "Beginner", **When** the Talk entity is instantiated, **Then** no error is thrown
6. **Given** a talk with difficulty level set to "Intermediate", **When** the Talk entity is instantiated, **Then** no error is thrown
7. **Given** a talk with difficulty level set to "Advanced", **When** the Talk entity is instantiated, **Then** no error is thrown

---

### User Story 2 - Clear Error Messages for Invalid Levels (Priority: P2)

When validation fails, the system must provide clear, actionable error messages that list the valid difficulty levels to help users quickly correct their input.

**Why this priority**: Good error messages improve developer experience and reduce support burden. Users should immediately understand what went wrong and how to fix it.

**Independent Test**: Can be fully tested by triggering validation errors and verifying the error message content includes all valid difficulty levels.

**Acceptance Scenarios**:

1. **Given** a talk with an invalid difficulty level "Easy", **When** validation fails, **Then** the error message includes "Valid levels are: Beginner, Intermediate, Advanced"
2. **Given** a talk with an invalid difficulty level "Expert", **When** validation fails, **Then** the error message clearly states the provided value "Expert" is invalid
3. **Given** a talk with an invalid difficulty level, **When** validation fails, **Then** the error is an instance of InvalidDifficultyLevelError with name property set correctly

---

### User Story 3 - Expose Difficulty Level Property (Priority: P2)

The Talk entity must expose the difficulty level as a read-only property so that consumers can access this information without breaking encapsulation.

**Why this priority**: Required for UI display, filtering, and reporting features. Without this, the difficulty level validation would be isolated and unusable by the rest of the system.

**Independent Test**: Can be fully tested by creating a valid Talk and verifying the difficulty level can be read via a getter property.

**Acceptance Scenarios**:

1. **Given** a talk created with difficulty level "Beginner", **When** accessing the difficulty level property, **Then** the value "Beginner" is returned
2. **Given** a talk created with difficulty level "Intermediate", **When** accessing the difficulty level property, **Then** the value "Intermediate" is returned
3. **Given** a talk created with difficulty level "Advanced", **When** accessing the difficulty level property, **Then** the value "Advanced" is returned
4. **Given** a valid talk, **When** attempting to modify the difficulty level property directly, **Then** the modification is prevented (read-only)

---

### Edge Cases

- What happens when difficulty level is provided with incorrect casing (e.g., "beginner", "BEGINNER", "BeGiNnEr")?
- How does the system handle difficulty level values with leading/trailing whitespace?
- What happens when difficulty level is provided as a number or boolean instead of a string?
- How does the system handle Unicode characters or special characters in difficulty level values?
- What happens during deserialization from JSON if the difficulty level field is missing entirely?

## Requirements _(mandatory)_

### Functional Requirements

- **FR-001**: System MUST define a DifficultyLevel type that allows only "Beginner", "Intermediate", or "Advanced" as valid values
- **FR-002**: System MUST validate the difficulty level property when instantiating a Talk entity
- **FR-003**: System MUST throw an InvalidDifficultyLevelError when an invalid difficulty level is provided
- **FR-004**: System MUST include the invalid value in the error message to aid debugging
- **FR-005**: System MUST list all valid difficulty levels in the error message
- **FR-006**: System MUST expose the difficulty level as a read-only property on the Talk entity
- **FR-007**: System MUST NOT allow modification of the difficulty level after Talk instantiation (immutability)
- **FR-008**: System MUST enforce difficulty level validation at the domain layer (zero external dependencies)

### Key Entities

- **DifficultyLevel**: Union type representing the three valid difficulty levels: "Beginner" | "Intermediate" | "Advanced"
- **InvalidDifficultyLevelError**: Domain error thrown when an invalid difficulty level is provided during Talk entity instantiation
- **Talk**: Existing domain entity that will be extended with a difficulty level property and validation logic

## Success Criteria _(mandatory)_

### Measurable Outcomes

- **SC-001**: All invalid difficulty level values are rejected with appropriate errors (100% validation coverage)
- **SC-002**: All three valid difficulty levels ("Beginner", "Intermediate", "Advanced") can be successfully used to create Talk entities
- **SC-003**: Error messages for invalid difficulty levels include both the invalid value and the list of valid values
- **SC-004**: The difficulty level property is accessible via a read-only getter on the Talk entity
- **SC-005**: Test coverage for difficulty level validation reaches at least 80% (lines, branches, functions, statements)
- **SC-006**: Zero regressions in existing Talk entity functionality (all existing tests continue to pass)

## Governance Requirements _(auto-filled by /speckit.specify)_

### Architecture Compliance

- [ ] **GR-001**: This feature MUST place domain logic in `src/domain/`
- [ ] **GR-002**: This feature MUST NOT introduce forbidden imports (domain → infrastructure)
- [ ] **GR-003**: Implementation MUST follow Clean Architecture layers

### Documentation Compliance

- [ ] **GR-004**: An ADR MUST be created documenting the key decision(s) for this feature
  - ADR Path: `docs/adrs/NNNN-difficulty-level-validation.md`
  - Content: Context (why three levels), Decision (type definition and validation approach), Consequences (type safety vs. runtime validation trade-offs), Alternatives (enum vs. union type)

### CI/CD Gate

This specification will be validated automatically on PR:

| Gate      | Validation                 |
| --------- | -------------------------- |
| Structure | Required directories exist |
| Imports   | No layer violations        |
| ADR       | At least one ADR exists    |
| Coherence | AI review passes           |

# Feature Specification: Limit Number of Speakers per Talk

**Feature Branch**: `003-limit-speakers`
**Created**: 2026-01-31
**Status**: Draft - Urgent (no ADR required)
**Input**: User description: "Limiter le nombre de speakers par talk a 3 maximum"

## User Scenarios & Testing _(mandatory)_

### User Story 1 - System Rejects Talks with More Than 3 Speakers (Priority: P1)

The system must prevent submission of talks with more than 3 speakers to comply with logistical constraints (badge limits, space on program, coordination complexity).

**Why this priority**: This is the core validation requirement. Without this, talks with too many speakers can be submitted, causing logistical problems (insufficient badges, display overflow, difficult coordination).

**Independent Test**: Can be fully tested by attempting to create a Talk with various speaker counts (1, 2, 3, 4, 5 speakers) and verifying that talks with 4+ speakers are rejected with appropriate errors while 1-3 speakers are accepted.

**Acceptance Scenarios**:

1. **Given** a talk with 1 speaker, **When** the Talk entity is instantiated, **Then** it should succeed
2. **Given** a talk with 2 speakers, **When** the Talk entity is instantiated, **Then** it should succeed
3. **Given** a talk with 3 speakers (maximum), **When** the Talk entity is instantiated, **Then** it should succeed
4. **Given** a talk with 4 speakers, **When** the Talk entity is instantiated, **Then** it should throw InvalidSpeakerCountError
5. **Given** a talk with 5 speakers, **When** the Talk entity is instantiated, **Then** it should throw InvalidSpeakerCountError
6. **Given** a talk with 0 speakers (empty list), **When** the Talk entity is instantiated, **Then** it should throw an error (at least 1 speaker required)

---

### User Story 2 - Clear Error Messages for Invalid Speaker Count (Priority: P2)

When validation fails, the system must provide clear, actionable error messages that indicate the current number of speakers and the maximum allowed (3) to help users quickly correct their submission.

**Why this priority**: Good error messages improve user experience and reduce support burden. Users should immediately understand what went wrong (too many speakers) and how to fix it (reduce to 3 maximum).

**Independent Test**: Can be fully tested by triggering validation errors with different speaker counts and verifying the error message content includes both the actual count and the limit.

**Acceptance Scenarios**:

1. **Given** a talk with 4 speakers, **When** validation fails, **Then** the error message includes "4 speakers" and "maximum 3 allowed"
2. **Given** a talk with 5 speakers, **When** validation fails, **Then** the error message clearly states "5 speakers" and "maximum 3 allowed"
3. **Given** a talk with invalid speaker count, **When** validation fails, **Then** the error is an instance of InvalidSpeakerCountError with name property set correctly

---

### Edge Cases

- What happens when speaker names list is empty (0 speakers)?
- How does the system handle duplicate speaker names in the list?
- What happens if speaker names contain only whitespace?
- How does the system handle very long speaker name lists (10+ speakers)?
- What happens if the speaker names parameter is null or undefined?

## Requirements _(mandatory)_

### Functional Requirements

- **FR-001**: System MUST reject talks with more than 3 speakers
- **FR-002**: System MUST accept talks with 1, 2, or 3 speakers
- **FR-003**: System MUST throw InvalidSpeakerCountError when speaker count exceeds 3
- **FR-004**: System MUST include the actual speaker count in the error message
- **FR-005**: System MUST include the maximum allowed count (3) in the error message
- **FR-006**: System MUST enforce speaker count validation at the domain layer (Talk entity)
- **FR-007**: System MUST reject talks with 0 speakers (at least 1 speaker required)

### Key Entities

- **Talk**: Existing domain entity that will be extended with speaker count validation logic
- **InvalidSpeakerCountError**: New domain error thrown when speaker count exceeds 3 or is less than 1

### Assumptions

- **Speaker representation**: Assuming speakers are currently represented as a string field (`speakerName`) that will be converted to a list/array of speaker names (`speakers: string[]`)
- **Minimum speakers**: Assuming at least 1 speaker is required (talks without speakers are invalid)
- **Name validation**: Assuming individual speaker names are validated elsewhere (non-empty, proper format)
- **Order preservation**: Assuming speaker order matters (first speaker is primary/main speaker)

## Success Criteria _(mandatory)_

### Measurable Outcomes

- **SC-001**: All talks with 4 or more speakers are rejected with appropriate errors (100% validation coverage)
- **SC-002**: All talks with 1-3 speakers can be successfully created
- **SC-003**: Error messages for invalid speaker counts include both the actual count and the maximum allowed (3)
- **SC-004**: Speaker count validation is enforced at domain entity instantiation (fail-fast principle)
- **SC-005**: Zero talks with more than 3 speakers can enter the system
- **SC-006**: Users can immediately identify and correct speaker count violations from error messages

## Governance Requirements _(auto-filled by /speckit.specify)_

### Architecture Compliance

- [ ] **GR-001**: This feature MUST place domain logic in `src/domain/`
- [ ] **GR-002**: This feature MUST NOT introduce forbidden imports (domain → infrastructure)
- [ ] **GR-003**: Implementation MUST follow Clean Architecture layers

### Documentation Compliance

- [ ] **GR-004**: ~~An ADR MUST be created documenting the key decision(s) for this feature~~
  - **EXCEPTION**: User specified "PAS D'ADR REQUIS (urgent, pas le temps)"
  - ADR can be created later if needed for documentation purposes
  - Implementation can proceed without ADR due to urgent business need

### CI/CD Gate

This specification will be validated automatically on PR:

| Gate      | Validation                 | Status |
| --------- | -------------------------- | ------ |
| Structure | Required directories exist | Active |
| Imports   | No layer violations        | Active |
| ADR       | At least one ADR exists    | **Waived** (urgent exception) |
| Coherence | AI review passes           | Active |

**Note**: ADR requirement waived for this feature due to urgent business need. Consider creating ADR post-implementation for documentation purposes.

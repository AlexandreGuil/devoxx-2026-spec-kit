# Implementation Plan: Validate Speaker Bio

**Branch**: `001-validate-speaker-bio` | **Date**: 2026-03-17 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-validate-speaker-bio/spec.md`

## Summary

Add mandatory bio validation to the `Talk` domain entity. A speaker bio must contain between 50 and 500 characters (trimmed). Violations throw a new `InvalidBioLengthError` domain error that encodes the constraint type (too short / too long), the applicable boundary, and the actual length. The implementation follows the existing `InvalidTitleLengthError` pattern exactly and requires an ADR per the project constitution.

## Technical Context

**Language/Version**: TypeScript 5.3.3 (strict mode) + Node.js >= 20.0.0
**Primary Dependencies**: Vitest (tests), ESLint + Prettier (linting)
**Storage**: N/A — in-memory repository, no persistence change
**Testing**: Vitest
**Target Platform**: Node.js
**Project Type**: Single project (Clean Architecture, 3-layer)
**Performance Goals**: N/A — pure domain logic, no I/O
**Constraints**: Domain layer must remain pure (no external imports, no side effects)
**Scale/Scope**: Small — single entity change + one new error class

## Constitution Check

_GATE: Must pass before Phase 0 research. Re-check after Phase 1 design._

| Principle    | Rule                                              | Status | Notes                                                       |
| ------------ | ------------------------------------------------- | ------ | ----------------------------------------------------------- |
| **I**        | Clean Architecture — 3 layers enforced            | ✅ PASS | Bio validation in `src/domain/` only                        |
| **I**        | Domain has 0 external dependencies                | ✅ PASS | `InvalidBioLengthError` is pure TypeScript, no imports      |
| **II**       | SOLID, readability, no God Objects                | ✅ PASS | Single responsibility — validation in constructor           |
| **III**      | ADR required for domain modification              | ✅ PASS | `docs/adrs/0006-validation-biographie-speaker.md` to create |
| **IV**       | Ubiquitous Language — naming                      | ✅ PASS | `bio`, `InvalidBioLengthError` — domain vocabulary          |
| **V**        | TDD — tests before implementation                 | ✅ PASS | Tests written first in `talk.entity.spec.ts`               |
| **VI**       | Code review mandatory before merge                | ✅ PASS | PR required, minimum 1 approval                             |

**Post-design re-check**: All gates still pass. No architectural violations introduced.

## Governance Compliance Gate

_GATE: CI/CD will automatically validate these rules on every PR to main._

**Governance File**: `.spec-kit/governance.md`
**Rules Reference**: `.specify/memory/governance-rules.md`

### Required for PR Merge

| Rule   | Description                | Validation                                                     |
| ------ | -------------------------- | -------------------------------------------------------------- |
| **R1** | Structure obligatoire      | `src/domain/`, `src/application/`, `src/infrastructure/` exist |
| **R2** | Clean Architecture imports | Domain/Application never import from outer layers              |
| **R3** | ADR obligatoire            | `docs/adrs/0006-validation-biographie-speaker.md` created      |
| **R4** | Cohérence documentation    | AI review validates doc/code alignment                         |

### Pre-Implementation Checklist

- [x] Identify which ADR(s) this feature requires → `docs/adrs/0006-validation-biographie-speaker.md`
- [x] Determine correct layer placement → `src/domain/talk.entity.ts` (domain layer)
- [x] Verify no architectural violations → Domain stays pure, no new dependencies

## Project Structure

### Documentation (this feature)

```text
specs/001-validate-speaker-bio/
├── plan.md              # This file
├── research.md          # Phase 0 output ✅
├── data-model.md        # Phase 1 output ✅
├── quickstart.md        # Phase 1 output ✅
├── contracts/
│   └── domain-contract.md  # Phase 1 output ✅
└── tasks.md             # Phase 2 output (/speckit.tasks — not yet created)
```

### Source Code (repository root)

```text
src/
├── domain/
│   ├── talk.entity.ts          ← MODIFY: add bio param + InvalidBioLengthError
│   └── talk.repository.ts      ← unchanged
├── application/
│   └── submit-talk.usecase.ts  ← MODIFY: pass bio to Talk constructor
└── infrastructure/
    └── cli.ts                  ← MODIFY: accept bio input, pass to use case

src/domain/
└── talk.entity.spec.ts         ← MODIFY: add bio validation test cases (TDD first)

docs/adrs/
└── 0006-validation-biographie-speaker.md  ← CREATE (mandatory ADR)
```

**Structure Decision**: Single project, Option 1. All changes are confined to the domain layer (primary) and callers (secondary propagation of new required parameter). No new files in `src/` — only modifications and one new ADR.

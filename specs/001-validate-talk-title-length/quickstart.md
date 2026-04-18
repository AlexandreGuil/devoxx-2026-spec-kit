# Quickstart Guide: Talk Title Length Validation

**Feature**: 001-validate-talk-title-length
**Branch**: `001-validate-talk-title-length`
**Estimated Time**: 1-2 hours (including tests and ADR)

## Prerequisites

- Node.js 20+ installed
- Project dependencies installed (`npm install`)
- Branch checked out: `git checkout 001-validate-talk-title-length`

---

## Implementation Workflow

### Step 1: Create ADR (REQUIRED FIRST)

**Why First**: Constitution Principle III mandates ADR creation BEFORE implementation for domain changes.

**File**: `docs/adrs/0005-validation-titre.md`

**Template**:

```markdown
# ADR-0005 : Talk Title Length Validation

**Statut** : Accepté
**Date** : 2026-01-31

## Contexte

Les titres de talks trop longs posent des problèmes d'affichage sur :

- Les applications mobiles (largeur d'écran limitée)
- Les programmes papier imprimés (contraintes de mise en page)

Actuellement, aucune limite n'est imposée sur la longueur des titres, ce qui entraîne :

- Titres tronqués dans l'app mobile
- Débordements de mise en page dans les programmes papier
- Mauvaise expérience utilisateur pour les participants

## Décision

**Limiter la longueur des titres de talks à 100 caractères maximum.**

### Implémentation

1. **Validation dans le constructeur** de l'entité `Talk` (`src/domain/talk.entity.ts`)
2. **Nouvelle erreur domaine** : `InvalidTitleLengthError`
3. **Comptage de caractères** : Utilisation de la propriété native `.length` de JavaScript (comptage UTF-16 code units)
4. **Message d'erreur** : Inclut la longueur actuelle et la limite maximale

### Justification technique

- **Validation au niveau domaine** : Respecte Clean Architecture (Principe I)
- **Fail-fast** : Rejet à la création de l'entité (invariant métier)
- **Zéro dépendance externe** : Utilisation de `.length` natif (pas de librairie tierce)

## Conséquences

### Positives

- ✅ Affichage cohérent sur tous les supports (mobile, web, papier)
- ✅ Validation fail-fast : impossible de créer une entité Talk invalide
- ✅ Aucune dépendance externe (logique domaine pure)
- ✅ Message d'erreur explicite (longueur actuelle + limite)

### Négatives

- ⚠️ Les speakers doivent reformuler les titres trop longs
- ⚠️ Emojis et caractères Unicode hors BMP comptent comme 2 caractères (cas rare, acceptable)
- ⚠️ Possible impact sur talks existants si titres > 100 chars (nécessite migration)

## Alternatives Considérées

### Alternative 1 : Limite plus longue (150 caractères)

- **Rejetée** : Le problème d'affichage mobile persiste avec 150 chars

### Alternative 2 : Validation au niveau application (use case)

- **Rejetée** : La limite de longueur est un invariant métier, doit être dans le domaine

### Alternative 3 : Utilisation de `Array.from(title).length` pour comptage exact

- **Rejetée** : Overkill pour le cas d'usage (titres de conférence rarement avec emojis), complexité inutile

### Alternative 4 : Librairie externe (grapheme-splitter)

- **Rejetée** : Viole le principe Clean Architecture (domaine doit avoir zéro dépendance externe)

## Migration

Si des talks existants dépassent 100 caractères, prévoir une tâche de migration pour :

1. Identifier les talks concernés (requête SQL : `SELECT * FROM talks WHERE LENGTH(title) > 100`)
2. Notifier les speakers
3. Mettre à jour les titres avec leur accord

## Références

- Spec : `specs/001-validate-talk-title-length/spec.md`
- Plan : `specs/001-validate-talk-title-length/plan.md`
- Constitution Principe III : ADR obligatoire
```

**Action**: Create this file and commit it BEFORE writing code.

```bash
# Create ADR
touch docs/adrs/0005-validation-titre.md
# ... copy template content above ...

# Commit ADR FIRST (per constitution)
git add docs/adrs/0005-validation-titre.md
git commit -m "docs: add ADR-0005 for talk title length validation"
```

---

### Step 2: Setup Test Framework (One-Time)

**Recommended**: Vitest (ESM-native, aligns with `"type": "module"`)

**Install**:

```bash
npm install --save-dev vitest @vitest/ui
```

**Create** `vitest.config.ts`:

```typescript
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html', 'lcov'],
      include: ['src/**/*.ts'],
      exclude: ['src/**/*.test.ts', 'src/**/*.spec.ts'],
      thresholds: {
        lines: 80,
        functions: 80,
        branches: 80,
        statements: 80,
      },
    },
  },
});
```

**Update** `package.json`:

```json
{
  "scripts": {
    "test": "vitest",
    "test:ui": "vitest --ui",
    "test:coverage": "vitest --coverage"
  }
}
```

**Create test directory**:

```bash
mkdir -p tests/unit/domain
```

---

### Step 3: Write Tests (TDD Red)

**File**: `tests/unit/domain/talk.entity.test.ts`

**Test Suite**:

```typescript
import { describe, it, expect } from 'vitest';
import { Talk, InvalidTitleLengthError, Duration } from '../../../src/domain/talk.entity.js';

describe('Talk Entity - Title Length Validation', () => {
  const validTalkData = {
    id: 'talk-1',
    title: 'Valid Title',
    abstract: 'A talk about testing',
    speakerName: 'John Doe',
    duration: 45 as Duration,
  };

  describe('Title Length Validation', () => {
    it('should accept title with exactly 100 characters', () => {
      const title100 = 'A'.repeat(100);
      const talk = new Talk(
        validTalkData.id,
        title100,
        validTalkData.abstract,
        validTalkData.speakerName,
        validTalkData.duration,
      );

      expect(talk.title).toBe(title100);
      expect(talk.title.length).toBe(100);
    });

    it('should reject title with 101 characters', () => {
      const title101 = 'A'.repeat(101);

      expect(() => {
        new Talk(
          validTalkData.id,
          title101,
          validTalkData.abstract,
          validTalkData.speakerName,
          validTalkData.duration,
        );
      }).toThrow(InvalidTitleLengthError);
    });

    it('should accept title with 50 characters', () => {
      const title50 = 'A'.repeat(50);
      const talk = new Talk(
        validTalkData.id,
        title50,
        validTalkData.abstract,
        validTalkData.speakerName,
        validTalkData.duration,
      );

      expect(talk.title).toBe(title50);
    });

    it('should reject title with 200 characters', () => {
      const title200 = 'A'.repeat(200);

      expect(() => {
        new Talk(
          validTalkData.id,
          title200,
          validTalkData.abstract,
          validTalkData.speakerName,
          validTalkData.duration,
        );
      }).toThrow(InvalidTitleLengthError);
    });

    it('should include actual length and max length in error message', () => {
      const title120 = 'A'.repeat(120);

      expect(() => {
        new Talk(
          validTalkData.id,
          title120,
          validTalkData.abstract,
          validTalkData.speakerName,
          validTalkData.duration,
        );
      }).toThrow(
        'Title length (120 characters) exceeds the maximum allowed length of 100 characters',
      );
    });

    it('should handle accented characters correctly', () => {
      const titleAccented = 'Café Français ' + 'A'.repeat(86); // Total 100 chars
      expect(titleAccented.length).toBe(100);

      const talk = new Talk(
        validTalkData.id,
        titleAccented,
        validTalkData.abstract,
        validTalkData.speakerName,
        validTalkData.duration,
      );

      expect(talk.title).toBe(titleAccented);
    });

    it('should count emoji as multiple characters (documented edge case)', () => {
      // '🎉' counts as 2 characters in JavaScript
      const titleWithEmoji = '🎉 Party Talk';
      expect(titleWithEmoji.length).toBe(13); // Not 12

      const talk = new Talk(
        validTalkData.id,
        titleWithEmoji,
        validTalkData.abstract,
        validTalkData.speakerName,
        validTalkData.duration,
      );

      expect(talk.title).toBe(titleWithEmoji);
    });
  });

  describe('Existing Validations (Regression Tests)', () => {
    it('should still reject empty title', () => {
      expect(() => {
        new Talk(
          validTalkData.id,
          '',
          validTalkData.abstract,
          validTalkData.speakerName,
          validTalkData.duration,
        );
      }).toThrow('Talk title must be provided');
    });

    it('should still reject whitespace-only title', () => {
      expect(() => {
        new Talk(
          validTalkData.id,
          '   ',
          validTalkData.abstract,
          validTalkData.speakerName,
          validTalkData.duration,
        );
      }).toThrow('Talk title must be provided');
    });
  });
});
```

**Run Tests** (should FAIL - Red phase):

```bash
npm test
```

**Expected**: All title length validation tests fail (feature not implemented yet).

---

### Step 4: Implement Feature (TDD Green)

**File**: `src/domain/talk.entity.ts`

**Step 4.1: Add Error Class**

Add BEFORE the Talk class definition:

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

**Step 4.2: Add Validation in Constructor**

Modify Talk constructor to add title length check AFTER empty-string validation:

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
    // ⭐ NEW: Title length validation
    if (title.length > 100) {
      throw new InvalidTitleLengthError(title.length);
    }
    if (!speakerName || speakerName.trim() === '') {
      throw new Error('Talk speakerName must be provided');
    }
    if (!this.isValidDuration(_duration)) {
      throw new InvalidDurationError(_duration);
    }
  }

  // ... rest of class unchanged
}
```

**Step 4.3: Update Exports**

Ensure `InvalidTitleLengthError` is exported:

```typescript
export { Talk, InvalidTitleLengthError, InvalidDurationError, type Duration };
```

**Run Tests** (should PASS - Green phase):

```bash
npm test
```

**Expected**: All tests pass ✅

---

### Step 5: Refactor (Optional)

**Optional Refactoring**: Extract constant for max length

```typescript
const MAX_TITLE_LENGTH = 100;

// In constructor:
if (title.length > MAX_TITLE_LENGTH) {
  throw new InvalidTitleLengthError(title.length);
}

// In error class:
export class InvalidTitleLengthError extends Error {
  constructor(actualLength: number) {
    super(
      `Title length (${actualLength} characters) exceeds the maximum allowed length of ${MAX_TITLE_LENGTH} characters`,
    );
    this.name = 'InvalidTitleLengthError';
  }
}
```

**Decision**: Optional. Inline value (`100`) is acceptable for single use case.

**Run Tests** (should still PASS):

```bash
npm test
```

---

### Step 6: Verify Coverage

**Run Coverage**:

```bash
npm run test:coverage
```

**Expected Coverage**:

- `src/domain/talk.entity.ts`: 100% (per Constitution Principle V)

**If coverage < 100%**: Add missing test cases.

---

### Step 7: Lint & Format

**Run Linter**:

```bash
npm run lint:fix
npm run format
```

**Fix any issues** before commit.

---

### Step 8: Commit Changes

**Commit Strategy** (per Conventional Commits):

```bash
# Stage changes
git add src/domain/talk.entity.ts
git add tests/unit/domain/talk.entity.test.ts
git add vitest.config.ts  # If created
git add package.json package-lock.json  # If test deps added

# Commit with descriptive message
git commit -m "feat: add title length validation for talks

- Add InvalidTitleLengthError domain error
- Validate title length <= 100 chars in Talk constructor
- Add comprehensive unit tests (100% coverage)
- Implement TDD workflow (Red-Green-Refactor)

Refs: ADR-0005, FR-001, FR-002, FR-003, FR-004

```

---

### Step 9: Manual Testing (Optional)

**Create Test Script** (optional): `scripts/test-title-validation.ts`

```typescript
import { Talk, InvalidTitleLengthError } from '../src/domain/talk.entity.js';

console.log('✅ Testing title length validation...\n');

// Test 1: Valid 100-char title
try {
  const title100 = 'A'.repeat(100);
  const talk1 = new Talk('1', title100, 'Abstract', 'Speaker', 45);
  console.log('✅ PASS: 100-character title accepted');
} catch (e) {
  console.log('❌ FAIL: 100-character title rejected');
}

// Test 2: Invalid 101-char title
try {
  const title101 = 'A'.repeat(101);
  const talk2 = new Talk('2', title101, 'Abstract', 'Speaker', 45);
  console.log('❌ FAIL: 101-character title accepted');
} catch (e) {
  if (e instanceof InvalidTitleLengthError) {
    console.log('✅ PASS: 101-character title rejected');
    console.log(`   Error: ${e.message}`);
  }
}

console.log('\n✅ Manual validation complete!');
```

**Run**:

```bash
npx ts-node --esm scripts/test-title-validation.ts
```

---

## Common Issues & Solutions

### Issue 1: Tests Not Found

**Symptom**: Vitest doesn't find test files

**Solution**: Check `vitest.config.ts` includes pattern:

```typescript
test: {
  include: ['**/*.test.ts', '**/*.spec.ts'],
}
```

### Issue 2: Module Import Errors

**Symptom**: `Cannot find module` errors in tests

**Solution**: Ensure `.js` extension in imports (ESM requirement):

```typescript
import { Talk } from '../../../src/domain/talk.entity.js'; // ✅ Correct
import { Talk } from '../../../src/domain/talk.entity'; // ❌ Wrong (ESM)
```

### Issue 3: TypeScript Errors in Tests

**Symptom**: Type errors in test file

**Solution**: Update `tsconfig.json` to include tests:

```json
{
  "include": ["src/**/*", "tests/**/*"]
}
```

---

## Validation Checklist

Before creating Pull Request:

- [ ] **ADR Created**: `docs/adrs/0005-validation-titre.md` exists and committed FIRST
- [ ] **Tests Written**: `tests/unit/domain/talk.entity.test.ts` exists
- [ ] **Tests Pass**: `npm test` shows all tests passing ✅
- [ ] **Coverage 100%**: `npm run test:coverage` shows 100% domain coverage
- [ ] **Code Validated**: Talk entity constructor has title length check
- [ ] **Error Class Added**: `InvalidTitleLengthError` exported
- [ ] **Linted**: `npm run lint` passes
- [ ] **Formatted**: `npm run format` applied
- [ ] **Committed**: Changes committed with conventional commit message
- [ ] **Constitution Compliance**: All 6 principles respected

---

## Next Steps

After implementation complete:

1. **Push Branch**: `git push origin 001-validate-talk-title-length`
2. **Create PR**: Use GitHub CLI or web interface
3. **PR Description**: Reference ADR-0005, spec, and constitution compliance
4. **CI/CD**: Wait for Spec-kit validation (R1, R2, R3, R4 gates)
5. **Code Review**: Address reviewer feedback
6. **Merge**: Once approved and CI passes

---

## Time Estimates

| Phase | Task                            | Time Estimate |
| ----- | ------------------------------- | ------------- |
| 1     | Create ADR                      | 15-20 min     |
| 2     | Setup test framework (one-time) | 10-15 min     |
| 3     | Write tests (TDD Red)           | 20-25 min     |
| 4     | Implement feature (TDD Green)   | 10-15 min     |
| 5     | Refactor (optional)             | 5-10 min      |
| 6     | Coverage verification           | 5 min         |
| 7     | Lint & format                   | 5 min         |
| 8     | Commit                          | 5 min         |

**Total**: 1-2 hours (including test framework setup)

**Subsequent features**: 45-60 min (test framework already configured)

---

## Resources

- **Spec**: [spec.md](./spec.md)
- **Plan**: [plan.md](./plan.md)
- **Research**: [research.md](./research.md)
- **Data Model**: [data-model.md](./data-model.md)
- **Constitution**: `.specify/memory/constitution.md`
- **Vitest Docs**: https://vitest.dev/
- **TDD Guide**: https://martinfowler.com/bliki/TestDrivenDevelopment.html

---

**Quickstart Status**: ✅ Ready for implementation

**Last Updated**: 2026-01-31

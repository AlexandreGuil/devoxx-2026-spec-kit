# Quickstart Guide: Abstract Length Validation

**Feature**: 004-validate-abstract-length
**Branch**: `004-validate-abstract-length`
**Estimated Time**: 45-60 minutes (tests and ADR)

## Prerequisites

- Node.js 20+ installed
- Project dependencies installed (`npm install`)
- Test framework configured (Vitest)
- Branch checked out: `git checkout 004-validate-abstract-length`

---

## Implementation Workflow

### Step 1: Create ADR (REQUIRED FIRST)

**Why First**: Constitution Principle III mandates ADR creation BEFORE implementation for domain changes.

**File**: `docs/adrs/0007-validate-abstract-length.md`

**Template**:

```markdown
# ADR-0007 : Abstract Length Validation

**Statut** : Accepté
**Date** : 2026-01-31

## Contexte

Les abstracts de talks trop longs posent des problèmes d'affichage sur les applications mobiles où l'espace d'écran est limité. Les participants consultent souvent le programme des talks depuis leur smartphone pendant la conférence.

Problèmes actuels :
- Abstracts non limités causent des débordements dans l'app mobile
- Texte tronqué ou nécessitant un scroll excessif
- Mauvaise expérience utilisateur lors de la consultation rapide du programme

## Décision

**Limiter la longueur des abstracts de talks à 500 caractères maximum.**

### Implémentation

1. **Validation dans le constructeur** de l'entité `Talk` (`src/domain/talk.entity.ts`)
2. **Nouvelle erreur domaine** : `InvalidAbstractLengthError`
3. **Comptage de caractères** : Utilisation de la propriété native `.length` de JavaScript (UTF-16 code units)
4. **Message d'erreur** : Inclut la longueur actuelle et la limite maximale (500 caractères)

### Justification technique

- **Validation au niveau domaine** : Respecte Clean Architecture (Principe I)
- **Fail-fast** : Rejet à la création de l'entité (invariant métier)
- **Cohérence avec validation du titre** : Même approche que la validation de longueur de titre (100 caractères)
- **Zéro dépendance externe** : Utilisation de `.length` natif

## Conséquences

### Positives

- ✅ Affichage optimal sur applications mobiles (pas de scroll infini)
- ✅ Validation fail-fast : impossible de créer une entité Talk invalide
- ✅ Message d'erreur explicite (longueur actuelle + limite)
- ✅ Cohérence avec la validation de titre existante
- ✅ Encourage les speakers à rédiger des abstracts concis et impactants

### Négatives

- ⚠️ Les speakers doivent synthétiser leurs abstracts (limite créative potentielle)
- ⚠️ Emojis et caractères Unicode hors BMP comptent comme 2 caractères (cas rare, acceptable)
- ⚠️ Possible impact sur talks existants si abstracts > 500 chars (nécessite migration)

## Alternatives Considérées

### Alternative 1 : Limite plus courte (300 caractères)

- **Rejetée** : Trop restrictif pour décrire adéquatement le contenu d'un talk
- 300 caractères insuffisants pour des talks techniques complexes

### Alternative 2 : Limite plus longue (1000 caractères)

- **Rejetée** : Ne résout pas le problème d'affichage mobile
- 1000 caractères nécessitent toujours un scroll important sur smartphone

### Alternative 3 : Validation au niveau application (use case)

- **Rejetée** : La limite de longueur est un invariant métier, doit être dans le domaine
- Cohérence avec validation de titre (déjà au niveau domaine)

### Alternative 4 : Utilisation de `Array.from(abstract).length` pour comptage exact

- **Rejetée** : Overkill pour le cas d'usage, complexité inutile
- Abstracts de conférence rarement avec emojis complexes

## Migration

Si des talks existants dépassent 500 caractères :

1. Identifier les talks concernés : `SELECT * FROM talks WHERE LENGTH(abstract) > 500`
2. Notifier les speakers avec statistiques (nombre de caractères à supprimer)
3. Mettre à jour les abstracts avec leur accord
4. Prévoir un délai raisonnable pour la migration (30 jours recommandés)

## Références

- Spec : `specs/004-validate-abstract-length/spec.md`
- Plan : `specs/004-validate-abstract-length/plan.md`
- Constitution Principe III : ADR obligatoire
- ADR-0005 : Validation titre (approche similaire)
```

**Action**: Create this file and commit it BEFORE writing code.

```bash
# Create ADR
touch docs/adrs/0007-validate-abstract-length.md
# ... copy template content above ...

# Commit ADR FIRST (per constitution)
git add docs/adrs/0007-validate-abstract-length.md
git commit -m "docs: add ADR-0007 for abstract length validation"
```

---

### Step 2: Write Tests (TDD Red)

**File**: `tests/unit/domain/talk.entity.test.ts`

**Add Test Suite** (append to existing test file):

```typescript
describe('Talk Entity - Abstract Length Validation', () => {
  const validTalkData = {
    id: 'talk-1',
    title: 'Valid Title',
    abstract: 'A talk about testing',
    speakerName: 'John Doe',
    duration: 45 as Duration,
  };

  describe('Abstract Length Validation', () => {
    it('should accept abstract with 400 characters', () => {
      const abstract400 = 'A'.repeat(400);
      const talk = new Talk(
        validTalkData.id,
        validTalkData.title,
        abstract400,
        validTalkData.speakerName,
        validTalkData.duration,
      );

      expect(talk.abstract).toBe(abstract400);
      expect(talk.abstract.length).toBe(400);
    });

    it('should accept abstract with exactly 500 characters', () => {
      const abstract500 = 'A'.repeat(500);
      const talk = new Talk(
        validTalkData.id,
        validTalkData.title,
        abstract500,
        validTalkData.speakerName,
        validTalkData.duration,
      );

      expect(talk.abstract).toBe(abstract500);
      expect(talk.abstract.length).toBe(500);
    });

    it('should reject abstract with 501 characters', () => {
      const abstract501 = 'A'.repeat(501);

      expect(() => {
        new Talk(
          validTalkData.id,
          validTalkData.title,
          abstract501,
          validTalkData.speakerName,
          validTalkData.duration,
        );
      }).toThrow(InvalidAbstractLengthError);
    });

    it('should reject abstract with 600 characters', () => {
      const abstract600 = 'A'.repeat(600);

      expect(() => {
        new Talk(
          validTalkData.id,
          validTalkData.title,
          abstract600,
          validTalkData.speakerName,
          validTalkData.duration,
        );
      }).toThrow(InvalidAbstractLengthError);
    });

    it('should reject abstract with 1000 characters', () => {
      const abstract1000 = 'A'.repeat(1000);

      expect(() => {
        new Talk(
          validTalkData.id,
          validTalkData.title,
          abstract1000,
          validTalkData.speakerName,
          validTalkData.duration,
        );
      }).toThrow(InvalidAbstractLengthError);
    });

    it('should include actual length and max length in error message (501 chars)', () => {
      const abstract501 = 'A'.repeat(501);

      expect(() => {
        new Talk(
          validTalkData.id,
          validTalkData.title,
          abstract501,
          validTalkData.speakerName,
          validTalkData.duration,
        );
      }).toThrow(
        'Abstract length (501 characters) exceeds the maximum allowed length of 500 characters',
      );
    });

    it('should include actual length and max length in error message (600 chars)', () => {
      const abstract600 = 'A'.repeat(600);

      expect(() => {
        new Talk(
          validTalkData.id,
          validTalkData.title,
          abstract600,
          validTalkData.speakerName,
          validTalkData.duration,
        );
      }).toThrow(
        'Abstract length (600 characters) exceeds the maximum allowed length of 500 characters',
      );
    });

    it('should set error name to InvalidAbstractLengthError', () => {
      const abstract600 = 'A'.repeat(600);

      try {
        new Talk(
          validTalkData.id,
          validTalkData.title,
          abstract600,
          validTalkData.speakerName,
          validTalkData.duration,
        );
        expect.fail('Should have thrown InvalidAbstractLengthError');
      } catch (e) {
        expect(e).toBeInstanceOf(InvalidAbstractLengthError);
        expect(e.name).toBe('InvalidAbstractLengthError');
      }
    });

    it('should handle accented characters correctly', () => {
      const abstractAccented = 'Café Français '.repeat(35) + 'A'.repeat(10); // ~500 chars
      expect(abstractAccented.length).toBeLessThanOrEqual(500);

      const talk = new Talk(
        validTalkData.id,
        validTalkData.title,
        abstractAccented,
        validTalkData.speakerName,
        validTalkData.duration,
      );

      expect(talk.abstract).toBe(abstractAccented);
    });

    it('should count emoji as multiple characters (documented edge case)', () => {
      // '🎉' counts as 2 characters in JavaScript
      const abstractWithEmoji = '🎉 Great talk! ' + 'A'.repeat(485); // ~500 chars
      expect(abstractWithEmoji.length).toBeLessThanOrEqual(500);

      const talk = new Talk(
        validTalkData.id,
        validTalkData.title,
        abstractWithEmoji,
        validTalkData.speakerName,
        validTalkData.duration,
      );

      expect(talk.abstract).toBe(abstractWithEmoji);
    });

    it('should handle abstracts with newlines correctly', () => {
      const abstractWithNewlines = 'Paragraph 1\n\nParagraph 2\n\nParagraph 3 ' + 'A'.repeat(460);
      expect(abstractWithNewlines.length).toBeLessThanOrEqual(500);

      const talk = new Talk(
        validTalkData.id,
        validTalkData.title,
        abstractWithNewlines,
        validTalkData.speakerName,
        validTalkData.duration,
      );

      expect(talk.abstract).toBe(abstractWithNewlines);
    });
  });

  describe('Existing Validations (Regression Tests)', () => {
    it('should still reject empty abstract', () => {
      expect(() => {
        new Talk(
          validTalkData.id,
          validTalkData.title,
          '',
          validTalkData.speakerName,
          validTalkData.duration,
        );
      }).toThrow('Talk abstract must be provided');
    });

    it('should still reject whitespace-only abstract', () => {
      expect(() => {
        new Talk(
          validTalkData.id,
          validTalkData.title,
          '   ',
          validTalkData.speakerName,
          validTalkData.duration,
        );
      }).toThrow('Talk abstract must be provided');
    });
  });
});
```

**Run Tests** (should FAIL - Red phase):

```bash
npm test
```

**Expected**: All abstract length validation tests fail (feature not implemented yet).

---

### Step 3: Implement Feature (TDD Green)

**File**: `src/domain/talk.entity.ts`

**Step 3.1: Add Error Class**

Add AFTER the `InvalidTitleLengthError` class definition:

```typescript
/**
 * InvalidAbstractLengthError (Domain Error)
 * Thrown when a talk abstract exceeds the maximum allowed length of 500 characters.
 */
export class InvalidAbstractLengthError extends Error {
  constructor(actualLength: number) {
    super(
      `Abstract length (${actualLength} characters) exceeds the maximum allowed length of 500 characters`,
    );
    this.name = 'InvalidAbstractLengthError';
  }
}
```

**Step 3.2: Add Validation in Constructor**

Modify Talk constructor to add abstract length check AFTER empty-string validation:

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
    if (title.length > 100) {
      throw new InvalidTitleLengthError(title.length);
    }
    if (!abstract || abstract.trim() === '') {
      throw new Error('Talk abstract must be provided');
    }
    // ⭐ NEW: Abstract length validation
    if (abstract.length > 500) {
      throw new InvalidAbstractLengthError(abstract.length);
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

**Step 3.3: Update Exports**

Ensure `InvalidAbstractLengthError` is exported:

```typescript
export { 
  Talk, 
  InvalidTitleLengthError, 
  InvalidAbstractLengthError, 
  InvalidDurationError, 
  type Duration 
};
```

**Run Tests** (should PASS - Green phase):

```bash
npm test
```

**Expected**: All tests pass ✅

---

### Step 4: Verify Coverage

**Run Coverage**:

```bash
npm run test:coverage
```

**Expected Coverage**:

- `src/domain/talk.entity.ts`: 100% (per Constitution Principle V)

**If coverage < 100%**: Add missing test cases.

---

### Step 5: Lint & Format

**Run Linter**:

```bash
npm run lint:fix
npm run format
```

**Fix any issues** before commit.

---

### Step 6: Commit Changes

**Commit Strategy** (per Conventional Commits):

```bash
# Stage changes
git add src/domain/talk.entity.ts
git add tests/unit/domain/talk.entity.test.ts

# Commit with descriptive message
git commit -m "feat: add abstract length validation for talks

- Add InvalidAbstractLengthError domain error
- Validate abstract length <= 500 chars in Talk constructor
- Add comprehensive unit tests (100% coverage)
- Implement TDD workflow (Red-Green-Refactor)

Refs: ADR-0007, FR-001, FR-002, FR-003, FR-004, FR-005

```

---

## Common Pitfalls & Solutions

### Pitfall 1: Wrong Character Count

**Problem**: Manually counting characters incorrectly in tests

**Solution**: Use `'A'.repeat(n)` for precise test strings:

```typescript
const abstract500 = 'A'.repeat(500); // ✅ Exactly 500 characters
const abstract500 = 'Some long text...'; // ❌ Hard to verify exact length
```

### Pitfall 2: Emoji Counting Confusion

**Problem**: Emojis like 🎉 count as 2 characters (UTF-16 code units)

**Solution**: Document this behavior in ADR and tests. Use `.length` consistently:

```typescript
'🎉'.length; // Returns 2 (expected behavior)
```

### Pitfall 3: Forgetting Existing Validations

**Problem**: Abstract length validation breaks existing empty-string validation

**Solution**: Add abstract length check AFTER empty-string validation:

```typescript
// ✅ Correct order
if (!abstract || abstract.trim() === '') {
  throw new Error('Talk abstract must be provided');
}
if (abstract.length > 500) {
  throw new InvalidAbstractLengthError(abstract.length);
}
```

### Pitfall 4: Copy-Paste Errors from Title Validation

**Problem**: Copying title validation code but forgetting to update error messages

**Solution**: Double-check error messages mention "Abstract" and "500 characters":

```typescript
// ❌ Wrong (copy-paste error)
throw new InvalidAbstractLengthError(abstract.length); 
// Error: "Title length (501 characters) exceeds..."

// ✅ Correct
throw new InvalidAbstractLengthError(abstract.length);
// Error: "Abstract length (501 characters) exceeds the maximum allowed length of 500 characters"
```

### Pitfall 5: Missing Export

**Problem**: `InvalidAbstractLengthError` not exported from module

**Solution**: Add to exports list:

```typescript
export { 
  Talk, 
  InvalidTitleLengthError,
  InvalidAbstractLengthError, // ✅ Don't forget this
  InvalidDurationError,
  type Duration
};
```

---

## Testing Cheatsheet

### Valid Abstracts (Should Pass)

```typescript
// Boundary test - exactly 500 characters
const abstract500 = 'A'.repeat(500); // ✅ Valid

// Well below limit
const abstract400 = 'A'.repeat(400); // ✅ Valid

// Short abstract
const abstractShort = 'Great talk about testing'; // ✅ Valid

// With newlines (still counts toward length)
const abstractMultiline = 'Para 1\n\nPara 2'; // ✅ Valid if <= 500
```

### Invalid Abstracts (Should Fail)

```typescript
// Just over the limit
const abstract501 = 'A'.repeat(501); // ❌ Invalid

// Significantly over
const abstract600 = 'A'.repeat(600); // ❌ Invalid

// Way over
const abstract1000 = 'A'.repeat(1000); // ❌ Invalid
```

### Edge Cases

```typescript
// Empty abstract (caught by existing validation)
const abstractEmpty = ''; // ❌ Invalid (empty check)

// Whitespace only (caught by existing validation)
const abstractWhitespace = '   '; // ❌ Invalid (empty check)

// Emoji (counts as multiple characters)
const abstractEmoji = '🎉'.repeat(251); // ❌ Invalid (502 characters)

// Accented characters (count as 1 character each)
const abstractAccented = 'Café'.repeat(125); // ✅ Valid (500 characters)
```

---

## FAQ

### Q1: Why 500 characters and not 300 or 1000?

**A**: 500 characters is a balance between:
- **Too short** (300): Insufficient for technical talks with complex concepts
- **Too long** (1000): Causes scroll issues on mobile, defeats purpose of "abstract"
- **Sweet spot** (500): 2-3 sentences, fits mobile screen without scroll

See ADR-0007 for detailed analysis of alternatives.

### Q2: How are emojis counted?

**A**: JavaScript's `.length` property counts UTF-16 code units. Most emojis count as 2 characters:

```typescript
'🎉'.length; // Returns 2
'Hello 🎉'.length; // Returns 8 (not 7)
```

This is documented behavior and acceptable for conference talk abstracts (rarely contain complex emojis).

### Q3: Do newlines count toward the limit?

**A**: Yes. `\n` is a character and counts toward the 500 limit:

```typescript
'Line 1\nLine 2'.length; // Returns 13 (includes \n)
```

### Q4: What happens to existing talks with long abstracts?

**A**: Migration required. See ADR-0007 "Migration" section:
1. Query database for talks with abstracts > 500 chars
2. Notify speakers with character count
3. Request abstract revisions
4. Update with speaker approval

### Q5: Can I use a different character counting method?

**A**: No. For consistency with title validation, we use JavaScript's native `.length`:
- ✅ Simple, no dependencies
- ✅ Consistent with existing title validation
- ✅ Good enough for conference talk abstracts
- ❌ Alternatives like `Array.from().length` add complexity without meaningful benefit

### Q6: Why is this validation in the domain layer?

**A**: Per Clean Architecture (Constitution Principle I):
- **Domain invariant**: "Abstracts must be ≤ 500 characters" is a business rule
- **Fail-fast**: Invalid entities cannot be created
- **Consistency**: Title validation already exists in domain layer

### Q7: What if my abstract is exactly 500 characters?

**A**: This is valid! The limit is **inclusive**:

```typescript
const abstract500 = 'A'.repeat(500);
new Talk(id, title, abstract500, speaker, duration); // ✅ Success
```

### Q8: Can I bypass this validation for special cases?

**A**: No. Domain entities enforce invariants strictly. If business requirements change:
1. Create new ADR documenting the change
2. Update validation logic
3. Update tests
4. Deploy to all environments

---

## Validation Checklist

Before creating Pull Request:

- [ ] **ADR Created**: `docs/adrs/0007-validate-abstract-length.md` exists and committed FIRST
- [ ] **Tests Written**: Abstract length validation tests added to `tests/unit/domain/talk.entity.test.ts`
- [ ] **Tests Pass**: `npm test` shows all tests passing ✅
- [ ] **Coverage 100%**: `npm run test:coverage` shows 100% domain coverage
- [ ] **Code Validated**: Talk entity constructor has abstract length check
- [ ] **Error Class Added**: `InvalidAbstractLengthError` exported
- [ ] **Linted**: `npm run lint` passes
- [ ] **Formatted**: `npm run format` applied
- [ ] **Committed**: Changes committed with conventional commit message
- [ ] **Constitution Compliance**: All 6 principles respected
- [ ] **No Regression**: Existing validations still work (empty abstract, title length, etc.)

---

## Next Steps

After implementation complete:

1. **Push Branch**: `git push origin 004-validate-abstract-length`
2. **Create PR**: Use GitHub CLI (`gh pr create`) or web interface
3. **PR Description**: Reference ADR-0007, spec, and constitution compliance
4. **CI/CD**: Wait for Spec-kit validation (R1, R2, R3, R4 gates)
5. **Code Review**: Address reviewer feedback
6. **Merge**: Once approved and CI passes

---

## Time Estimates

| Phase | Task                        | Time Estimate |
| ----- | --------------------------- | ------------- |
| 1     | Create ADR                  | 15-20 min     |
| 2     | Write tests (TDD Red)       | 20-25 min     |
| 3     | Implement feature (Green)   | 10-15 min     |
| 4     | Coverage verification       | 5 min         |
| 5     | Lint & format               | 5 min         |
| 6     | Commit                      | 5 min         |

**Total**: 45-60 minutes

---

## Resources

- **Spec**: [spec.md](./spec.md)
- **Plan**: [plan.md](./plan.md)
- **Research**: [research.md](./research.md)
- **Data Model**: [data-model.md](./data-model.md)
- **Constitution**: `.specify/memory/constitution.md`
- **Related ADR**: ADR-0005 (title validation - similar approach)
- **Vitest Docs**: https://vitest.dev/
- **TDD Guide**: https://martinfowler.com/bliki/TestDrivenDevelopment.html

---

**Quickstart Status**: ✅ Ready for implementation

**Last Updated**: 2026-01-31

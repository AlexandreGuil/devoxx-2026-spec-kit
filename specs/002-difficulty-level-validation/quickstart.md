# Quickstart Guide: Difficulty Level Validation

**Feature**: 002-difficulty-level-validation
**Date**: 2026-01-31
**For**: Developers implementing or using the difficulty level validation feature

## Overview

This guide provides practical examples for using the new difficulty level validation in the Talk entity. After this feature, all talks must specify a difficulty level: "Beginner", "Intermediate", or "Advanced".

---

## Basic Usage

### Creating Talks with Difficulty Levels

```typescript
import { Talk, DifficultyLevel } from './src/domain/talk.entity';

// Create a beginner-level talk
const beginnerTalk = new Talk(
  '1',
  'Introduction to TypeScript',
  'Learn TypeScript fundamentals and basic syntax',
  'John Doe',
  45,
  'Beginner'  // NEW: Difficulty level (6th parameter)
);

// Create an intermediate-level talk
const intermediateTalk = new Talk(
  '2',
  'Advanced TypeScript Patterns',
  'Deep dive into generics, conditional types, and mapped types',
  'Jane Smith',
  90,
  'Intermediate'
);

// Create an advanced-level talk
const advancedTalk = new Talk(
  '3',
  'TypeScript Compiler Internals',
  'Understand how the TypeScript compiler works under the hood',
  'Expert Dev',
  90,
  'Advanced'
);
```

### Accessing Difficulty Level

```typescript
// Read-only access via getter
console.log(beginnerTalk.difficulty);      // "Beginner"
console.log(intermediateTalk.difficulty);  // "Intermediate"
console.log(advancedTalk.difficulty);      // "Advanced"

// Type-safe: TypeScript knows the return type
const level: DifficultyLevel = beginnerTalk.difficulty;

// Immutable: No setter exists
// beginnerTalk.difficulty = "Advanced";  // ❌ Compile error
```

### Using DifficultyLevel Type

```typescript
// Type-safe function parameters
function filterTalksByDifficulty(
  talks: Talk[],
  level: DifficultyLevel
): Talk[] {
  return talks.filter(talk => talk.difficulty === level);
}

// Autocomplete works! IDE suggests: "Beginner" | "Intermediate" | "Advanced"
const beginnerTalks = filterTalksByDifficulty(allTalks, 'Beginner');
```

---

## Error Handling

### Catching Invalid Difficulty Levels

```typescript
import { Talk, InvalidDifficultyLevelError } from './src/domain/talk.entity';

// ❌ Invalid difficulty level: "Easy"
try {
  const invalidTalk = new Talk(
    '4',
    'Some Talk',
    'Description',
    'Speaker Name',
    45,
    'Easy'  // ❌ Not a valid difficulty level
  );
} catch (error) {
  if (error instanceof InvalidDifficultyLevelError) {
    console.error(error.message);
    // Output: Invalid difficulty level: "Easy". Valid levels are: Beginner, Intermediate, Advanced
  }
}

// ❌ Invalid difficulty level: "Expert"
try {
  const invalidTalk = new Talk('5', 'Talk', 'Desc', 'Speaker', 45, 'Expert');
} catch (error) {
  if (error instanceof InvalidDifficultyLevelError) {
    console.error(error.name);     // "InvalidDifficultyLevelError"
    console.error(error.message);  // "Invalid difficulty level: "Expert". Valid levels are: Beginner, Intermediate, Advanced"
  }
}
```

### Validating User Input

```typescript
function createTalkFromUserInput(input: any): Talk | Error {
  try {
    return new Talk(
      input.id,
      input.title,
      input.abstract,
      input.speakerName,
      input.duration,
      input.difficulty  // Will throw if invalid
    );
  } catch (error) {
    if (error instanceof InvalidDifficultyLevelError) {
      // Handle difficulty validation error
      return new Error(`Please provide a valid difficulty level: Beginner, Intermediate, or Advanced`);
    }
    // Handle other validation errors (title length, duration, etc.)
    return error as Error;
  }
}

// Usage
const result = createTalkFromUserInput({
  id: '1',
  title: 'My Talk',
  abstract: 'Description',
  speakerName: 'Speaker',
  duration: 45,
  difficulty: 'Easy'  // ❌ Invalid
});

if (result instanceof Error) {
  console.error(result.message);
  // "Please provide a valid difficulty level: Beginner, Intermediate, or Advanced"
}
```

---

## Edge Cases

### Case Sensitivity

⚠️ **Difficulty levels are case-sensitive**. Only exact matches are valid.

```typescript
// ✅ Valid (exact case)
new Talk('1', 'Talk', 'Desc', 'Speaker', 45, 'Beginner');
new Talk('2', 'Talk', 'Desc', 'Speaker', 45, 'Intermediate');
new Talk('3', 'Talk', 'Desc', 'Speaker', 45, 'Advanced');

// ❌ Invalid (wrong case)
new Talk('4', 'Talk', 'Desc', 'Speaker', 45, 'beginner');      // lowercase
new Talk('5', 'Talk', 'Desc', 'Speaker', 45, 'BEGINNER');      // uppercase
new Talk('6', 'Talk', 'Desc', 'Speaker', 45, 'BeGiNnEr');      // mixed case
```

**Workaround** (if accepting user input):
```typescript
function normalizeDifficulty(input: string): DifficultyLevel | null {
  const normalized = input.trim().toLowerCase();
  switch (normalized) {
    case 'beginner': return 'Beginner';
    case 'intermediate': return 'Intermediate';
    case 'advanced': return 'Advanced';
    default: return null;
  }
}

// Usage
const userInput = 'beginner';  // From user form
const difficulty = normalizeDifficulty(userInput);

if (difficulty) {
  const talk = new Talk('1', 'Talk', 'Desc', 'Speaker', 45, difficulty);
} else {
  console.error('Invalid difficulty level');
}
```

### Whitespace

⚠️ **Leading/trailing whitespace is rejected**. No automatic trimming.

```typescript
// ❌ Invalid (whitespace)
new Talk('1', 'Talk', 'Desc', 'Speaker', 45, ' Beginner');   // leading space
new Talk('2', 'Talk', 'Desc', 'Speaker', 45, 'Beginner ');   // trailing space
new Talk('3', 'Talk', 'Desc', 'Speaker', 45, ' Beginner ');  // both

// ✅ Valid (no whitespace)
new Talk('4', 'Talk', 'Desc', 'Speaker', 45, 'Beginner');
```

**Workaround** (if accepting user input):
```typescript
const userInput = ' Beginner ';  // From form with extra spaces
const trimmed = userInput.trim();  // "Beginner"

if (trimmed === 'Beginner' || trimmed === 'Intermediate' || trimmed === 'Advanced') {
  const talk = new Talk('1', 'Talk', 'Desc', 'Speaker', 45, trimmed as DifficultyLevel);
}
```

### Type Coercion

⚠️ **Only strings are accepted**. Numbers, booleans, null, undefined are rejected.

```typescript
// ❌ Invalid (wrong types)
new Talk('1', 'Talk', 'Desc', 'Speaker', 45, 1);             // number
new Talk('2', 'Talk', 'Desc', 'Speaker', 45, true);          // boolean
new Talk('3', 'Talk', 'Desc', 'Speaker', 45, null);          // null
new Talk('4', 'Talk', 'Desc', 'Speaker', 45, undefined);     // undefined
new Talk('5', 'Talk', 'Desc', 'Speaker', 45, {level: 'Beginner'});  // object
```

**TypeScript will prevent most of these at compile time**, but runtime validation catches them if bypassed (e.g., from untyped JSON).

---

## Migration Guide

### Updating Existing Code

**Before Feature 002** (5 parameters):
```typescript
const talk = new Talk(
  '1',
  'Introduction to Testing',
  'Learn testing fundamentals',
  'John Doe',
  45
);
```

**After Feature 002** (6 parameters):
```typescript
const talk = new Talk(
  '1',
  'Introduction to Testing',
  'Learn testing fundamentals',
  'John Doe',
  45,
  'Beginner'  // NEW: Must add difficulty level
);
```

### Updating Tests

**Example test update**:

**Before**:
```typescript
describe('Talk entity', () => {
  it('should create a valid talk', () => {
    const talk = new Talk('1', 'Test Talk', 'Description', 'Speaker', 45);
    expect(talk.title).toBe('Test Talk');
  });
});
```

**After**:
```typescript
describe('Talk entity', () => {
  it('should create a valid talk', () => {
    const talk = new Talk('1', 'Test Talk', 'Description', 'Speaker', 45, 'Intermediate');
    expect(talk.title).toBe('Test Talk');
    expect(talk.difficulty).toBe('Intermediate');  // NEW: Can test difficulty
  });
});
```

### Updating Repository/Factory Patterns

**Before**:
```typescript
class TalkFactory {
  static createFromDTO(dto: TalkDTO): Talk {
    return new Talk(
      dto.id,
      dto.title,
      dto.abstract,
      dto.speakerName,
      dto.duration
    );
  }
}
```

**After**:
```typescript
class TalkFactory {
  static createFromDTO(dto: TalkDTO): Talk {
    return new Talk(
      dto.id,
      dto.title,
      dto.abstract,
      dto.speakerName,
      dto.duration,
      dto.difficulty  // NEW: Pass difficulty from DTO
    );
  }
}

// DTO interface updated
interface TalkDTO {
  id: string;
  title: string;
  abstract: string;
  speakerName: string;
  duration: number;
  difficulty: DifficultyLevel;  // NEW: Add to DTO
}
```

### Compiler Assistance

TypeScript will help find all places requiring updates:

```
Error: Expected 6 arguments, but got 5.
An argument for '_difficulty' was not provided.
```

**Strategy**: Let the compiler guide you. Compile your code and fix each error one by one.

```bash
# Compile to find all affected call sites
npm run build

# Or use watch mode to get real-time feedback
npm run dev
```

---

## Integration with Other Features

### Combining with Duration Validation (Feature 001)

```typescript
// All validations work together
try {
  const talk = new Talk(
    '1',
    'A'.repeat(101),  // ❌ Title too long (>100 chars)
    'Description',
    'Speaker',
    45,
    'Beginner'
  );
} catch (error) {
  // Will throw InvalidTitleLengthError (title validation happens first)
}

try {
  const talk = new Talk(
    '1',
    'Valid Title',
    'Description',
    'Speaker',
    45,
    'Expert'  // ❌ Invalid difficulty
  );
} catch (error) {
  // Will throw InvalidDifficultyLevelError (difficulty validation happens last)
}
```

### Using with changeDuration()

```typescript
const originalTalk = new Talk(
  '1',
  'TypeScript Tips',
  'Quick tips for TS developers',
  'Jane Smith',
  15,
  'Intermediate'
);

// Change duration (difficulty is preserved)
const updatedTalk = originalTalk.changeDuration(45);

console.log(updatedTalk.duration);      // 45 (changed)
console.log(updatedTalk.difficulty);    // "Intermediate" (preserved)
console.log(updatedTalk.format);        // "Conference" (computed from new duration)
```

---

## Best Practices

### 1. Use Type Annotations

```typescript
// ✅ Good: Type-safe function signature
function scheduleTalk(difficulty: DifficultyLevel, room: string): void {
  // TypeScript ensures only valid difficulty levels are passed
}

// ❌ Bad: Untyped parameter
function scheduleTalk(difficulty: string, room: string): void {
  // Any string accepted, no compile-time validation
}
```

### 2. Centralize Validation Logic

```typescript
// ✅ Good: Use Talk entity validation (domain layer)
const talk = new Talk(id, title, abstract, speaker, duration, difficulty);
// Validation happens automatically

// ❌ Bad: Duplicate validation in application layer
if (difficulty !== 'Beginner' && difficulty !== 'Intermediate' && difficulty !== 'Advanced') {
  throw new Error('Invalid difficulty');  // Don't duplicate domain logic!
}
const talk = new Talk(id, title, abstract, speaker, duration, difficulty);
```

### 3. Expose DifficultyLevel Type

```typescript
// ✅ Good: Export type for reuse
import { Talk, DifficultyLevel } from './src/domain/talk.entity';

function filterByDifficulty(talks: Talk[], level: DifficultyLevel): Talk[] {
  return talks.filter(t => t.difficulty === level);
}

// ❌ Bad: Hardcode strings without type safety
function filterByDifficulty(talks: Talk[], level: string): Talk[] {
  return talks.filter(t => t.difficulty === level);  // No autocomplete, no type checking
}
```

### 4. Handle Errors Gracefully

```typescript
// ✅ Good: Specific error handling
try {
  const talk = new Talk(id, title, abstract, speaker, duration, difficulty);
  return { success: true, talk };
} catch (error) {
  if (error instanceof InvalidDifficultyLevelError) {
    return { success: false, error: 'Invalid difficulty level. Choose Beginner, Intermediate, or Advanced.' };
  }
  throw error;  // Re-throw unexpected errors
}

// ❌ Bad: Silent failure or generic error
try {
  const talk = new Talk(id, title, abstract, speaker, duration, difficulty);
  return talk;
} catch (error) {
  return null;  // Lost error information!
}
```

---

## Common Patterns

### Pattern 1: Validation Before Entity Creation

```typescript
function createTalkSafely(input: unknown): Talk | Error {
  // Type guard pattern
  if (!isValidTalkInput(input)) {
    return new Error('Invalid input structure');
  }

  try {
    return new Talk(
      input.id,
      input.title,
      input.abstract,
      input.speakerName,
      input.duration,
      input.difficulty
    );
  } catch (error) {
    return error as Error;
  }
}

function isValidTalkInput(input: any): input is TalkInput {
  return (
    typeof input === 'object' &&
    typeof input.id === 'string' &&
    typeof input.title === 'string' &&
    typeof input.abstract === 'string' &&
    typeof input.speakerName === 'string' &&
    typeof input.duration === 'number' &&
    typeof input.difficulty === 'string'
  );
}
```

### Pattern 2: Builder Pattern (Optional)

```typescript
class TalkBuilder {
  private id?: string;
  private title?: string;
  private abstract?: string;
  private speakerName?: string;
  private duration?: number;
  private difficulty?: DifficultyLevel;

  withId(id: string): this {
    this.id = id;
    return this;
  }

  withTitle(title: string): this {
    this.title = title;
    return this;
  }

  withDifficulty(difficulty: DifficultyLevel): this {
    this.difficulty = difficulty;
    return this;
  }

  // ... other setters

  build(): Talk {
    if (!this.id || !this.title || !this.abstract || !this.speakerName || !this.duration || !this.difficulty) {
      throw new Error('Missing required fields');
    }
    return new Talk(this.id, this.title, this.abstract, this.speakerName, this.duration, this.difficulty);
  }
}

// Usage
const talk = new TalkBuilder()
  .withId('1')
  .withTitle('TypeScript Patterns')
  .withAbstract('Learn design patterns')
  .withSpeakerName('Jane Doe')
  .withDuration(45)
  .withDifficulty('Intermediate')
  .build();
```

---

## Troubleshooting

### Problem: "Expected 6 arguments, but got 5"

**Cause**: Missing difficulty parameter after upgrading to Feature 002

**Solution**: Add difficulty level as 6th parameter to all Talk instantiations

```typescript
// Before
new Talk('1', 'Title', 'Abstract', 'Speaker', 45);

// After
new Talk('1', 'Title', 'Abstract', 'Speaker', 45, 'Beginner');
```

### Problem: "Invalid difficulty level: "beginner""

**Cause**: Case-sensitive validation, lowercase not accepted

**Solution**: Use exact case: "Beginner", "Intermediate", or "Advanced"

```typescript
// Wrong
new Talk('1', 'Title', 'Abstract', 'Speaker', 45, 'beginner');

// Correct
new Talk('1', 'Title', 'Abstract', 'Speaker', 45, 'Beginner');
```

### Problem: Runtime error from JSON deserialization

**Cause**: JSON contains invalid difficulty level

**Solution**: Validate and normalize JSON input before creating Talk entity

```typescript
function parseTalkFromJSON(json: string): Talk | Error {
  const data = JSON.parse(json);

  // Normalize difficulty
  const validDifficulties = ['Beginner', 'Intermediate', 'Advanced'];
  if (!validDifficulties.includes(data.difficulty)) {
    return new Error(`Invalid difficulty in JSON: ${data.difficulty}`);
  }

  try {
    return new Talk(
      data.id,
      data.title,
      data.abstract,
      data.speakerName,
      data.duration,
      data.difficulty as DifficultyLevel
    );
  } catch (error) {
    return error as Error;
  }
}
```

---

## Summary

### Key Takeaways

1. ✅ **Difficulty levels**: "Beginner", "Intermediate", "Advanced" (case-sensitive, exact match)
2. ✅ **Constructor change**: 6th parameter required (breaking change)
3. ✅ **Read-only access**: Use `talk.difficulty` getter (immutable)
4. ✅ **Error handling**: Catch `InvalidDifficultyLevelError` for validation failures
5. ✅ **Type safety**: Use `DifficultyLevel` type for function parameters and variables

### Quick Reference

```typescript
import { Talk, DifficultyLevel, InvalidDifficultyLevelError } from './src/domain/talk.entity';

// Create talk
const talk = new Talk('1', 'Title', 'Abstract', 'Speaker', 45, 'Beginner');

// Access difficulty
const level: DifficultyLevel = talk.difficulty;  // "Beginner"

// Error handling
try {
  new Talk('2', 'Title', 'Abstract', 'Speaker', 45, 'Expert');  // ❌ Invalid
} catch (error) {
  if (error instanceof InvalidDifficultyLevelError) {
    console.error(error.message);  // "Invalid difficulty level: "Expert". Valid levels are: Beginner, Intermediate, Advanced"
  }
}
```

**Need help?** See `data-model.md` for technical details or `research.md` for design rationale.

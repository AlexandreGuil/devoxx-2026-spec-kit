# Quickstart: Limit Number of Speakers per Talk

**Feature**: 003-limit-speakers
**Date**: 2026-01-31
**Audience**: Developers implementing or using the Talk entity

## Overview

This feature enforces a maximum of 3 speakers per talk. The Talk entity now accepts an array of speaker names (`speakers: string[]`) instead of a single name (`speakerName: string`).

**Breaking Change**: Constructor signature has changed. All code instantiating `Talk` must be updated.

---

## Basic Usage

### Creating a Talk with 1 Speaker

```typescript
import { Talk } from './domain/talk.entity.js';

const talk = new Talk(
  'talk-001',
  'Introduction to TypeScript',
  'Learn the basics of TypeScript in this session',
  ['Alice Johnson'],  // ← Array with 1 speaker
  45
);

console.log(talk.speakers); // ['Alice Johnson']
```

### Creating a Talk with Multiple Speakers

```typescript
const talk = new Talk(
  'talk-002',
  'Advanced React Patterns',
  'Deep dive into React hooks and context',
  ['Bob Smith', 'Carol White'],  // ← Array with 2 speakers
  90
);

console.log(talk.speakers); // ['Bob Smith', 'Carol White']
```

### Creating a Talk with Maximum Speakers (3)

```typescript
const talk = new Talk(
  'talk-003',
  'Microservices Architecture',
  'Building scalable systems',
  ['Alice Johnson', 'Bob Smith', 'Carol White'],  // ← Maximum 3 speakers
  45
);

console.log(talk.speakers); // ['Alice Johnson', 'Bob Smith', 'Carol White']
```

---

## Error Handling

### Too Many Speakers (>3)

```typescript
import { InvalidSpeakerCountError } from './domain/talk.entity.js';

try {
  const talk = new Talk(
    'talk-004',
    'Panel Discussion',
    'Group discussion',
    ['Alice', 'Bob', 'Carol', 'Dave'],  // ← 4 speakers (exceeds limit)
    45
  );
} catch (error) {
  if (error instanceof InvalidSpeakerCountError) {
    console.error(error.message);
    // Output: "Speaker count (4 speakers) exceeds the maximum allowed (3 speakers)"
  }
}
```

### No Speakers (Empty Array)

```typescript
try {
  const talk = new Talk(
    'talk-005',
    'Empty Talk',
    'Invalid talk',
    [],  // ← No speakers
    45
  );
} catch (error) {
  console.error(error.message);
  // Output: "At least one speaker is required"
}
```

---

## Migration Guide

### Before (Old Code)

```typescript
// Old constructor with single speaker string
const talk = new Talk(
  'talk-001',
  'My Talk',
  'Talk description',
  'John Doe',  // ← Single string
  45
);

console.log(talk.speakerName); // 'John Doe'
```

### After (New Code)

```typescript
// New constructor with speaker array
const talk = new Talk(
  'talk-001',
  'My Talk',
  'Talk description',
  ['John Doe'],  // ← Array of strings
  45
);

console.log(talk.speakers); // ['John Doe']
```

### Migrating Multiple Speakers

If you were previously storing multiple speakers as comma-separated strings:

```typescript
// Old approach (not recommended, but common)
const speakerString = 'Alice, Bob, Carol';
const talk = new Talk('id', 'title', 'abstract', speakerString, 45);

// New approach
const speakerArray = speakerString.split(',').map(name => name.trim());
const talk = new Talk('id', 'title', 'abstract', speakerArray, 45);
```

---

## Testing Examples

### Unit Test: Valid Speaker Counts

```typescript
import { describe, it, expect } from 'vitest';
import { Talk, InvalidSpeakerCountError } from '../../../src/domain/talk.entity.js';

describe('Talk Entity - Speaker Count Validation', () => {
  it('should accept talk with 1 speaker', () => {
    const talk = new Talk('1', 'Title', 'Abstract', ['Alice'], 45);
    expect(talk.speakers).toEqual(['Alice']);
    expect(talk.speakers.length).toBe(1);
  });

  it('should accept talk with 2 speakers', () => {
    const talk = new Talk('2', 'Title', 'Abstract', ['Alice', 'Bob'], 45);
    expect(talk.speakers).toEqual(['Alice', 'Bob']);
    expect(talk.speakers.length).toBe(2);
  });

  it('should accept talk with 3 speakers (maximum)', () => {
    const talk = new Talk('3', 'Title', 'Abstract', ['Alice', 'Bob', 'Carol'], 90);
    expect(talk.speakers).toEqual(['Alice', 'Bob', 'Carol']);
    expect(talk.speakers.length).toBe(3);
  });
});
```

### Unit Test: Invalid Speaker Counts

```typescript
describe('Talk Entity - Speaker Count Validation Errors', () => {
  it('should reject talk with 0 speakers', () => {
    expect(() => {
      new Talk('4', 'Title', 'Abstract', [], 45);
    }).toThrow('At least one speaker is required');
  });

  it('should reject talk with 4 speakers', () => {
    expect(() => {
      new Talk('5', 'Title', 'Abstract', ['A', 'B', 'C', 'D'], 45);
    }).toThrow(InvalidSpeakerCountError);
  });

  it('should include actual count and limit in error message', () => {
    expect(() => {
      new Talk('6', 'Title', 'Abstract', ['A', 'B', 'C', 'D', 'E'], 45);
    }).toThrow('Speaker count (5 speakers) exceeds the maximum allowed (3 speakers)');
  });

  it('should throw InvalidSpeakerCountError instance', () => {
    try {
      new Talk('7', 'Title', 'Abstract', ['A', 'B', 'C', 'D'], 45);
      expect.fail('Should have thrown error');
    } catch (error) {
      expect(error).toBeInstanceOf(InvalidSpeakerCountError);
      expect(error.name).toBe('InvalidSpeakerCountError');
    }
  });
});
```

---

## Application Layer Integration

### Submit Talk Use Case

**Before**:
```typescript
// Old use case (simplified)
export class SubmitTalkUseCase {
  async execute(data: { title: string; abstract: string; speakerName: string; duration: number }) {
    const talk = new Talk(
      generateId(),
      data.title,
      data.abstract,
      data.speakerName,  // ← Single string
      data.duration as Duration
    );
    await this.talkRepository.save(talk);
  }
}
```

**After**:
```typescript
// New use case (simplified)
export class SubmitTalkUseCase {
  async execute(data: { title: string; abstract: string; speakers: string[]; duration: number }) {
    // Validation: Check speaker count before creating entity
    if (data.speakers.length > 3) {
      throw new InvalidSpeakerCountError(data.speakers.length, 3);
    }

    const talk = new Talk(
      generateId(),
      data.title,
      data.abstract,
      data.speakers,  // ← Array of strings
      data.duration as Duration
    );
    await this.talkRepository.save(talk);
  }
}
```

**Note**: The validation in the use case is optional (defensive programming). The Talk entity constructor will also validate and throw the error if the count exceeds 3.

---

## CLI Integration Example

**Before**:
```typescript
// Old CLI prompt
const answers = await prompt([
  { type: 'input', name: 'title', message: 'Talk title:' },
  { type: 'input', name: 'speakerName', message: 'Speaker name:' },
  // ...
]);

await submitTalkUseCase.execute(answers);
```

**After**:
```typescript
// New CLI prompt
const answers = await prompt([
  { type: 'input', name: 'title', message: 'Talk title:' },
  {
    type: 'input',
    name: 'speakers',
    message: 'Speaker names (comma-separated, max 3):',
    validate: (input: string) => {
      const speakers = input.split(',').map(s => s.trim()).filter(s => s);
      if (speakers.length === 0) return 'At least one speaker is required';
      if (speakers.length > 3) return `Maximum 3 speakers allowed (you entered ${speakers.length})`;
      return true;
    }
  },
  // ...
]);

// Convert comma-separated input to array
const speakersArray = answers.speakers.split(',').map(s => s.trim()).filter(s => s);

await submitTalkUseCase.execute({
  ...answers,
  speakers: speakersArray
});
```

---

## Common Pitfalls

### ❌ Forgetting to Wrap Single Speaker in Array

```typescript
// WRONG
const talk = new Talk('id', 'title', 'abstract', 'Alice', 45);
// Error: Type 'string' is not assignable to type 'string[]'
```

```typescript
// CORRECT
const talk = new Talk('id', 'title', 'abstract', ['Alice'], 45);
```

### ❌ Using Spread Operator on String

```typescript
// WRONG
const speakerName = 'Alice';
const talk = new Talk('id', 'title', 'abstract', [...speakerName], 45);
// Result: ['A', 'l', 'i', 'c', 'e'] (array of characters!)
```

```typescript
// CORRECT
const speakerName = 'Alice';
const talk = new Talk('id', 'title', 'abstract', [speakerName], 45);
```

### ❌ Mutating the Speakers Array

```typescript
const talk = new Talk('id', 'title', 'abstract', ['Alice', 'Bob'], 45);

// WRONG (violates immutability)
talk.speakers.push('Carol');
// TypeScript will allow this, but violates entity immutability principles
```

**Best Practice**: Treat `talk.speakers` as readonly. If you need to add/remove speakers, create a new Talk instance (or add a mutation method like `addSpeaker(name: string): Talk` in the future).

---

## FAQ

### Q: Can I pass an empty string in the speakers array?

**A**: Currently, yes. Individual speaker name validation (empty, whitespace-only) is out of scope for this feature. This may be addressed in a future feature.

### Q: Can I have duplicate speaker names?

**A**: Currently, yes. Duplicate detection is not enforced by this feature.

### Q: What if I need more than 3 speakers?

**A**: This is a business constraint (badge limits, display space). If your use case requires more speakers, discuss with the business stakeholders to potentially increase the limit.

### Q: How do I get the speaker count?

```typescript
const talk = new Talk('id', 'title', 'abstract', ['Alice', 'Bob'], 45);
const speakerCount = talk.speakers.length; // 2
```

### Q: Can I modify the speakers array after instantiation?

**A**: No. The Talk entity is immutable. All properties are readonly. To change speakers, you would need to create a new Talk instance (or add a mutation method in the future).

---

## Summary

| Operation | Code |
|-----------|------|
| Create talk (1 speaker) | `new Talk(id, title, abstract, ['Alice'], 45)` |
| Create talk (2 speakers) | `new Talk(id, title, abstract, ['Alice', 'Bob'], 45)` |
| Create talk (3 speakers) | `new Talk(id, title, abstract, ['Alice', 'Bob', 'Carol'], 90)` |
| Get speaker count | `talk.speakers.length` |
| Access speakers | `talk.speakers` (readonly `string[]`) |
| Handle errors | `try/catch` with `InvalidSpeakerCountError` |

**Key Takeaway**: Always pass speakers as an array, even for a single speaker. The entity enforces 1-3 speakers and throws `InvalidSpeakerCountError` if the count exceeds 3.

---

**Quickstart Complete**: Developers can now use the new Talk entity API with speaker count validation.

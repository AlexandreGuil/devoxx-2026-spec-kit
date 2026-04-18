# Contract: InvalidAbstractLengthError

**Feature**: 004-validate-abstract-length
**Domain**: Talk Entity Validation
**Type**: Domain Error
**File Location**: `src/domain/talk.entity.ts`
**Created**: 2026-01-31

---

## Overview

`InvalidAbstractLengthError` is a domain error thrown when a talk abstract exceeds the maximum allowed length of 500 characters. This error enforces mobile application display constraints and ensures all talk abstracts can be properly displayed within UI boundaries.

---

## Error Class Signature

```typescript
export class InvalidAbstractLengthError extends Error {
  constructor(actualLength: number, maxLength: number);
}
```

### Inheritance

- **Extends**: `Error` (JavaScript/TypeScript built-in)
- **Type**: Domain Error (business rule violation)
- **Scope**: Public export from `talk.entity.ts`

---

## Properties

### Property: `name`

```typescript
readonly name: string = 'InvalidAbstractLengthError'
```

| Aspect | Specification |
|--------|---------------|
| **Type** | `string` |
| **Value** | `"InvalidAbstractLengthError"` (constant) |
| **Mutability** | Immutable (set in constructor) |
| **Purpose** | Error type identification for instanceof checks and error handling |
| **Contract** | MUST always equal `"InvalidAbstractLengthError"` |

**Usage in Error Handling**:
```typescript
try {
  const talk = new Talk(id, title, longAbstract, speakers, 45);
} catch (error) {
  if (error.name === 'InvalidAbstractLengthError') {
    // Handle abstract length validation error
  }
}
```

---

### Property: `message`

```typescript
readonly message: string
```

| Aspect | Specification |
|--------|---------------|
| **Type** | `string` |
| **Format** | `"Abstract length ({actualLength} characters) exceeds the maximum allowed length of {maxLength} characters"` |
| **Mutability** | Immutable (set in constructor via super()) |
| **Purpose** | Human-readable error description for logging and user feedback |
| **Contract** | MUST include both actual length and maximum allowed length |

**Message Format Contract**:
```typescript
// Pattern: "Abstract length (X characters) exceeds the maximum allowed length of Y characters"
// Where:
//   X = actualLength (number > maxLength)
//   Y = maxLength (always 500)

// Example messages:
"Abstract length (501 characters) exceeds the maximum allowed length of 500 characters"
"Abstract length (600 characters) exceeds the maximum allowed length of 500 characters"
"Abstract length (1000 characters) exceeds the maximum allowed length of 500 characters"
```

**Message Components** (MUST include all):
1. Phrase "Abstract length"
2. Actual length in parentheses with "characters" suffix
3. Phrase "exceeds the maximum allowed length of"
4. Maximum length with "characters" suffix

---

## Constructor Parameters

### Parameter: `actualLength`

```typescript
actualLength: number
```

| Aspect | Specification |
|--------|---------------|
| **Type** | `number` (integer) |
| **Valid Values** | Positive integer > 500 |
| **Purpose** | The actual character count of the abstract being validated |
| **Contract** | MUST be > maxLength when error is thrown |
| **Used In** | Error message construction |

**Validation**:
- No explicit validation in constructor (assumes caller provides correct value)
- In practice, will always be > 500 when thrown from Talk entity constructor

---

### Parameter: `maxLength`

```typescript
maxLength: number
```

| Aspect | Specification |
|--------|---------------|
| **Type** | `number` (integer) |
| **Valid Values** | 500 (constant) |
| **Purpose** | The maximum allowed character count for abstracts |
| **Contract** | MUST be 500 (business rule) |
| **Used In** | Error message construction |

**Validation**:
- No explicit validation in constructor
- In practice, will always be 500 when thrown from Talk entity constructor

---

## Constructor Implementation Contract

```typescript
constructor(actualLength: number, maxLength: number) {
  super(
    `Abstract length (${actualLength} characters) exceeds the maximum allowed length of ${maxLength} characters`,
  );
  this.name = 'InvalidAbstractLengthError';
}
```

### Constructor MUST:
1. Call `super()` with formatted message string
2. Set `this.name` to `'InvalidAbstractLengthError'`
3. Include both parameters in the message
4. Use exact message format specified above

### Constructor MUST NOT:
1. Validate input parameters (assumes correct usage)
2. Perform side effects (logging, I/O, etc.)
3. Throw other errors
4. Modify any external state

---

## Behavior Contracts

### Contract BC-1: When Thrown

**Condition**: Talk constructor receives abstract with length > 500 characters

```typescript
// GIVEN
const abstract = 'A'.repeat(501); // 501 characters
const talk = new Talk(id, title, abstract, speakers, duration);

// THEN
// - InvalidAbstractLengthError is thrown
// - Error.name === 'InvalidAbstractLengthError'
// - Error.message contains "501 characters"
// - Error.message contains "500 characters"
// - Talk entity is NOT created
// - No side effects occur
```

**Invariants When Thrown**:
- Abstract length MUST be > 500
- Error MUST be thrown before any other validation
- Error MUST be thrown synchronously (not async)
- Error MUST prevent Talk entity instantiation

---

### Contract BC-2: When NOT Thrown

**Condition**: Talk constructor receives abstract with length ≤ 500 characters

```typescript
// Valid abstracts (should NOT throw)
const abstract400 = 'A'.repeat(400);  // 400 chars - valid
const abstract500 = 'A'.repeat(500);  // 500 chars - valid (boundary)
const abstractShort = "Brief";         // 5 chars - valid
const abstractEmpty = "";              // 0 chars - valid (no minimum)

// For all valid abstracts:
const talk = new Talk(id, title, validAbstract, speakers, duration);
// - No error thrown
// - Talk entity created successfully
// - talk.abstract === validAbstract
```

**Invariants When NOT Thrown**:
- Abstract length MUST be ≤ 500
- Talk entity MUST be created successfully
- Validation continues to other properties (speakers, duration)

---

### Contract BC-3: Validation Order

**Position**: Abstract length validation occurs AFTER title validation, BEFORE speaker validation

```typescript
// Validation order in Talk constructor:
// 1. ID validation (empty check)
// 2. Title validation (empty check)
// 3. Title length validation (InvalidTitleLengthError)
// 4. Abstract length validation (InvalidAbstractLengthError) ← THIS ERROR
// 5. Speakers validation (empty check)
// 6. Speakers count validation (InvalidSpeakerCountError)
// 7. Duration validation (InvalidDurationError)
```

**Implications**:
- If title > 100 chars AND abstract > 500 chars: `InvalidTitleLengthError` thrown (not abstract error)
- If abstract > 500 chars AND speakers > 3: `InvalidAbstractLengthError` thrown (not speaker error)
- Abstract validation only runs if all previous validations pass

---

## Test Scenarios

### Scenario TS-1: Boundary Test (500 characters exactly)

```typescript
const abstract500 = 'A'.repeat(500);
const talk = new Talk("id-1", "Valid Title", abstract500, ["Alice"], 45);

// ASSERT:
expect(talk.abstract).toBe(abstract500);
expect(talk.abstract.length).toBe(500);
// No error thrown
```

**Expected**: Success (500 is valid, not exceeding maximum)

---

### Scenario TS-2: Boundary Test (501 characters)

```typescript
const abstract501 = 'A'.repeat(501);

// ASSERT:
expect(() => {
  new Talk("id-2", "Valid Title", abstract501, ["Bob"], 45);
}).toThrow(InvalidAbstractLengthError);
```

**Expected**: Error thrown (501 exceeds maximum)

---

### Scenario TS-3: Error Message Contains Actual Length

```typescript
const abstract600 = 'B'.repeat(600);

try {
  new Talk("id-3", "Valid Title", abstract600, ["Carol"], 45);
  fail("Expected InvalidAbstractLengthError");
} catch (error) {
  // ASSERT:
  expect(error).toBeInstanceOf(InvalidAbstractLengthError);
  expect(error.message).toContain("600 characters");
  expect(error.message).toContain("500 characters");
  expect(error.name).toBe("InvalidAbstractLengthError");
}
```

**Expected**: Error message includes both 600 (actual) and 500 (max)

---

### Scenario TS-4: Error Name Property

```typescript
const abstract1000 = 'C'.repeat(1000);

try {
  new Talk("id-4", "Valid Title", abstract1000, ["Dave"], 90);
} catch (error) {
  // ASSERT:
  expect(error.name).toBe("InvalidAbstractLengthError");
  expect(error instanceof InvalidAbstractLengthError).toBe(true);
}
```

**Expected**: Error has correct name property for type checking

---

### Scenario TS-5: Short Abstract (No Minimum)

```typescript
const abstractShort = "Brief";
const talk = new Talk("id-5", "Valid Title", abstractShort, ["Eve"], 30);

// ASSERT:
expect(talk.abstract).toBe("Brief");
expect(talk.abstract.length).toBe(5);
// No error thrown
```

**Expected**: Success (no minimum length enforced)

---

### Scenario TS-6: Empty Abstract

```typescript
const abstractEmpty = "";
const talk = new Talk("id-6", "Valid Title", abstractEmpty, ["Frank"], 15);

// ASSERT:
expect(talk.abstract).toBe("");
expect(talk.abstract.length).toBe(0);
// No error thrown
```

**Expected**: Success (empty abstracts allowed)

---

### Scenario TS-7: Abstract with Special Characters (Emoji)

```typescript
// Emoji "🎉" counts as 2 characters (UTF-16 surrogate pair)
const abstractEmoji = '🎉'.repeat(251); // 502 characters (251 * 2)

// ASSERT:
expect(() => {
  new Talk("id-7", "Valid Title", abstractEmoji, ["Grace"], 45);
}).toThrow(InvalidAbstractLengthError);

// Verify message shows correct length
try {
  new Talk("id-7", "Valid Title", abstractEmoji, ["Grace"], 45);
} catch (error) {
  expect(error.message).toContain("502 characters");
}
```

**Expected**: Error thrown, message shows 502 characters

---

### Scenario TS-8: Abstract with Newlines

```typescript
const abstractNewlines = 'A'.repeat(490) + '\n'.repeat(11); // 501 chars
expect(abstractNewlines.length).toBe(501);

// ASSERT:
expect(() => {
  new Talk("id-8", "Valid Title", abstractNewlines, ["Henry"], 90);
}).toThrow(InvalidAbstractLengthError);
```

**Expected**: Error thrown (newlines count as characters)

---

### Scenario TS-9: Abstract with Accented Characters

```typescript
const abstractAccent = 'é'.repeat(501); // 501 characters (each accented char = 1)
expect(abstractAccent.length).toBe(501);

// ASSERT:
expect(() => {
  new Talk("id-9", "Valid Title", abstractAccent, ["Isabelle"], 45);
}).toThrow(InvalidAbstractLengthError);
```

**Expected**: Error thrown (accented characters count normally)

---

### Scenario TS-10: Multiple Validation Errors (Title First)

```typescript
const longTitle = 'T'.repeat(101);      // Exceeds title max (100)
const longAbstract = 'A'.repeat(501);   // Exceeds abstract max (500)

// ASSERT:
expect(() => {
  new Talk("id-10", longTitle, longAbstract, ["Jack"], 45);
}).toThrow(InvalidTitleLengthError); // NOT InvalidAbstractLengthError
```

**Expected**: Title error thrown first (validation order)

---

### Scenario TS-11: Error Caught with instanceof

```typescript
const abstract700 = 'X'.repeat(700);

try {
  new Talk("id-11", "Valid Title", abstract700, ["Kate"], 30);
  fail("Expected error to be thrown");
} catch (error) {
  // ASSERT:
  if (error instanceof InvalidAbstractLengthError) {
    expect(error.message).toContain("700 characters");
    expect(error.message).toContain("500 characters");
  } else {
    fail("Expected InvalidAbstractLengthError");
  }
}
```

**Expected**: Error can be caught and identified with instanceof

---

## Invariants

### Invariant INV-1: Error Name Consistency

```typescript
// INVARIANT: error.name MUST always equal 'InvalidAbstractLengthError'
const error = new InvalidAbstractLengthError(600, 500);
expect(error.name).toBe('InvalidAbstractLengthError');
```

**Rationale**: Consistent error naming enables reliable error handling and type checking.

---

### Invariant INV-2: Message Format Consistency

```typescript
// INVARIANT: Message MUST follow exact format pattern
const error1 = new InvalidAbstractLengthError(501, 500);
const error2 = new InvalidAbstractLengthError(1000, 500);

// Both messages MUST match pattern:
// "Abstract length (X characters) exceeds the maximum allowed length of Y characters"
expect(error1.message).toMatch(/^Abstract length \(\d+ characters\) exceeds the maximum allowed length of \d+ characters$/);
expect(error2.message).toMatch(/^Abstract length \(\d+ characters\) exceeds the maximum allowed length of \d+ characters$/);
```

**Rationale**: Consistent message format enables parsing, logging, and user feedback.

---

### Invariant INV-3: Error is Throwable

```typescript
// INVARIANT: Error MUST be throwable and catchable
try {
  throw new InvalidAbstractLengthError(600, 500);
  fail("Error should have been thrown");
} catch (error) {
  expect(error).toBeInstanceOf(Error);
  expect(error).toBeInstanceOf(InvalidAbstractLengthError);
}
```

**Rationale**: Error must integrate with JavaScript/TypeScript error handling.

---

### Invariant INV-4: Error Prevents Entity Creation

```typescript
// INVARIANT: When thrown, Talk entity MUST NOT be created
let talk: Talk | undefined = undefined;

try {
  talk = new Talk("id", "Title", 'A'.repeat(501), ["Alice"], 45);
} catch (error) {
  // Talk was NOT created
}

expect(talk).toBeUndefined();
```

**Rationale**: Domain errors enforce business rules by preventing invalid state.

---

### Invariant INV-5: Synchronous Execution

```typescript
// INVARIANT: Error MUST be thrown synchronously (not async)
const throwError = () => {
  return new Talk("id", "Title", 'A'.repeat(501), ["Alice"], 45);
};

// Should throw immediately, not return a Promise
expect(throwError).toThrow(InvalidAbstractLengthError);
```

**Rationale**: Validation errors are synchronous domain rules, not async operations.

---

## Integration Points

### IP-1: Talk Entity Constructor

**Location**: `src/domain/talk.entity.ts` - `Talk` class constructor

```typescript
constructor(
  public readonly id: string,
  public readonly title: string,
  public readonly abstract: string,
  public readonly speakers: string[],
  private readonly _duration: Duration,
) {
  // ... other validations ...

  // INTEGRATION POINT: Throw InvalidAbstractLengthError
  if (abstract.length > 500) {
    throw new InvalidAbstractLengthError(abstract.length, 500);
  }

  // ... remaining validations ...
}
```

**Contract**:
- MUST throw when `abstract.length > 500`
- MUST pass actual length as first parameter
- MUST pass 500 as second parameter (maxLength)
- MUST execute after title validation, before speaker validation

---

### IP-2: Use Case Layer (Error Handling)

**Example**: `src/application/create-talk.use-case.ts`

```typescript
export class CreateTalkUseCase {
  async execute(dto: CreateTalkDto): Promise<Result<Talk>> {
    try {
      const talk = new Talk(
        dto.id,
        dto.title,
        dto.abstract,
        dto.speakers,
        dto.duration,
      );
      
      await this.talkRepository.save(talk);
      return Result.success(talk);
    } catch (error) {
      // INTEGRATION POINT: Catch and handle InvalidAbstractLengthError
      if (error instanceof InvalidAbstractLengthError) {
        return Result.failure({
          code: 'INVALID_ABSTRACT_LENGTH',
          message: error.message,
        });
      }
      
      throw error; // Re-throw unexpected errors
    }
  }
}
```

**Contract**:
- Use cases MUST catch `InvalidAbstractLengthError`
- Use cases SHOULD convert to Result/Either pattern
- Use cases SHOULD preserve error message for user feedback
- Use cases MUST NOT suppress the error silently

---

### IP-3: API/Presentation Layer

**Example**: REST API error response

```typescript
// HTTP POST /api/talks
try {
  const result = await createTalkUseCase.execute(requestBody);
  
  if (result.isFailure) {
    // INTEGRATION POINT: Map error to HTTP response
    if (result.error.code === 'INVALID_ABSTRACT_LENGTH') {
      return res.status(400).json({
        error: 'INVALID_ABSTRACT_LENGTH',
        message: result.error.message,
        field: 'abstract',
      });
    }
  }
  
  return res.status(201).json(result.value);
} catch (error) {
  return res.status(500).json({ error: 'Internal server error' });
}
```

**Contract**:
- API MUST return 400 Bad Request for validation errors
- API SHOULD include error message from InvalidAbstractLengthError
- API SHOULD indicate which field failed validation ('abstract')
- API MUST NOT expose internal error stack traces

---

### IP-4: Testing Layer

**Example**: Unit tests for Talk entity

```typescript
describe('Talk Entity - Abstract Length Validation', () => {
  it('should throw InvalidAbstractLengthError when abstract exceeds 500 characters', () => {
    // INTEGRATION POINT: Verify error is thrown correctly
    const longAbstract = 'A'.repeat(501);
    
    expect(() => {
      new Talk('id', 'Title', longAbstract, ['Speaker'], 45);
    }).toThrow(InvalidAbstractLengthError);
  });

  it('should include actual and max length in error message', () => {
    const longAbstract = 'B'.repeat(600);
    
    try {
      new Talk('id', 'Title', longAbstract, ['Speaker'], 45);
      fail('Expected error');
    } catch (error) {
      expect(error).toBeInstanceOf(InvalidAbstractLengthError);
      expect(error.message).toContain('600 characters');
      expect(error.message).toContain('500 characters');
    }
  });
});
```

**Contract**:
- Tests MUST verify error is thrown for invalid abstracts
- Tests MUST verify error message format and content
- Tests MUST verify error type (instanceof check)
- Tests MUST cover boundary cases (500, 501)

---

### IP-5: Logging and Monitoring

**Example**: Application logging

```typescript
try {
  const talk = new Talk(id, title, abstract, speakers, duration);
} catch (error) {
  // INTEGRATION POINT: Log validation errors
  if (error instanceof InvalidAbstractLengthError) {
    logger.warn('Abstract length validation failed', {
      errorName: error.name,
      errorMessage: error.message,
      talkId: id,
    });
  }
  
  throw error;
}
```

**Contract**:
- Logging SHOULD capture validation failures
- Logging SHOULD include error name and message
- Logging SHOULD include relevant context (e.g., talk ID)
- Logging MUST NOT log sensitive user data
- Logging MUST NOT suppress or swallow errors

---

## Non-Functional Requirements

### NFR-1: Performance

- Error instantiation MUST complete in < 1ms
- Error message construction MUST be O(1) complexity
- No external dependencies or I/O operations

### NFR-2: Memory

- Error instances MUST NOT retain references to large objects
- Error message MUST NOT include full abstract content (only length)

### NFR-3: Compatibility

- MUST be compatible with JavaScript Error handling (try/catch)
- MUST work in Node.js and browser environments
- MUST support TypeScript type checking (instanceof)

### NFR-4: Maintainability

- Error message format MUST be consistent with other domain errors
- Constructor signature MUST match similar errors (InvalidTitleLengthError, InvalidSpeakerCountError)
- Error class MUST be co-located with Talk entity (same file)

---

## Related Contracts

- **Talk Entity Contract**: Abstract validation is part of Talk entity invariants
- **InvalidTitleLengthError Contract**: Similar error for title length validation
- **InvalidSpeakerCountError Contract**: Similar error for speaker count validation
- **InvalidDurationError Contract**: Similar error for duration validation

---

## References

- **Feature Spec**: `specs/004-validate-abstract-length/spec.md`
- **Data Model**: `specs/004-validate-abstract-length/data-model.md`
- **ADR**: `docs/adrs/0007-validate-abstract-length.md` (to be created)
- **Implementation**: `src/domain/talk.entity.ts`

---

**Contract Status**: Draft
**Review Required**: Yes (before implementation)
**Breaking Change**: No (new error, existing errors unchanged)

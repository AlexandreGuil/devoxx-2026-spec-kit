# Contract: InvalidSpeakerCountError

**Feature**: 003-limit-speakers
**Date**: 2026-01-31
**Type**: Domain Error
**Location**: `src/domain/talk.entity.ts`

## Purpose

This contract defines the behavior and guarantees of the `InvalidSpeakerCountError` domain error, which is thrown when a Talk entity is instantiated with more than the maximum allowed number of speakers (3).

---

## Error Class Signature

```typescript
export class InvalidSpeakerCountError extends Error {
  constructor(actualCount: number, maxCount: number);
}
```

---

## Properties

### name

- **Type**: `string`
- **Value**: `"InvalidSpeakerCountError"`
- **Mutability**: Immutable
- **Contract**: MUST always be set to `"InvalidSpeakerCountError"` for type checking and error identification

### message

- **Type**: `string`
- **Format**: `"Speaker count (${actualCount} speakers) exceeds the maximum allowed (${maxCount} speakers)"`
- **Mutability**: Immutable
- **Contract**: MUST include both the actual speaker count and the maximum allowed count
- **Examples**:
  - `"Speaker count (4 speakers) exceeds the maximum allowed (3 speakers)"`
  - `"Speaker count (5 speakers) exceeds the maximum allowed (3 speakers)"`
  - `"Speaker count (10 speakers) exceeds the maximum allowed (3 speakers)"`

---

## Behavior Contracts

### When Thrown

**Contract**: This error MUST be thrown when and only when:
- A `Talk` entity is instantiated
- The `speakers` parameter is an array with length > 3

**Example**:
```typescript
const speakers = ['Alice', 'Bob', 'Carol', 'Dave']; // length = 4
const talk = new Talk('id', 'title', 'abstract', speakers, 45);
// MUST throw InvalidSpeakerCountError
```

### When NOT Thrown

**Contract**: This error MUST NOT be thrown when:
- `speakers.length === 1` (minimum valid)
- `speakers.length === 2` (valid)
- `speakers.length === 3` (maximum valid)
- `speakers.length === 0` (different error: generic Error with message "At least one speaker is required")

---

## Constructor Parameters

### actualCount

- **Type**: `number`
- **Purpose**: The actual number of speakers provided by the user
- **Contract**: MUST accurately reflect `speakers.length` at the time of error
- **Range**: In practice, will be ≥ 4 (since error only thrown when > 3)

### maxCount

- **Type**: `number`
- **Purpose**: The maximum allowed number of speakers
- **Contract**: MUST always be `3` (current business rule)
- **Note**: This parameter allows future flexibility if the limit changes

---

## Message Format Contract

### Required Elements

1. **Actual count phrase**: `"${actualCount} speakers"`
   - MUST use plural "speakers" (not "speaker")
   - MUST include the numeric value

2. **Maximum count phrase**: `"${maxCount} speakers"`
   - MUST use plural "speakers" (not "speaker")
   - MUST include the numeric value

3. **Verb phrase**: `"exceeds the maximum allowed"`
   - MUST clearly indicate the violation type

### Message Structure

```
"Speaker count (${actualCount} speakers) exceeds the maximum allowed (${maxCount} speakers)"
```

**Parts**:
- Prefix: `"Speaker count "`
- Actual value: `"(${actualCount} speakers)"`
- Verb: `" exceeds the maximum allowed "`
- Max value: `"(${maxCount} speakers)"`

### Localization

**Contract**: The error message is currently English-only. Future localization should preserve:
- Actual count value
- Maximum count value
- Clear indication of violation

---

## Error Handling Contract

### Type Checking

**Contract**: Consumers MUST be able to distinguish this error from other errors using `instanceof`:

```typescript
try {
  const talk = new Talk('id', 'title', 'abstract', ['A', 'B', 'C', 'D'], 45);
} catch (error) {
  if (error instanceof InvalidSpeakerCountError) {
    // Handle speaker count violation specifically
  }
}
```

### Error Name Checking

**Contract**: Consumers MUST be able to identify this error by checking the `name` property:

```typescript
try {
  // ... create talk
} catch (error) {
  if (error.name === 'InvalidSpeakerCountError') {
    // Handle speaker count violation
  }
}
```

---

## Test Scenarios

### Scenario 1: Error Thrown with 4 Speakers

**Given**: A Talk is instantiated with 4 speakers
**When**: The constructor executes
**Then**:
- An `InvalidSpeakerCountError` MUST be thrown
- `error.name` MUST equal `"InvalidSpeakerCountError"`
- `error.message` MUST equal `"Speaker count (4 speakers) exceeds the maximum allowed (3 speakers)"`
- `error instanceof InvalidSpeakerCountError` MUST be `true`

```typescript
expect(() => {
  new Talk('id', 'title', 'abstract', ['A', 'B', 'C', 'D'], 45);
}).toThrow(InvalidSpeakerCountError);
```

### Scenario 2: Error Thrown with 5 Speakers

**Given**: A Talk is instantiated with 5 speakers
**When**: The constructor executes
**Then**:
- An `InvalidSpeakerCountError` MUST be thrown
- `error.message` MUST include `"5 speakers"` (actual count)
- `error.message` MUST include `"3 speakers"` (maximum)

```typescript
try {
  new Talk('id', 'title', 'abstract', ['A', 'B', 'C', 'D', 'E'], 45);
} catch (error) {
  expect(error.message).toContain('5 speakers');
  expect(error.message).toContain('3 speakers');
}
```

### Scenario 3: Error NOT Thrown with 3 Speakers

**Given**: A Talk is instantiated with 3 speakers (maximum)
**When**: The constructor executes
**Then**:
- NO error MUST be thrown
- A valid Talk instance MUST be returned

```typescript
expect(() => {
  new Talk('id', 'title', 'abstract', ['A', 'B', 'C'], 45);
}).not.toThrow();
```

### Scenario 4: Error NOT Thrown with 1 Speaker

**Given**: A Talk is instantiated with 1 speaker (minimum)
**When**: The constructor executes
**Then**:
- NO `InvalidSpeakerCountError` MUST be thrown
- A valid Talk instance MUST be returned

```typescript
const talk = new Talk('id', 'title', 'abstract', ['Alice'], 45);
expect(talk.speakers).toEqual(['Alice']);
```

### Scenario 5: Different Error with 0 Speakers

**Given**: A Talk is instantiated with 0 speakers
**When**: The constructor executes
**Then**:
- A generic `Error` MUST be thrown (NOT `InvalidSpeakerCountError`)
- The message MUST be `"At least one speaker is required"`

```typescript
expect(() => {
  new Talk('id', 'title', 'abstract', [], 45);
}).toThrow('At least one speaker is required');

expect(() => {
  new Talk('id', 'title', 'abstract', [], 45);
}).not.toThrow(InvalidSpeakerCountError);
```

---

## Invariants

1. **Name Invariant**: `error.name === "InvalidSpeakerCountError"` for all instances
2. **Message Format Invariant**: Message MUST always contain both actual count and max count in the specified format
3. **Throw Condition Invariant**: MUST be thrown if and only if `speakers.length > 3`
4. **Inheritance Invariant**: MUST extend `Error` class
5. **Immutability Invariant**: Properties `name` and `message` MUST NOT change after instantiation

---

## Integration Points

### Domain Layer

**File**: `src/domain/talk.entity.ts`

**Usage**:
```typescript
if (speakers.length > 3) {
  throw new InvalidSpeakerCountError(speakers.length, 3);
}
```

**Contract**: Error MUST be thrown during Talk entity instantiation (constructor), not after

### Application Layer

**File**: `src/application/submit-talk.usecase.ts`

**Usage** (optional defensive check):
```typescript
if (data.speakers.length > 3) {
  throw new InvalidSpeakerCountError(data.speakers.length, 3);
}
```

**Contract**: Application layer MAY catch and re-throw or transform this error for user-facing messages

### Infrastructure Layer

**File**: `src/infrastructure/cli.ts`

**Usage**:
```typescript
try {
  await submitTalkUseCase.execute(data);
} catch (error) {
  if (error instanceof InvalidSpeakerCountError) {
    console.error('Validation failed:', error.message);
    // User-friendly message: "Please reduce the number of speakers to 3 or fewer"
  }
}
```

**Contract**: Infrastructure layer MUST handle this error gracefully and provide user-friendly feedback

---

## Future Considerations

### Potential Changes

1. **Maximum count parameterization**: If the limit changes from 3, the `maxCount` parameter allows flexibility
2. **Localization**: Message format may need translation while preserving numeric values
3. **Error codes**: May add numeric error code property for API responses

### Backward Compatibility

**Contract**: The following MUST remain stable:
- Error class name: `InvalidSpeakerCountError`
- `name` property value: `"InvalidSpeakerCountError"`
- Message includes actual count and max count (format may evolve)
- `instanceof InvalidSpeakerCountError` type checking continues to work

---

## Summary

This contract ensures that `InvalidSpeakerCountError`:
1. Is thrown consistently when speaker count exceeds 3
2. Provides clear, actionable error messages
3. Can be reliably caught and handled by consumers
4. Maintains stable API for type checking and error identification

**Contract Version**: 1.0.0
**Status**: Active (feature not yet implemented)

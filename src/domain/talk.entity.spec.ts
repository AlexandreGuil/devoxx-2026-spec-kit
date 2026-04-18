import { describe, it, expect } from 'vitest';
import { Talk, InvalidAbstractLengthError } from './talk.entity.js';
import type { Duration } from './talk.entity.js';

/**
 * Tests pour la validation de la longueur de l'abstract (ADR-0007)
 * Contrainte : abstract.length <= 500
 */

const VALID_TALK_DEFAULTS = {
  id: 'talk-test',
  title: 'Un talk de test valide',
  speakerName: 'Test Speaker',
  duration: 30 as Duration,
};

function createTalk(abstractOverride: string): Talk {
  return new Talk(
    VALID_TALK_DEFAULTS.id,
    VALID_TALK_DEFAULTS.title,
    abstractOverride,
    VALID_TALK_DEFAULTS.speakerName,
    VALID_TALK_DEFAULTS.duration,
  );
}

describe('Talk \u2014 abstract length validation', () => {
  it('should accept an abstract of exactly 500 characters', () => {
    const abstract = 'A'.repeat(500);
    const talk = createTalk(abstract);
    expect(talk.abstract).toBe(abstract);
  });

  it('should throw InvalidAbstractLengthError for an abstract of 501 characters', () => {
    const abstract = 'A'.repeat(501);
    expect(() => createTalk(abstract)).toThrow(InvalidAbstractLengthError);
    expect(() => createTalk(abstract)).toThrow(
      'Abstract length (501 characters) exceeds the maximum allowed length of 500 characters',
    );
  });

  it('should accept an empty abstract (no minimum length)', () => {
    const talk = createTalk('');
    expect(talk.abstract).toBe('');
  });
});

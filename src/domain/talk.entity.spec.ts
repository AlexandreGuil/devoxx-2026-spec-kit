import { describe, it, expect } from 'vitest';
import { Talk, InvalidBioLengthError } from './talk.entity.js';
import type { Duration } from './talk.entity.js';

/**
 * Tests pour la validation de la biographie speaker (ADR-0006)
 * Contraintes : 50 <= bio.trim().length <= 500
 */

const VALID_TALK_DEFAULTS = {
  id: 'talk-test',
  title: 'Un talk de test valide',
  abstract: 'Abstract valide pour les tests unitaires.',
  speakerName: 'Test Speaker',
  duration: 30 as Duration,
};

function createTalk(bioOverride: string): Talk {
  return new Talk(
    VALID_TALK_DEFAULTS.id,
    VALID_TALK_DEFAULTS.title,
    VALID_TALK_DEFAULTS.abstract,
    VALID_TALK_DEFAULTS.speakerName,
    bioOverride,
    VALID_TALK_DEFAULTS.duration,
  );
}

describe('Talk bio validation', () => {
  it('should accept a bio with exactly 50 characters', () => {
    const bio = 'A'.repeat(50);
    const talk = createTalk(bio);
    expect(talk.bio).toBe(bio);
  });

  it('should accept a bio with exactly 500 characters', () => {
    const bio = 'B'.repeat(500);
    const talk = createTalk(bio);
    expect(talk.bio).toBe(bio);
  });

  it('should throw InvalidBioLengthError when bio is too short (49 chars)', () => {
    const bio = 'C'.repeat(49);
    expect(() => createTalk(bio)).toThrow(InvalidBioLengthError);
    expect(() => createTalk(bio)).toThrow(
      'Bio length (49 characters) is below the minimum of 50 characters',
    );
  });

  it('should throw InvalidBioLengthError when bio is too long (501 chars)', () => {
    const bio = 'D'.repeat(501);
    expect(() => createTalk(bio)).toThrow(InvalidBioLengthError);
    expect(() => createTalk(bio)).toThrow(
      'Bio length (501 characters) exceeds the maximum of 500 characters',
    );
  });

  it('should throw InvalidBioLengthError for whitespace-only bio (trimmed to 0)', () => {
    const bio = '   \t\n   ';
    expect(() => createTalk(bio)).toThrow(InvalidBioLengthError);
    expect(() => createTalk(bio)).toThrow(
      'Bio length (0 characters) is below the minimum of 50 characters',
    );
  });
});

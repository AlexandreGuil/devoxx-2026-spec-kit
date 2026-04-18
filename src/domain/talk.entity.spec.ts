import { describe, it, expect } from 'vitest';
import { Talk, InvalidSpeakerCountError } from './talk.entity.js';

describe('Talk — speaker count validation', () => {
  const validArgs = {
    id: 'talk-test',
    title: 'Un talk de test',
    abstract: 'Description du talk de test.',
  };

  it('accepts a talk with 1 speaker', () => {
    const talk = new Talk(validArgs.id, validArgs.title, validArgs.abstract, ['Alice'], 30);
    expect(talk.speakers).toEqual(['Alice']);
  });

  it('accepts a talk with 3 speakers (maximum)', () => {
    const speakers = ['Alice', 'Bob', 'Charlie'];
    const talk = new Talk(validArgs.id, validArgs.title, validArgs.abstract, speakers, 30);
    expect(talk.speakers).toEqual(speakers);
  });

  it('rejects a talk with 0 speakers', () => {
    expect(
      () => new Talk(validArgs.id, validArgs.title, validArgs.abstract, [], 30),
    ).toThrow(InvalidSpeakerCountError);
  });

  it('rejects a talk with 4 speakers', () => {
    const speakers = ['Alice', 'Bob', 'Charlie', 'Diana'];
    expect(
      () => new Talk(validArgs.id, validArgs.title, validArgs.abstract, speakers, 30),
    ).toThrow(InvalidSpeakerCountError);
  });
});

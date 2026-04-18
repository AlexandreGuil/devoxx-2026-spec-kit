/**
 * Application Layer: List Talks Use Case
 *
 * Retrieves all submitted talks from the repository.
 */

import type { Talk } from '../domain/talk.entity.js';
import type { TalkRepository } from '../domain/talk.repository.js';

export class ListTalksUseCase {
  constructor(private readonly talkRepository: TalkRepository) {}

  /**
   * Returns all talks submitted to the Devoxx portal.
   */
  async execute(): Promise<Talk[]> {
    return this.talkRepository.findAll();
  }
}

/**
 * Application Layer: Submit Talk Use Case
 *
 * Orchestrates the submission of a new Talk to the Devoxx portal.
 * Depends only on domain interfaces (Clean Architecture).
 */

import { Talk, Duration } from '../domain/talk.entity.js';
import type { TalkRepository } from '../domain/talk.repository.js';

export interface SubmitTalkInput {
  id: string;
  title: string;
  abstract: string;
  speakerName: string;
  bio: string;
  duration: Duration;
}

export class SubmitTalkUseCase {
  constructor(private readonly talkRepository: TalkRepository) {}

  /**
   * Submits a new talk to the Devoxx portal.
   *
   * @param input - Talk submission data
   * @returns The created Talk entity
   * @throws Error if validation fails (domain rules)
   */
  async execute(input: SubmitTalkInput): Promise<Talk> {
    const talk = new Talk(
      input.id,
      input.title,
      input.abstract,
      input.speakerName,
      input.bio,
      input.duration,
    );

    await this.talkRepository.save(talk);

    return talk;
  }
}

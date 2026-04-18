import type { Talk } from './talk.entity.js';

/**
 * TalkRepository (Domain Port)
 * - Interface defined in the domain layer
 * - Implemented by infrastructure adapters
 * - No external imports
 */
export interface TalkRepository {
  findAll(): Promise<Talk[]>;
  findById(id: string): Promise<Talk | undefined>;
  save(talk: Talk): Promise<void>;
}

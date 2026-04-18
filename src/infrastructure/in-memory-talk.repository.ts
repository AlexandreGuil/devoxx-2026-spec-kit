/**
 * Infrastructure Layer: In-Memory Talk Repository
 *
 * Concrete adapter implementing the TalkRepository port.
 * Used for demos and local development.
 */

import { Talk } from '../domain/talk.entity.js';
import type { TalkRepository } from '../domain/talk.repository.js';

export class InMemoryTalkRepository implements TalkRepository {
  private talks: Map<string, Talk> = new Map();

  constructor() {
    // Demo data: Sample talks for Devoxx 2026
    const demoTalks: Talk[] = [
      new Talk(
        'talk-001',
        'Stop a la dette documentaire avec Spec-kit',
        'Decouvrez comment GitHub Spec-kit transforme votre documentation en validation automatique.',
        'Alexandre Guillemot',
        'Architecte logiciel chez WeScale, Alexandre accompagne les equipes dans leur transformation DevOps et Cloud Native depuis 8 ans.',
        30,
      ),
      new Talk(
        'talk-002',
        'Clean Architecture en 15 minutes',
        'Les principes essentiels de la Clean Architecture expliques rapidement.',
        'Marie Dupont',
        'Developpeuse senior specialisee en architecture logicielle et Domain-Driven Design. Contributrice active a la communaute TypeScript francophone.',
        15,
      ),
      new Talk(
        'talk-003',
        'TypeScript avance pour le Domain-Driven Design',
        'Techniques TypeScript pour modeliser des domaines metier riches et expressifs.',
        'Jean Martin',
        'Consultant independant en ingenierie logicielle, Jean intervient sur des projets complexes alliant TypeScript, DDD et architecture hexagonale.',
        45,
      ),
    ];

    demoTalks.forEach((talk) => this.talks.set(talk.id, talk));
  }

  async findAll(): Promise<Talk[]> {
    return Array.from(this.talks.values());
  }

  async findById(id: string): Promise<Talk | undefined> {
    return this.talks.get(id);
  }

  async save(talk: Talk): Promise<void> {
    this.talks.set(talk.id, talk);
  }
}

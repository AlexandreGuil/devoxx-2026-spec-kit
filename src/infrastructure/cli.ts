#!/usr/bin/env node
/* eslint-disable no-console */
/**
 * Infrastructure Layer: CLI Entry Point
 *
 * Composes dependencies and executes use cases.
 * Demonstrates Clean Architecture in action for the Devoxx Portal.
 */

import { InMemoryTalkRepository } from './in-memory-talk.repository.js';
import { ListTalksUseCase } from '../application/list-talks.usecase.js';
import { SubmitTalkUseCase } from '../application/submit-talk.usecase.js';

async function main() {
  console.log('🎤 Portail Devoxx 2026 - Talk Management Demo\n');

  // Dependency injection (composition root)
  const repository = new InMemoryTalkRepository();
  const listTalks = new ListTalksUseCase(repository);
  const submitTalk = new SubmitTalkUseCase(repository);

  // Demo 1: List existing talks
  console.log('📋 Talks soumis :');
  console.log('─'.repeat(60));

  const talks = await listTalks.execute();
  talks.forEach((talk) => {
    const formatIcon =
      talk.format === 'Quickie' ? '⚡' : talk.format === 'Tools-in-Action' ? '🔧' : '🎯';
    console.log(`  ${formatIcon} [${talk.format}] ${talk.title}`);
    console.log(`     👤 ${talk.speakers.join(', ')} | ⏱️  ${talk.duration} min`);
    console.log();
  });

  // Demo 2: Submit a new talk
  console.log('─'.repeat(60));
  console.log("📝 Soumission d'un nouveau talk...\n");

  const newTalk = await submitTalk.execute({
    id: 'talk-004',
    title: 'Machine-Readable Governance avec GitHub Spec-kit',
    abstract:
      'Comment industrialiser vos ADRs et READMEs pour que la documentation devienne votre meilleur gardien.',
    speakers: ['Alex Demo'],
    duration: 30,
  });

  console.log(`  ✅ Talk soumis avec succès !`);
  console.log(`     📌 "${newTalk.title}"`);
  console.log(`     👤 ${newTalk.speakers.join(', ')}`);
  console.log(`     🔧 Format: ${newTalk.format} (${newTalk.duration} min)`);

  // Demo 3: Show domain rule enforcement
  console.log('\n' + '─'.repeat(60));
  console.log('🛡️  Démonstration de la règle métier (durée invalide)...\n');

  try {
    await submitTalk.execute({
      id: 'talk-005',
      title: 'Talk avec durée invalide',
      abstract: 'Ce talk ne devrait pas passer la validation.',
      speakers: ['Test Speaker'],
      duration: 20 as 15, // Invalid duration - will throw
    });
  } catch (error) {
    if (error instanceof Error) {
      console.log(`  ❌ Erreur métier capturée :`);
      console.log(`     ${error.message}`);
    }
  }

  console.log('\n✨ Clean Architecture en action !');
  console.log('   Domain → Application → Infrastructure');
  console.log('   Les règles métier vivent dans le Domain.\n');
}

main().catch((error) => {
  console.error('❌ Erreur fatale :', error.message);
  process.exit(1);
});

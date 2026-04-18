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
  console.log('Portail Devoxx 2026 - Talk Management Demo\n');

  const repository = new InMemoryTalkRepository();
  const listTalks = new ListTalksUseCase(repository);
  const submitTalk = new SubmitTalkUseCase(repository);

  console.log('Talks soumis :');
  console.log('-'.repeat(60));

  const talks = await listTalks.execute();
  talks.forEach((talk) => {
    console.log(`  [${talk.format}] ${talk.title}`);
    console.log(`     ${talk.speakerName} | ${talk.duration} min`);
    console.log();
  });

  console.log('-'.repeat(60));
  console.log("Soumission d'un nouveau talk...\n");

  const newTalk = await submitTalk.execute({
    id: 'talk-004',
    title: 'Machine-Readable Governance avec GitHub Spec-kit',
    abstract: 'Comment industrialiser vos ADRs et READMEs pour que la documentation devienne votre meilleur gardien.',
    speakerName: 'Alex Demo',
    bio: 'Ingenieur logiciel passionne par la gouvernance automatisee et les pratiques DevOps modernes. Speaker regulier dans les conferences tech.',
    duration: 30,
  });

  console.log('  Talk soumis avec succes !');
  console.log(`     "${newTalk.title}"`);
  console.log(`     ${newTalk.speakerName}`);
  console.log(`     Format: ${newTalk.format} (${newTalk.duration} min)`);

  console.log('\n' + '-'.repeat(60));
  console.log('Demonstration de la regle metier (duree invalide)...\n');

  try {
    await submitTalk.execute({
      id: 'talk-005',
      title: 'Talk avec duree invalide',
      abstract: 'Ce talk ne devrait pas passer la validation.',
      speakerName: 'Test Speaker',
      bio: 'Speaker experimentee avec plus de 10 ans dans le developpement logiciel et les architectures distribuees.',
      duration: 20 as 15,
    });
  } catch (error) {
    if (error instanceof Error) {
      console.log('  Erreur metier capturee :');
      console.log(`     ${error.message}`);
    }
  }

  console.log('\nClean Architecture en action !');
  console.log('   Domain -> Application -> Infrastructure');
  console.log('   Les regles metier vivent dans le Domain.\n');
}

main().catch((error) => {
  console.error('Erreur fatale :', error.message);
  process.exit(1);
});

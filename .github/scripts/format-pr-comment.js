/**
 * PR Comment Formatter for Spec-kit Governance Reports
 * Transforms JSON agent reports into user-friendly Markdown
 */

import fs from 'fs';

// Parse command line arguments
const args = process.argv.slice(2);
const getArg = (name) => {
  const idx = args.indexOf(`--${name}`);
  return idx > -1 && args[idx + 1] ? args[idx + 1] : null;
};

const structurePath = getArg('structure') || 'structure-validation-report.json';
const adrPath = getArg('adr') || 'adr-review-report.json';
const adrMarkdownPath = getArg('adr-md') || 'adr-review-report.md';
const coherencePath = getArg('coherence') || 'coherence-check-report.json';
const coherenceMarkdownPath = getArg('coherence-md') || 'coherence-check-report.md';
const speckitContextPath = getArg('speckit-context') || 'speckit-context.json';
const overallStatus = getArg('status') || 'UNKNOWN';
const overallScore = parseInt(getArg('score') || '0', 10);
const threshold = parseInt(getArg('threshold') || '80', 10);
const validationMode = getArg('validation-mode') || 'legacy';
const featureName = getArg('feature-name') || 'unknown';
const outputPath = getArg('output') || 'pr-comment.md';

// Helper: Read JSON file safely
const readJSON = (filePath) => {
  try {
    if (fs.existsSync(filePath)) {
      return JSON.parse(fs.readFileSync(filePath, 'utf8'));
    }
  } catch (e) {
    console.warn(`Warning: Could not read ${filePath}: ${e.message}`);
  }
  return null;
};

// Helper: Read Markdown file safely (for rich Claude analysis)
const readMarkdown = (filePath) => {
  try {
    if (fs.existsSync(filePath)) {
      return fs.readFileSync(filePath, 'utf8').trim();
    }
  } catch (e) {
    console.warn(`Warning: Could not read ${filePath}: ${e.message}`);
  }
  return null;
};

// Helper: Generate progress bar
const progressBar = (score, max = 100, width = 20) => {
  const pct = Math.min(100, Math.max(0, (score / max) * 100));
  const filled = Math.round((pct / 100) * width);
  const empty = width - filled;
  const bar = '█'.repeat(filled) + '░'.repeat(empty);
  return `\`${bar}\` ${Math.round(pct)}%`;
};

// Helper: Status icon
const statusIcon = (status) => {
  switch (status?.toUpperCase()) {
    case 'PASS': return '✅';
    case 'FAIL': return '❌';
    case 'NEEDS_REVIEW': return '⚠️';
    case 'SKIP': return '⏭️';
    default: return '❓';
  }
};

// Helper: Check icon
const checkIcon = (value) => value ? '✅' : '❌';

// Load agent reports
const structure = readJSON(structurePath);
const adr = readJSON(adrPath);
const adrMarkdown = readMarkdown(adrMarkdownPath);
const coherence = readJSON(coherencePath);
const coherenceMarkdown = readMarkdown(coherenceMarkdownPath);
const speckitContext = readJSON(speckitContextPath);

// Determine pass/fail
const passed = overallStatus.toUpperCase() === 'PASS';

// Determine if we're in Spec-kit mode or fallback mode
const isSpeckitMode = validationMode === 'speckit' || speckitContext?.has_specs === true;

// Generate fallback warning banner
const generateFallbackBanner = () => {
  if (isSpeckitMode) return '';

  return `
## ⚠️ MODE DÉGRADÉ (Sans Spec-kit)

\`\`\`
┌─────────────────────────────────────────────────────────────────────────────┐
│  ⚠️  ATTENTION: VALIDATION EN MODE DÉGRADÉ                                  │
│  ───────────────────────────────────────────────────────────────────────── │
│                                                                             │
│  Aucun artefact Spec-kit trouvé pour cette feature.                        │
│                                                                             │
│  📁 Recherché dans:                                                         │
│     • .specify/specs/${featureName}/                                        │
│     • specs/${featureName}/                                                 │
│                                                                             │
│  💡 Pour une validation optimale, utilisez les commandes Spec-kit:         │
│     1. /speckit.specify - Créer la spécification                           │
│     2. /speckit.plan    - Générer le plan technique                        │
│     3. /speckit.tasks   - Générer les tâches de gouvernance                │
│                                                                             │
│  📖 Mode actuel: LEGACY (validation générique sans contexte spécifique)    │
└─────────────────────────────────────────────────────────────────────────────┘
\`\`\`

---

`;
};

// Generate Spec-kit context section
const generateSpeckitContextSection = () => {
  const hasSpecs = isSpeckitMode;
  const artifacts = speckitContext?.artifacts || {};
  const counts = speckitContext?.counts || {};

  return `
### 📖 Spec-kit Context

| Artefact | Status |
|----------|--------|
| \`spec.md\` | ${artifacts.spec_md ? `✅ Found (${counts.user_stories || 0} user stories)` : '❌ Not found'} |
| \`plan.md\` | ${artifacts.plan_md ? `✅ Found (${counts.planned_files || 0} planned files)` : '❌ Not found'} |
| \`tasks.md\` | ${artifacts.tasks_md ? `✅ Found (${counts.governance_tasks || 0} TGOV tasks)` : '❌ Not found'} |

**Validation Mode**: ${hasSpecs ? '🎯 **Spec-kit Driven** - Validation basée sur vos spécifications' : '⚠️ **<Leg>acy Fallback** - Validation générique (non optimisée)'}

---

`;
};

// Count agents run
let agentsRun = 0;
if (structure) agentsRun++;
if (adr) agentsRun++;
if (coherence) agentsRun++;

// Calculate agent scores for the pixel art display
const getAgentScore = (agent, agentType) => {
  if (!agent) return 0;
  if (agentType === 'structure') {
    return agent.status === 'PASS' ? 100 : (agent.status === 'NEEDS_REVIEW' ? 70 : 0);
  }
  if (agentType === 'adr') {
    if (agent.status === 'PASS') return 100;
    if (agent.status === 'NEEDS_REVIEW') return 70;
    if (agent.domain_changes_count > 0 && agent.adrs_in_pr === 0) return 0;
    return 50;
  }
  if (agentType === 'coherence') {
    return agent.overall_coherence_score || (agent.status === 'PASS' ? 100 : 0);
  }
  return 0;
};

const structureScore = getAgentScore(structure, 'structure');
const adrScore = getAgentScore(adr, 'adr');
const coherenceScore = getAgentScore(coherence, 'coherence');

// Helper: Generate wider progress bar for pixel art display (32 chars)
const wideProgressBar = (score, width = 32) => {
  const pct = Math.min(100, Math.max(0, score));
  const filled = Math.round((pct / 100) * width);
  const empty = width - filled;
  return '█'.repeat(filled) + '░'.repeat(empty);
};

// Helper: Status text for pixel art
const statusText = (status) => {
  switch (status?.toUpperCase()) {
    case 'PASS': return 'OK  ';
    case 'FAIL': return 'FAIL';
    case 'NEEDS_REVIEW': return 'WARN';
    default: return 'SKIP';
  }
};

// Helper: Pad to fixed width
const pad = (str, width) => {
  const s = String(str);
  return s.length >= width ? s : s + ' '.repeat(width - s.length);
};
const padLeft = (str, width) => {
  const s = String(str);
  return s.length >= width ? s : ' '.repeat(width - s.length) + s;
};

// Failure reason
const getFailureReason = () => {
  if (adr && adr.domain_changes_count > 0 && adr.adrs_in_pr === 0) {
    return 'Domain code modified without corresponding ADR';
  }
  if (adr?.status === 'FAIL' && adr.adrs_in_pr > 0) {
    return 'ADR does not match code changes';
  }
  if (coherence?.status === 'FAIL') {
    return 'Code-documentation coherence check failed';
  }
  return 'Governance compliance threshold not met';
};

// ASCII Art banners for PASS/FAIL
const PASSED_PIXEL_ART = `╔═══════════════════════════════════════════════════════════════════════════════╗
║                                                                               ║
║   ██████╗  █████╗ ███████╗███████╗███████╗██████╗     ██╗                    ║
║   ██╔══██╗██╔══██╗██╔════╝██╔════╝██╔════╝██╔══██╗    ██║                    ║
║   ██████╔╝███████║███████╗███████╗█████╗  ██║  ██║    ██║                    ║
║   ██╔═══╝ ██╔══██║╚════██║╚════██║██╔══╝  ██║  ██║    ╚═╝                    ║
║   ██║     ██║  ██║███████║███████║███████╗██████╔╝    ██╗                    ║
║   ╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝╚═════╝     ╚═╝                    ║
║                                                                               ║`;

const FAILED_PIXEL_ART = `╔═══════════════════════════════════════════════════════════════════════════════╗
║                                                                               ║
║   ███████╗ █████╗ ██╗██╗     ███████╗██████╗     ██╗                         ║
║   ██╔════╝██╔══██╗██║██║     ██╔════╝██╔══██╗    ██║                         ║
║   █████╗  ███████║██║██║     █████╗  ██║  ██║    ██║                         ║
║   ██╔══╝  ██╔══██║██║██║     ██╔══╝  ██║  ██║    ╚═╝                         ║
║   ██║     ██║  ██║██║███████╗███████╗██████╔╝    ██╗                         ║
║   ╚═╝     ╚═╝  ╚═╝╚═╝╚══════╝╚══════╝╚═════╝     ╚═╝                         ║
║                                                                               ║`;

// Build the result pixel art banner
const buildResultBanner = () => {
  const pixelArt = passed ? PASSED_PIXEL_ART : FAILED_PIXEL_ART;
  const statusLine = passed ? 'GOVERNANCE COMPLIANCE ACHIEVED' : 'GOVERNANCE COMPLIANCE FAILED';
  const complianceText = passed ? 'COMPLIANT' : 'NON-COMPLIANT';
  const scoreDisplay = `Score: ${padLeft(overallScore, 3)}/100  │  Threshold: ${threshold}/100  │  Status: ${complianceText}`;

  const agent1 = `Agent 1: Structure      ${wideProgressBar(structureScore)} ${padLeft(structureScore, 3)}%  ${statusText(structure?.status)}`;
  const agent2 = `Agent 2: ADR Review     ${wideProgressBar(adrScore)} ${padLeft(adrScore, 3)}%  ${statusText(adr?.status)}`;
  const agent3 = `Agent 3: Coherence      ${wideProgressBar(coherenceScore)} ${padLeft(coherenceScore, 3)}%  ${statusText(coherence?.status)}`;

  let banner = pixelArt + `
║   ┌─────────────────────────────────────────────────────────────────────┐    ║
║   │  ${pad(statusLine, 67)}│    ║
║   │  ───────────────────────────────────────────────────────────────── │    ║
║   │  ${pad(scoreDisplay, 67)}│    ║
║   └─────────────────────────────────────────────────────────────────────┘    ║
║                                                                               ║
║   ${pad(agent1, 73)}║
║   ${pad(agent2, 73)}║
║   ${pad(agent3, 73)}║
║                                                                               ║`;

  if (!passed) {
    const reason = getFailureReason();
    banner += `
║   Reason: ${pad(reason, 64)}║`;
  } else {
    banner += `
║   Powered by Claude AI + Clean Architecture + Spec-Kit                       ║`;
  }

  banner += `
╚═══════════════════════════════════════════════════════════════════════════════╝`;

  return banner;
};

// Generate markdown
const fallbackBanner = generateFallbackBanner();
const speckitContextSection = generateSpeckitContextSection();
const resultBanner = buildResultBanner();

const md = `${fallbackBanner}
\`\`\`
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   ███████╗██████╗ ███████╗ ██████╗    ██╗  ██╗██╗████████╗    ║
║   ██╔════╝██╔══██╗██╔════╝██╔════╝    ██║ ██╔╝██║╚══██╔══╝    ║
║   ███████╗██████╔╝█████╗  ██║         █████╔╝ ██║   ██║       ║
║   ╚════██║██╔═══╝ ██╔══╝  ██║         ██╔═██╗ ██║   ██║       ║
║   ███████║██║     ███████╗╚██████╗    ██║  ██╗██║   ██║       ║
║   ╚══════╝╚═╝     ╚══════╝ ╚═════╝    ╚═╝  ╚═╝╚═╝   ╚═╝       ║
║                                                               ║
║               Governance Compliance Pipeline                  ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
\`\`\`

\`\`\`
${resultBanner}
\`\`\`

## 🛡️ Spec-kit Governance Compliance Report

---

### 📊 Score Overview

| Metric | Value | Status |
|--------|-------|--------|
| **Overall Score** | ${overallScore}/100 | ${statusIcon(overallStatus)} |
| **Threshold** | ${threshold}/100 | - |
| **Agents Run** | ${agentsRun}/3 | - |

---

${speckitContextSection}
### 🔍 Agent 1: Structure Validator ${structure ? statusIcon(structure.status) : '⏭️'}

${structure ? progressBar(structure.status === 'PASS' ? 100 : (structure.status === 'NEEDS_REVIEW' ? 70 : 0)) : '`░░░░░░░░░░░░░░░░░░░░` Skipped'}

<details>
<summary>View Details</summary>

${structure ? `
| Check | Status |
|-------|--------|
| \`src/domain/\` | ${checkIcon(structure.checks?.src_domain_exists)} |
| \`src/application/\` | ${checkIcon(structure.checks?.src_application_exists)} |
| \`src/infrastructure/\` | ${checkIcon(structure.checks?.src_infrastructure_exists)} |
| \`docs/adrs/\` | ${checkIcon(structure.checks?.docs_adrs_exists)} (${structure.adr_count || 0} found) |
| Forbidden imports | ${structure.checks?.forbidden_imports_count || 0} violations |

${structure.specs?.found ? `**Specs:** Found at \`${structure.specs.location}\`` : '**Specs:** Not found'}
` : '*Agent did not run*'}

</details>

---

### 📚 Agent 2: ADR Reviewer ${adr ? statusIcon(adr.status) : '⏭️'}

${adr ? progressBar(adr.status === 'PASS' ? 100 : (adr.status === 'NEEDS_REVIEW' ? 70 : 0)) : '`░░░░░░░░░░░░░░░░░░░░` Skipped'}

<details>
<summary>View Details</summary>

${adr ? `
| Metric | Value |
|--------|-------|
| Domain/App Changes | ${adr.domain_changes_count || 0} files |
| ADRs Found | ${adr.adrs_found || 0} |
| ADRs in PR | ${adr.adrs_in_pr || 0} |

${adrMarkdown ? `
---

**🤖 Analyse Claude :**

${adrMarkdown}

---
` : adr.status === 'FAIL' ? `
**⚠️ Issue Detected**

Domain or application files were modified without a corresponding ADR.

**Recommendation:** Create an ADR in \`docs/adrs/\` documenting the architectural decision.
` : ''}
` : '*Agent did not run*'}

</details>

---

### 🔗 Agent 3: Coherence Checker ${coherence ? statusIcon(coherence.status) : '⏭️'}

${coherence ? progressBar(coherence.overall_coherence_score || (coherence.status === 'PASS' ? 100 : 0)) : '`░░░░░░░░░░░░░░░░░░░░` Skipped'}

<details>
<summary>View Details</summary>

${coherence ? `
| Category | Score | Status |
|----------|-------|--------|
| Naming | ${coherence.scores?.naming ?? 25}/25 | ${statusIcon(coherence.scores?.naming >= 20 ? 'PASS' : 'FAIL')} |
| Architecture | ${coherence.scores?.architecture ?? 25}/25 | ${statusIcon(coherence.scores?.architecture >= 20 ? 'PASS' : 'FAIL')} |
| Domain Purity | ${coherence.scores?.domain_purity ?? 25}/25 | ${statusIcon(coherence.scores?.domain_purity >= 20 ? 'PASS' : 'FAIL')} |
| Business Rules | ${coherence.scores?.business_rules ?? 25}/25 | ${statusIcon(coherence.scores?.business_rules >= 20 ? 'PASS' : 'FAIL')} |

**Violations Detected:**
- Naming violations: ${coherence.naming_violations || 0}
- Forbidden imports: ${coherence.forbidden_imports || 0}
- Side effects in domain: ${coherence.side_effects || 0}

${coherenceMarkdown ? `
---

**🤖 Analyse Claude :**

${coherenceMarkdown}

---
` : ''}
` : '*Agent did not run*'}

</details>

---

${!passed ? `
### 🔧 Actions Required

- [ ] Review the failed agent reports above
- [ ] Fix the reported issues
- [ ] Push changes to re-run governance checks

${adr?.status === 'FAIL' && adr?.domain_changes_count > 0 && adr?.adrs_in_pr === 0 ? `
---

## 📚 Agent 2: ADR Review — ❌ DOCUMENTATION MANQUANTE

\`\`\`
╔══════════════════════════════════════════════════════════════════════╗
║  ❌  VIOLATION PRINCIPE III — RÈGLE D'OR                            ║
║  ──────────────────────────────────────────────────────────────────  ║
║  "Toute modification de logique métier dans src/application ou      ║
║   src/domain DOIT être accompagnée d'un nouveau .md dans docs/adrs" ║
╚══════════════════════════════════════════════════════════════════════╝
\`\`\`

- **Fichiers domain modifiés** : ${adr.domain_changes_count}
- **ADRs dans cette PR** : ${adr.adrs_in_pr}

${adrMarkdown ? `
### 🤖 Ce que Claude en dit

${adrMarkdown}
` : `
### Action requise

Créez \`docs/adrs/NNNN-titre.md\` avec ce template :

\`\`\`markdown
# ADR NNNN : [Titre de la décision]

**Statut** : Proposé
**Date** : ${new Date().toISOString().split('T')[0]}

## Contexte
[Pourquoi cette modification ?]

## Décision
[Qu'avez-vous implémenté ?]

## Conséquences
[Impact sur le système]
\`\`\`
`}
` : ''}

**Resources:**
- 📖 [Constitution](.specify/memory/constitution.md)
- 📜 [Governance Rules](.spec-kit/governance.md)
- 📚 [ADR Examples](docs/adrs/)

` : `
### ✨ All Governance Checks Passed!

Your PR complies with all governance rules. Great job!

`}

---

<sub>🤖 Analyzed by [Spec-kit](https://github.com/github/spec-kit) + Claude AI (Haiku 4.5)</sub>
<sub>📖 Governance: \`.specify/memory/constitution.md\` | 🔗 [View workflow run](${process.env.GITHUB_SERVER_URL || 'https://github.com'}/${process.env.GITHUB_REPOSITORY || 'owner/repo'}/actions/runs/${process.env.GITHUB_RUN_ID || '0'})</sub>
`.trim();

// Write output
fs.writeFileSync(outputPath, md);
console.log(`✅ PR comment generated: ${outputPath}`);
console.log(`   Status: ${overallStatus}`);
console.log(`   Score: ${overallScore}/${threshold}`);
console.log(`   Agents: ${agentsRun}/3`);


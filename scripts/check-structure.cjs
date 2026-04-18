#!/usr/bin/env node
/* eslint-env node */
/**
 * Governance Compliance Checker
 * Validates rules defined in .spec-kit/governance.md
 *
 * Rules validated:
 * - Rule 1: Clean Architecture Structure (directories + files)
 * - Rule 2: Dependency Direction (forbidden imports)
 * - Rule 3: ADR Requirement (at least one ADR)
 */

const fs = require('fs');
const path = require('path');

// ============================================
// Configuration (mirrors .spec-kit/governance.md)
// ============================================

const RULES = {
  requiredDirectories: [
    { path: 'src/domain', description: 'Couche Domain (logique métier pure)' },
    { path: 'src/application', description: "Couche Application (cas d'usage)" },
    { path: 'src/infrastructure', description: 'Couche Infrastructure (adaptateurs)' },
    { path: 'docs/adrs', description: 'Architecture Decision Records' },
  ],

  requiredFiles: [
    { path: 'src/domain/talk.entity.ts', description: 'Entité métier Talk' },
    { path: 'src/domain/talk.repository.ts', description: 'Interface du repository Talk' },
    { path: 'src/application/submit-talk.usecase.ts', description: "Cas d'usage soumission" },
    { path: 'src/application/list-talks.usecase.ts', description: "Cas d'usage listage" },
    {
      path: 'src/infrastructure/in-memory-talk.repository.ts',
      description: 'Repository en mémoire',
    },
    { path: 'src/infrastructure/cli.ts', description: "Point d'entrée CLI" },
  ],

  forbiddenImports: [
    {
      sourceLayer: 'domain',
      forbiddenPatterns: [/from\s+['"]\.\.\/application/, /from\s+['"]\.\.\/infrastructure/],
      message: 'Domain layer must have ZERO dependencies on Application or Infrastructure',
    },
    {
      sourceLayer: 'application',
      forbiddenPatterns: [/from\s+['"]\.\.\/infrastructure/],
      message: 'Application layer must not depend on Infrastructure',
    },
  ],
};

// ============================================
// Utility Functions
// ============================================

function existsDir(p) {
  try {
    return fs.statSync(p).isDirectory();
  } catch {
    return false;
  }
}

function existsFile(p) {
  try {
    return fs.statSync(p).isFile();
  } catch {
    return false;
  }
}

function getAllTsFiles(dir) {
  const files = [];
  if (!existsDir(dir)) return files;

  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      files.push(...getAllTsFiles(fullPath));
    } else if (entry.name.endsWith('.ts')) {
      files.push(fullPath);
    }
  }
  return files;
}

// ============================================
// Validation Functions
// ============================================

function checkDirectories() {
  console.log('\n📁 Rule 1a: Required Directories');
  let ok = true;

  for (const dir of RULES.requiredDirectories) {
    if (existsDir(dir.path)) {
      console.log(`   ✅ ${dir.path} - ${dir.description}`);
    } else {
      console.error(`   ❌ ${dir.path} MISSING - ${dir.description}`);
      ok = false;
    }
  }
  return ok;
}

function checkFiles() {
  console.log('\n📄 Rule 1b: Required Files');
  let ok = true;

  for (const file of RULES.requiredFiles) {
    if (existsFile(file.path)) {
      console.log(`   ✅ ${file.path}`);
    } else {
      console.error(`   ❌ ${file.path} MISSING - ${file.description}`);
      ok = false;
    }
  }
  return ok;
}

function checkImports() {
  console.log('\n🔀 Rule 2: Dependency Direction (imports)');
  let ok = true;

  for (const rule of RULES.forbiddenImports) {
    const layerDir = `src/${rule.sourceLayer}`;
    const files = getAllTsFiles(layerDir);

    for (const file of files) {
      const content = fs.readFileSync(file, 'utf-8');
      const lines = content.split('\n');

      for (let i = 0; i < lines.length; i++) {
        const line = lines[i];
        for (const pattern of rule.forbiddenPatterns) {
          if (pattern.test(line)) {
            console.error(`   ❌ VIOLATION in ${file}:${i + 1}`);
            console.error(`      ${line.trim()}`);
            console.error(`      → ${rule.message}`);
            ok = false;
          }
        }
      }
    }
  }

  if (ok) {
    console.log('   ✅ Domain has no forbidden imports');
    console.log('   ✅ Application has no forbidden imports');
  }
  return ok;
}

function checkADRs() {
  console.log('\n📚 Rule 3: ADR Requirement');

  if (!existsDir('docs/adrs')) {
    console.error('   ❌ docs/adrs/ directory missing');
    return false;
  }

  const adrFiles = fs.readdirSync('docs/adrs').filter((f) => f.endsWith('.md'));

  if (adrFiles.length === 0) {
    console.error('   ❌ No ADR found in docs/adrs/');
    console.error('      → At least one ADR is required to document architectural decisions');
    return false;
  }

  console.log(`   ✅ Found ${adrFiles.length} ADR(s):`);
  adrFiles.forEach((f) => console.log(`      - ${f}`));
  return true;
}

// ============================================
// Main Execution
// ============================================

console.log('═══════════════════════════════════════════════════════════════');
console.log('   🔍 GOVERNANCE COMPLIANCE CHECK');
console.log('   Based on: .spec-kit/governance.md');
console.log('═══════════════════════════════════════════════════════════════');

const results = {
  directories: checkDirectories(),
  files: checkFiles(),
  imports: checkImports(),
  adrs: checkADRs(),
};

console.log('\n═══════════════════════════════════════════════════════════════');

const allPassed = Object.values(results).every((r) => r);

if (allPassed) {
  console.log('   ✅ ALL GOVERNANCE RULES PASSED');
  console.log('═══════════════════════════════════════════════════════════════\n');
  process.exit(0);
} else {
  console.error('   ❌ GOVERNANCE VIOLATIONS DETECTED');
  console.error('═══════════════════════════════════════════════════════════════\n');
  process.exit(1);
}

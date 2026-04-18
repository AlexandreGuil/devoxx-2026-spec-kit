#!/usr/bin/env node
/* eslint-env node */
import { execSync } from 'child_process';

// ESM wrapper that delegates to the CommonJS script
try {
  execSync('node scripts/check-structure.cjs', { stdio: 'inherit' });
} catch (e) {
  process.exit(e.status || 1);
}

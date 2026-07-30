#!/usr/bin/env node
// DeepGrade: Test/build tracker (PostToolUse: Bash) — lane N
//
// Ledger row 11: the expanded test-runner detection is the SCRIPT's, kept and
// widened slightly where the .sh list had gaps that would misreport (see below).
// Writes session-isolated markers that dg-session-stop (row 9) and the git
// guard's opt-in build check (row 5) read.
//
// Informational: fails OPEN, never exits non-zero, emits nothing on the happy path.
// Uses the same quote-stripping skeleton as the git guard so that
// `git commit -m "ran npm test"` does not record a test run that never happened.
'use strict';
const fs = require('fs');
const os = require('os');
const path = require('path');

function quiet() { process.exit(0); }

let payload = null;
try { payload = JSON.parse(fs.readFileSync(0, 'utf8')); } catch { quiet(); }

const command = payload && payload.tool_input && typeof payload.tool_input.command === 'string'
  ? payload.tool_input.command
  : '';
if (!command.trim()) quiet();

// Same tokenizer as dg-git-guard.js. Duplicated deliberately: F06's reverse sweep
// requires every file in scripts/ to be referenced by the hook config, so a shared
// module would fail it.
function skeleton(cmd) {
  let out = '', i = 0;
  while (i < cmd.length) {
    const ch = cmd[i];
    if (ch === '\\') { i += 2; continue; }
    if (ch === "'") { const e = cmd.indexOf("'", i + 1); out += "''"; if (e === -1) return out; i = e + 1; continue; }
    if (ch === '"') { i++; while (i < cmd.length && cmd[i] !== '"') { i += cmd[i] === '\\' ? 2 : 1; } out += '""'; if (i >= cmd.length) return out; i++; continue; }
    out += ch; i++;
  }
  return out;
}
const skel = skeleton(command);

const TEST_PATTERNS = [
  /\b(npm|pnpm|yarn|bun)\s+(run\s+)?test\b/,
  /\bnpx\s+(jest|vitest|mocha|ava|playwright|cypress)\b/,
  /\b(jest|vitest|mocha|ava)\b/,
  /\b(pytest|tox|nose2|unittest)\b/,
  /\bpython\s+-m\s+(pytest|unittest)\b/,
  /\bdotnet\s+test\b/,
  /\b(nunit|xunit)\b/,
  /\bcargo\s+test\b/,
  /\bgo\s+test\b/,
  /\bbundle\s+exec\s+rspec\b/,
  /\brspec\b/,
  /\bphpunit\b/,
  /\bmvn\s+(test|verify)\b/,
  /\bgradle\s+test\b/,
  // This repo's own suite, which the .sh list did not recognize at all — so a
  // full `bash tests/run-all.sh` never recorded that tests had run, and row 9
  // would nag "no tests ran" immediately after a green suite.
  /\btests\/run-all\.sh\b/,
  /\bbash\s+tests\/layer\d/,
];

const BUILD_PATTERNS = [
  /\b(npm|pnpm|yarn|bun)\s+run\s+build\b/,
  /\bnpx\s+tsc\b/,
  /\btsc\b/,
  /\b(npm|pnpm|yarn)\s+run\s+typecheck\b/,
  /\bdotnet\s+build\b/,
  /\bmsbuild\b/,
  /\bcargo\s+(build|check)\b/,
  /\bgo\s+(build|vet)\b/,
  /\bmvn\s+(compile|package)\b/,
  /\bgradle\s+(build|assemble)\b/,
  /\bmake\b/,
];

const sessionId = (payload && typeof payload.session_id === 'string' && payload.session_id) || 'default';
const tmp = process.env.TMPDIR || process.env.TEMP || os.tmpdir();

function mark(kind) {
  try { fs.writeFileSync(path.join(tmp, `dg-${kind}-${sessionId}`), String(Math.floor(Date.now() / 1000))); }
  catch { /* fail open */ }
}

if (TEST_PATTERNS.some((re) => re.test(skel))) mark('test');
if (BUILD_PATTERNS.some((re) => re.test(skel))) mark('build');

quiet();

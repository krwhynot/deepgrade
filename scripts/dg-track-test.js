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

// Same word splitter as dg-git-guard.js. Duplicated deliberately: F06's reverse
// sweep requires every file in scripts/ to be referenced by the hook config, so a
// shared module would fail it.
//
// This replaced a span-deleting tokenizer that an adversarial probe showed could be
// bypassed by quoting (`git push "--force"`). Here the stakes are inverted — this
// is an informational tracker, so a false marker is the failure that matters, not a
// missed one. A word containing whitespace can only have come from quoting, so it
// is data and is dropped before matching; `npm "test"` still counts, and
// `git commit -m "ran npm test earlier"` correctly does not.
function words(cmd) {
  const out = [];
  let word = '', started = false, i = 0;
  const end = () => { if (started) { out.push(word); word = ''; started = false; } };
  while (i < cmd.length) {
    const c = cmd[i];
    if (c === '\\') { if (i + 1 < cmd.length) { word += cmd[i + 1]; started = true; i += 2; } else i++; continue; }
    if (c === "'") { i++; while (i < cmd.length && cmd[i] !== "'") { word += cmd[i]; i++; } started = true; i++; continue; }
    if (c === '"') {
      i++;
      while (i < cmd.length && cmd[i] !== '"') {
        if (cmd[i] === '\\' && i + 1 < cmd.length) { word += cmd[i + 1]; i += 2; } else { word += cmd[i]; i++; }
      }
      started = true; i++; continue;
    }
    if (/[\s;|&()]/.test(c)) { end(); i++; continue; }
    word += c; started = true; i++;
  }
  end();
  return out;
}
const skel = words(command).filter((w) => !/\s/.test(w)).join(' ');

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

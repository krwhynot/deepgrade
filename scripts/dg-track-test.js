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
function segments(cmd) {
  const segs = [[]];
  let word = '', started = false, i = 0;
  const end = () => { if (started) { segs[segs.length - 1].push(word); word = ''; started = false; } };
  const endSeg = () => { end(); if (segs[segs.length - 1].length) segs.push([]); };
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
    if (/[;|&()\n\r]/.test(c)) { endSeg(); i++; continue; }
    if (/\s/.test(c)) { end(); i++; continue; }
    word += c; started = true; i++;
  }
  end();
  return segs.filter((s) => s.length);
}
// Match PER SEGMENT and at a command position. The previous version joined every
// segment's words into one string, so a pattern could match across two unrelated
// commands (`echo npm && test -f dist/index.js` forged a test marker) — the very
// isolation the git guard was fixed to preserve. Bare-word patterns also fired on
// commands that merely NAMED a tool (`grep -rn tsc src/`, `cat make.log`), and a
// forged build marker satisfies the DG_STRICT_GIT build gate.
const READERS = new Set(['grep', 'egrep', 'rg', 'cat', 'less', 'more', 'head', 'tail', 'ls',
                         'find', 'echo', 'printf', 'wc', 'stat', 'file', 'test', 'diff', 'sed', 'awk']);
const WRAPPERS = new Set(['sudo', 'env', 'command', 'nohup', 'time', 'timeout', 'winpty', 'stdbuf']);

function commandLine(seg) {
  // Drop leading env assignments and wrappers, then reject the segment outright if the
  // program is a reader — nothing a reader does is a test or build run.
  let i = 0;
  while (i < seg.length) {
    const w = seg[i];
    if (/^[A-Za-z_][A-Za-z0-9_]*=/.test(w)) { i++; continue; }
    if (WRAPPERS.has(w)) { i++; continue; }
    break;
  }
  if (i >= seg.length) return '';
  const prog = seg[i].replace(/\\/g, '/').split('/').pop().replace(/\.(exe|cmd|bat)$/i, '');
  if (READERS.has(prog)) return '';
  // Words containing whitespace came from quoting and are data, not structure.
  return [prog].concat(seg.slice(i + 1).filter((w) => !/\s/.test(w))).join(' ');
}

const skel = segments(command).map(commandLine).filter(Boolean);

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


// A session id is interpolated into a filename, so it is validated before use.
// Unvalidated, `session_id: "../../../../../../x/y"` wrote this handler's JSON OVER a
// file outside TMPDIR (confirmed by probe). path.join consumes the first `..` against
// the `dg-<name>-..` component, which is why a shallow test looks safe.
function safeSessionId(v) {
  return (typeof v === 'string' && /^[A-Za-z0-9._-]{1,64}$/.test(v) && v !== '.' && v !== '..')
    ? v : 'default';
}

const sessionId = safeSessionId(payload && payload.session_id);
const tmp = process.env.TMPDIR || process.env.TEMP || os.tmpdir();

function mark(kind) {
  try { fs.writeFileSync(path.join(tmp, `dg-${kind}-${sessionId}`), String(Math.floor(Date.now() / 1000))); }
  catch { /* fail open */ }
}

if (skel.some((line) => TEST_PATTERNS.some((re) => re.test(line)))) mark('test');
if (skel.some((line) => BUILD_PATTERNS.some((re) => re.test(line)))) mark('build');

quiet();

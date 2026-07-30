#!/usr/bin/env node
// Runs tests/fixtures/hook-corpus.json against a hook implementation and reports
// per-row pass/fail. Usage:
//   node tests/run-hook-corpus.js <path-to-hook> [--json]
//
// The corpus is read from a file rather than passed on a command line because the
// live guard denies any Bash invocation whose text contains a trigger string —
// F24 blocks its own test harness. Keep it that way.
'use strict';
const { spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const hook = process.argv[2];
const asJson = process.argv.includes('--json');
if (!hook) {
  console.error('usage: node tests/run-hook-corpus.js <path-to-hook> [--json]');
  process.exit(64);
}

const corpusPath = path.join(__dirname, 'fixtures', 'hook-corpus.json');
const corpus = JSON.parse(fs.readFileSync(corpusPath, 'utf8'));
const isJs = hook.endsWith('.js');

let pass = 0;
const failures = [];

for (const c of corpus.cases) {
  const input = c.payload_raw !== undefined && c.payload_raw !== null
    ? c.payload_raw
    : JSON.stringify(c.payload);

  const argv = isJs ? [hook] : [hook];
  const cmd = isJs ? process.execPath : 'bash';
  const r = spawnSync(cmd, argv, { input, encoding: 'utf8' });
  const exit = r.status;
  const out = (r.stdout || '').trim();
  const err = (r.stderr || '').trim();

  const problems = [];
  if (exit !== c.want_exit) problems.push(`exit ${exit}, want ${c.want_exit}`);

  // F26: every exit-0 emission must be JSON, and stderr must stay empty on exit 0.
  if (exit === 0 && err) problems.push(`stderr on exit 0: ${err.slice(0, 60)}`);
  if (exit === 0 && out) {
    let parsed = null;
    try { parsed = JSON.parse(out); } catch { problems.push('exit-0 stdout is not JSON'); }
    if (parsed && c.want_decision) {
      const got = parsed.hookSpecificOutput && parsed.hookSpecificOutput.permissionDecision;
      if (got !== c.want_decision) problems.push(`permissionDecision '${got}', want '${c.want_decision}'`);
    }
    // An ALLOW row must be SILENT. `want_decision: null` used to mean "do not
    // check", which made every allow row unable to detect a spurious prompt —
    // mutation M3 removed per-segment isolation, producing an unwanted `ask`, and
    // no row went red. "Allow" and "quietly ask the user" are different outcomes
    // and the corpus has to tell them apart.
    if (parsed && !c.want_decision) {
      const got = parsed.hookSpecificOutput && parsed.hookSpecificOutput.permissionDecision;
      problems.push(`expected a silent allow but got permissionDecision '${got}'`);
    }
  } else if (exit === 0 && c.want_decision) {
    problems.push(`want permissionDecision '${c.want_decision}' but nothing was emitted`);
  }

  if (problems.length === 0) pass++;
  else failures.push({ id: c.id, problems, why: c.why });
}

if (asJson) {
  console.log(JSON.stringify({ total: corpus.cases.length, pass, failures }, null, 2));
} else {
  for (const f of failures) {
    console.log(`[FAIL] ${f.id}: ${f.problems.join('; ')}`);
    console.log(`       ${f.why}`);
  }
  console.log(`\n${pass}/${corpus.cases.length} corpus rows pass against ${hook}`);
}
process.exit(failures.length ? 1 : 0);

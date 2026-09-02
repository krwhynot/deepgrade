#!/usr/bin/env node
// PHV5-040 acceptance: one falsifying test per behaviour-ledger row (approach.md
// §3.1.4), plus the F26 output-shape rule across every informational handler.
//
// Only the plan-context handlers remain. Rows 1-3, 5-9 and 11 exercised the
// git guard, migration guard, change/test trackers and the Stop summary, all of
// which shipped in deepgrade-guard and were RETIRED with it in 9.0.0. The rows
// that survive (4, 10, F26) are the ones whose subject is still in the tree.
//
// Runs in a scratch directory so plan fixtures never touch the real repo or the
// developer's temp state.
'use strict';
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');

const ROOT = path.resolve(__dirname, '..');

// Scratch dirs are swept at exit — before this existed every run leaked its
// dirs into the OS temp (3,000+ had accumulated). force+maxRetries because
// Windows can hold read-only handles briefly; a cleanup failure must never
// fail the run.
const scratchDirs = [];
function mkScratch(prefix) {
  const d = fs.mkdtempSync(path.join(os.tmpdir(), prefix));
  scratchDirs.push(d);
  return d;
}
process.on('exit', () => {
  for (const d of scratchDirs) {
    try { fs.rmSync(d, { recursive: true, force: true, maxRetries: 3 }); } catch { /* leave it */ }
  }
});

// Resolve each script where it ships, and THROW on a miss — a silently-skipped
// handler would read as a passing row, which is the vacuous-pass species.
const S = (n) => {
  const c = path.join(ROOT, 'plugins', 'deepgrade', 'scripts', n);
  if (fs.existsSync(c)) return c;
  throw new Error(`handler ${n} not found under plugins/deepgrade/scripts/ — the ledger row has no subject`);
};

let pass = 0;
const fails = [];
function check(name, ok, detail) {
  if (ok) { pass++; console.log(`[PASS] ${name}`); }
  else { fails.push(name); console.log(`[FAIL] ${name}${detail ? ' — ' + detail : ''}`); }
}

// Each run gets its own TMPDIR so nothing can leak between rows.
function run(script, payload, opts = {}) {
  const tmp = mkScratch('dg-row-');
  const env = { ...process.env, TMPDIR: tmp, TEMP: tmp, ...(opts.env || {}) };
  const r = spawnSync(process.execPath, [S(script)], {
    input: typeof payload === 'string' ? payload : JSON.stringify(payload),
    encoding: 'utf8', cwd: opts.cwd || ROOT, env,
  });
  return { exit: r.status, out: (r.stdout || '').trim(), err: (r.stderr || '').trim(), tmp, env };
}

// ---------------------------------------------------------------------------
console.log('--- Ledger row 10: SessionStart reads a pretty-printed status.json ---');

// Row 10: SessionStart must report the phase from a PRETTY-PRINTED status.json.
// dg-session-start.sh reported "phase: unknown" here because its grep pattern
// required no space after the colon.
const planRoot = mkScratch('dg-plan-');
const planDir = path.join(planRoot, 'docs', 'plans', '2026-01-01-demo');
fs.mkdirSync(planDir, { recursive: true });
fs.writeFileSync(path.join(planDir, 'status.json'), JSON.stringify({
  current_phase: 'build', phases: { brainstorm: { status: 'complete' }, build: { status: 'in_progress' } },
}, null, 2));
const r10 = run('dg-session-start.js', { source: 'startup' }, { cwd: planRoot });
let r10json = null; try { r10json = JSON.parse(r10.out); } catch {}
check('row 10: phase read from pretty-printed JSON (not "unknown")',
  !!r10json && /phase: build/.test(r10json.systemMessage), r10.out || '(no output)');
check('row 10: reports the PHASE\'s own status, not the first one in the file',
  !!r10json && /status: in_progress/.test(r10json.systemMessage) && !/status: complete/.test(r10json.systemMessage),
  r10json ? r10json.systemMessage : '(no output)');

// ---------------------------------------------------------------------------
console.log('\n--- F26: every exit-0 emission is JSON, and stderr stays empty ---');
const f26Cases = [
  ['dg-subagent-stop.js', { session_id: 's', reason: 'done' }],
  ['dg-pre-compact.js', { session_id: 's' }],
  ['dg-session-start.js', { source: 'startup' }],
];
// Each case must reach its EMITTING path, not an early exit, so every handler
// runs against the plan fixture above rather than an empty directory.
function runEmitting(script, payload) {
  const tmp = mkScratch('dg-f26-');
  const r = spawnSync(process.execPath, [S(script)], {
    input: JSON.stringify(payload), encoding: 'utf8', cwd: planRoot,
    env: { ...process.env, TMPDIR: tmp, TEMP: tmp },
  });
  return { exit: r.status, out: (r.stdout || '').trim(), err: (r.stderr || '').trim() };
}

let f26 = true;
for (const [script, payload] of f26Cases) {
  const r = runEmitting(script, payload);
  // Proving the case is not vacuous: every handler that has something to say
  // under this fixture must say it. Two exclusions, both because the handler is
  // covered more strictly elsewhere rather than because it may do nothing:
  //   dg-session-start.js  — row 10 asserts the phase and status it reports
  //   dg-subagent-stop.js  — its output channel is a LOG FILE, not stdout, so
  //                          emitting nothing here is correct. Its real effect is
  //                          asserted separately below (row 4 log append).
  const FILE_CHANNEL = script === 'dg-subagent-stop.js';
  if (script !== 'dg-session-start.js' && !FILE_CHANNEL && !r.out && !r.err) {
    f26 = false;
    console.log(`        ${script} produced NO output at all — this F26 case is vacuous (a no-op handler would pass it)`);
  }
  if (r.exit !== 0) { f26 = false; console.log(`        ${script} exited ${r.exit}, informational hooks must exit 0`); }
  if (r.err) { f26 = false; console.log(`        ${script} wrote to stderr at exit 0: ${r.err.slice(0, 60)}`); }
  if (r.out) { try { JSON.parse(r.out); } catch { f26 = false; console.log(`        ${script} exit-0 stdout is not JSON: ${r.out.slice(0, 60)}`); } }
}
check('F26: all informational handlers exit 0, JSON-only, no stderr', f26);

// Ledger row 4: dg-subagent-stop.js writes to a log rather than to stdout, so the
// F26 loop above cannot detect a no-op version of it. Assert the actual effect.
// Without this, replacing the file with `process.exit(0)` left the whole suite green.
(() => {
  const root = mkScratch('dg-sub-');
  const dir = path.join(root, 'docs', 'plans', '2026-01-01-demo', 'troubleshooting');
  fs.mkdirSync(dir, { recursive: true });
  const log = path.join(dir, 'subagent-log.txt');
  const r = run('dg-subagent-stop.js', { session_id: 's', reason: 'unit-probe' }, { cwd: root });
  const wrote = fs.existsSync(log) ? fs.readFileSync(log, 'utf8') : '';
  check('row 4: dg-subagent-stop appends the stop reason to the plan log',
    r.exit === 0 && /unit-probe/.test(wrote), `exit ${r.exit}, log=${JSON.stringify(wrote.slice(0, 60))}`);

  // Negative: no troubleshooting/ directory means the plan has not opted in, and the
  // handler must NOT create one. A stop hook silently making directories in someone
  // else's repo is a surprise.
  const root2 = mkScratch('dg-sub2-');
  fs.mkdirSync(path.join(root2, 'docs', 'plans', '2026-01-01-demo'), { recursive: true });
  const r2 = run('dg-subagent-stop.js', { session_id: 's', reason: 'x' }, { cwd: root2 });
  check('row 4 negative: no troubleshooting/ dir means no log and no directory created',
    r2.exit === 0 && !fs.existsSync(path.join(root2, 'docs', 'plans', '2026-01-01-demo', 'troubleshooting')),
    `exit ${r2.exit}`);
})();

// Malformed input must never make an informational hook fail loudly.
let openFail = true;
for (const [script] of f26Cases) {
  const r = run(script, '{not json', { cwd: planRoot });
  if (r.exit !== 0) { openFail = false; console.log(`        ${script} exited ${r.exit} on a malformed payload`); }
}
check('informational hooks fail OPEN on a malformed payload', openFail);

console.log(`\n${pass} passed, ${fails.length} failed`);
process.exit(fails.length ? 1 : 0);

#!/usr/bin/env node
// PHV5-040 acceptance: one falsifying test per behaviour-ledger row (approach.md
// §3.1.4), plus the F26 output-shape rule across every informational handler.
//
// The ledger is BIDIRECTIONAL: rows 1-2 exist only in the inline implementation
// and rows 3, 5-11 only in scripts/. Migrating either direction naively deletes
// working guards. Each row below fails if its behaviour is absent.
//
// Runs in a scratch directory so tracker files and plan fixtures never touch the
// real repo or the developer's temp state.
'use strict';
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');

const ROOT = path.resolve(__dirname, '..');
const S = (n) => path.join(ROOT, 'scripts', n);

let pass = 0;
const fails = [];
function check(name, ok, detail) {
  if (ok) { pass++; console.log(`[PASS] ${name}`); }
  else { fails.push(name); console.log(`[FAIL] ${name}${detail ? ' — ' + detail : ''}`); }
}

// Each run gets its own TMPDIR so session markers cannot leak between rows.
function run(script, payload, opts = {}) {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'dg-row-'));
  const env = { ...process.env, TMPDIR: tmp, TEMP: tmp, ...(opts.env || {}) };
  const r = spawnSync(process.execPath, [S(script)], {
    input: typeof payload === 'string' ? payload : JSON.stringify(payload),
    encoding: 'utf8', cwd: opts.cwd || ROOT, env,
  });
  return { exit: r.status, out: (r.stdout || '').trim(), err: (r.stderr || '').trim(), tmp, env };
}

// ---------------------------------------------------------------------------
console.log('--- Ledger rows 1-2: behaviours that exist ONLY inline today ---');

// Row 1 is covered in depth by tests/fixtures/hook-corpus.json; asserted here too
// so the ledger has its own evidence and neither file is the sole record.
const r1 = run('dg-git-guard.js', { session_id: 's', tool_input: { command: 'supabase db push' } });
check('row 1: database deploy denied', r1.exit === 2 && /BLOCKED/.test(r1.err), `exit ${r1.exit}`);
const r1b = run('dg-git-guard.js', { session_id: 's', tool_input: { command: 'supabase db diff' } });
check('row 1: `db diff` (read-only) allowed', r1b.exit === 0, `exit ${r1b.exit}`);

// Row 2: Windows backslash normalization in the migration guard.
const scratch = fs.mkdtempSync(path.join(os.tmpdir(), 'dg-mig-'));
fs.mkdirSync(path.join(scratch, 'db', 'migrations'), { recursive: true });
const migFile = path.join(scratch, 'db', 'migrations', '20240101_init.sql');
fs.writeFileSync(migFile, 'select 1;\n');
const backslashPath = migFile.replace(/\//g, '\\');
const r2 = run('dg-migration-guard.js', { tool_input: { file_path: backslashPath } }, { cwd: scratch });
check('row 2: backslash path recognized as a migration', r2.exit === 2, `exit ${r2.exit}`);
const r2b = run('dg-migration-guard.js', { tool_input: { file_path: migFile } }, { cwd: scratch });
check('row 2: forward-slash path still recognized', r2b.exit === 2, `exit ${r2b.exit}`);

// ---------------------------------------------------------------------------
console.log('\n--- Ledger row 3: wider migration coverage (script side) ---');
// Each filename must isolate exactly ONE recognition rule. The first version of
// this test used `.sql` for every shape, so the `.sql` extension rule caught them
// all and the prefix rules were never exercised — mutation P2 deleted the Flyway
// V-prefix pattern and the row stayed green. These are real-world non-SQL
// migration filenames, one per rule.
const covered = [
  ['plain.sql', 'SQL extension'],
  ['0001_initial.py', 'Django/alembic 4-digit underscore prefix'],
  ['20240101120000_Init.cs', 'EF Core timestamp prefix'],
  ['V2__Add_index.java', 'Flyway V-prefix (Java migration, so .sql cannot mask it)'],
  ['AppDbContextModelSnapshot.cs', 'EF Core snapshot'],
];
let row3 = true;
for (const [name, rule] of covered) {
  const f = path.join(scratch, 'db', 'migrations', name);
  fs.writeFileSync(f, 'x\n');
  const r = run('dg-migration-guard.js', { tool_input: { file_path: f } }, { cwd: scratch });
  if (r.exit !== 2) { row3 = false; console.log(`        ${name} (${rule}) -> exit ${r.exit}, expected 2`); }
}
check(`row 3: all ${covered.length} migration filename shapes caught, each isolating one rule`, row3);
const newFile = path.join(scratch, 'db', 'migrations', '9999_brand_new.sql');
const r3neg = run('dg-migration-guard.js', { tool_input: { file_path: newFile } }, { cwd: scratch });
check('row 3 negative: a NEW migration is never blocked', r3neg.exit === 0, `exit ${r3neg.exit}`);

// The three positives above plus that negative are ALL satisfied by "deny iff the
// file exists", because every positive fixture is an existing file inside a
// migration directory and the negative is a path that was never created. Proven by
// mutation: deleting MIGRATION_DIRS and the whole IS_MIGRATION filename block left
// 25/25 passing. These two negatives are what force the directory and filename
// logic to exist — both files EXIST, so existsSync alone cannot discriminate them.
const existsOutsideDir = path.join(scratch, 'src', '20240101_init.sql');
fs.mkdirSync(path.dirname(existsOutsideDir), { recursive: true });
fs.writeFileSync(existsOutsideDir, 'select 1;\n');
const rOut = run('dg-migration-guard.js', { tool_input: { file_path: existsOutsideDir } }, { cwd: scratch });
check('row 3 negative: an EXISTING migration-shaped file outside a migration dir is allowed',
  rOut.exit === 0, `exit ${rOut.exit} — the directory check is doing no work`);

const existsWrongShape = path.join(scratch, 'db', 'migrations', 'README.md');
fs.writeFileSync(existsWrongShape, '# notes\n');
const rShape = run('dg-migration-guard.js', { tool_input: { file_path: existsWrongShape } }, { cwd: scratch });
check('row 3 negative: an EXISTING non-migration file inside a migration dir is allowed',
  rShape.exit === 0, `exit ${rShape.exit} — the filename-shape check is doing no work`);

// ---------------------------------------------------------------------------
console.log('\n--- Ledger rows 5-6: opt-in, DG_STRICT_GIT default OFF (F05c) ---');
// Row 5 only has something to say where a build command is DETECTABLE. The first
// version of this test ran in a bare scratch dir with no package.json, so the
// guard correctly found nothing to require and returned 0 — the test was wrong,
// not the code. Give it a project shape so the assertion means something.
const proj = fs.mkdtempSync(path.join(os.tmpdir(), 'dg-proj-'));
fs.writeFileSync(path.join(proj, 'package.json'), JSON.stringify({ scripts: { build: 'tsc' } }));

const r5off = run('dg-git-guard.js', { session_id: 's', tool_input: { command: 'git commit -m "x"' } }, { cwd: proj });
check('rows 5-6: inactive with DG_STRICT_GIT unset (default-off negative)',
  r5off.exit === 0 && !r5off.err, `exit ${r5off.exit} ${r5off.err}`);

const r5on = run('dg-git-guard.js', { session_id: 's', tool_input: { command: 'git commit -m "x"' } },
  { env: { DG_STRICT_GIT: '1' }, cwd: proj });
check('rows 5-6: active when DG_STRICT_GIT=1', r5on.exit === 2 && /npm run build/.test(r5on.err),
  `exit ${r5on.exit} ${r5on.err}`);

// A recorded build inside the 120-minute window satisfies it.
const buildTmp = fs.mkdtempSync(path.join(os.tmpdir(), 'dg-bld-'));
fs.writeFileSync(path.join(buildTmp, 'dg-build-s'), '1');
const r5marker = spawnSync(process.execPath, [S('dg-git-guard.js')], {
  input: JSON.stringify({ session_id: 's', tool_input: { command: 'git commit -m "x"' } }),
  encoding: 'utf8', cwd: proj,
  env: { ...process.env, TMPDIR: buildTmp, TEMP: buildTmp, DG_STRICT_GIT: '1' },
});
check('row 5: a fresh build marker satisfies the check', r5marker.status === 0, `exit ${r5marker.status}`);

// ---------------------------------------------------------------------------
console.log('\n--- Ledger rows 7-8: tracker threshold and tolerant key read ---');
function trackerRun(seed, threshold) {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'dg-trk-'));
  if (seed) fs.writeFileSync(path.join(tmp, 'dg-baseline-s'), seed);
  const r = spawnSync(process.execPath, [S('dg-track-change.js')], {
    input: JSON.stringify({ session_id: 's', tool_input: { file_path: 'a.ts' } }),
    encoding: 'utf8', cwd: ROOT,
    env: { ...process.env, TMPDIR: tmp, TEMP: tmp, DG_CHANGE_THRESHOLD: String(threshold) },
  });
  return { out: (r.stdout || '').trim(), exit: r.status, tmp };
}
const r7 = trackerRun('{"session_changes":14,"total_changes_since_audit":14}', 15);
check('row 7: nudge fires at the threshold', /files changed since the last audit/.test(r7.out), r7.out || '(no output)');
const r7b = trackerRun('{"session_changes":1,"total_changes_since_audit":1}', 15);
check('row 7 negative: silent below the threshold', r7b.out === '', r7b.out);

// Row 8 is the whole point: a reader that knows only ONE key name sees 0.
const r8old = trackerRun('{"total":14}', 15);
check('row 8: legacy `total` key read (inline generation)', /14 files|15 files/.test(r8old.out), r8old.out || '(no output)');
const r8new = trackerRun('{"total_changes_since_audit":14}', 15);
check('row 8: `total_changes_since_audit` key read (script generation)', /15 files/.test(r8new.out), r8new.out || '(no output)');
const r8write = trackerRun('', 999);
const written = fs.readFileSync(path.join(r8write.tmp, 'dg-baseline-s'), 'utf8');
check('row 8: writes BOTH key names', /total_changes_since_audit/.test(written) && /"total"/.test(written), written);

// ---------------------------------------------------------------------------
console.log('\n--- Ledger rows 9-11: Stop verification, SessionStart, runner detection ---');
function stopRun(seed, markTest) {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'dg-stop-'));
  fs.writeFileSync(path.join(tmp, 'dg-baseline-s'), seed);
  if (markTest) fs.writeFileSync(path.join(tmp, 'dg-test-s'), '1');
  const r = spawnSync(process.execPath, [S('dg-session-stop.js')], {
    input: JSON.stringify({ session_id: 's' }), encoding: 'utf8', cwd: ROOT,
    env: { ...process.env, TMPDIR: tmp, TEMP: tmp },
  });
  return { out: (r.stdout || '').trim(), err: (r.stderr || '').trim(), exit: r.status };
}
const r9 = stopRun('{"session_changes":3}', false);
check('row 9: warns when files changed and no tests ran', /no test run was detected/.test(r9.out), r9.out || '(no output)');
const r9b = stopRun('{"session_changes":3}', true);
check('row 9 negative: silent about tests once a test run is recorded',
  !/no test run/.test(r9b.out) && /Session summary/.test(r9b.out), r9b.out || '(no output)');

// Row 11: the runner list must recognize THIS repo's suite, which the .sh list
// did not — so a green `bash tests/run-all.sh` recorded nothing and row 9 nagged.
function trackTest(cmd) {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'dg-tt-'));
  spawnSync(process.execPath, [S('dg-track-test.js')], {
    input: JSON.stringify({ session_id: 's', tool_input: { command: cmd } }),
    encoding: 'utf8', cwd: ROOT, env: { ...process.env, TMPDIR: tmp, TEMP: tmp },
  });
  return { test: fs.existsSync(path.join(tmp, 'dg-test-s')), build: fs.existsSync(path.join(tmp, 'dg-build-s')) };
}
check('row 11: `bash tests/run-all.sh` recorded as a test run', trackTest('bash tests/run-all.sh').test);
check('row 11: `pytest -q` recorded', trackTest('pytest -q').test);
check('row 11: `cargo test` recorded', trackTest('cargo test').test);
check('row 11: `npm run build` recorded as a build, not a test',
  (() => { const m = trackTest('npm run build'); return m.build && !m.test; })());
check('row 11 negative: a quoted mention does not record a test run',
  !trackTest('git commit -m "ran npm test earlier"').test);

// Row 10: SessionStart must report the phase from a PRETTY-PRINTED status.json.
// dg-session-start.sh reports "phase: unknown" here because its grep pattern
// requires no space after the colon.
const planRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'dg-plan-'));
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
  ['dg-track-change.js', { session_id: 's', tool_input: { file_path: 'a.ts' } }],
  ['dg-session-stop.js', { session_id: 's' }],
  ['dg-subagent-stop.js', { session_id: 's', reason: 'done' }],
  ['dg-pre-compact.js', { session_id: 's' }],
  ['dg-session-start.js', { source: 'startup' }],
];
// Each case must reach its EMITTING path, not an early exit. `run()` hands every
// call a fresh empty TMPDIR, so dg-session-stop and dg-track-change previously
// found no tracker, returned silently, and the F26 assertion inspected nothing —
// mutation P8 made the stop hook write to stderr and this row stayed green.
// Seed a tracker so both actually emit.
function runEmitting(script, payload) {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'dg-f26-'));
  fs.writeFileSync(path.join(tmp, 'dg-baseline-s'), '{"session_changes":3,"total_changes_since_audit":99}');
  const r = spawnSync(process.execPath, [S(script)], {
    input: JSON.stringify(payload), encoding: 'utf8', cwd: planRoot,
    env: { ...process.env, TMPDIR: tmp, TEMP: tmp, DG_CHANGE_THRESHOLD: '1' },
  });
  return { exit: r.status, out: (r.stdout || '').trim(), err: (r.stderr || '').trim() };
}

let f26 = true;
for (const [script, payload] of f26Cases) {
  const r = runEmitting(script, payload);
  // Proving the case is not vacuous. This floor originally covered only two of the
  // five handlers, so `dg-subagent-stop.js` and `dg-pre-compact.js` could be
  // replaced with `process.exit(0)` and the whole suite stayed green — both
  // assertions naming them are satisfied by emitting nothing at all. Every handler
  // that has something to say under this fixture must now say it.
  //
  // Two exclusions, both because the handler is covered more strictly elsewhere
  // rather than because it is allowed to do nothing:
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
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'dg-sub-'));
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
  const root2 = fs.mkdtempSync(path.join(os.tmpdir(), 'dg-sub2-'));
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

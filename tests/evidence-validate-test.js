#!/usr/bin/env node
/**
 * Tests for scripts/tq-evidence-validate.js  (PH5-020, spec §5.3)
 *
 * Unlike a test that mirrors logic living in markdown,
 * this file requires the real module. There is no second copy of the rules to drift.
 *
 * Run with: node tests/evidence-validate-test.js
 */

const path = require('path');
const { validateRecord, validateDirectory, VALID_VERDICTS } = require('../plugins/toque/scripts/tq-evidence-validate.js');

const ROOT = __dirname;
const ARTIFACT = 'fixtures/evidence/spec-sample.md';

// Line 9 of the fixture, byte for byte.
const TRUE_QUOTE = 'Rollback: revert migration 0043 via `npm run db:down 0043`.';

// sha256 of the fixture's LF-normalized content. If this file is legitimately
// edited, recompute with:
//   node -e "const f=require('fs'),c=require('crypto');console.log(c.createHash('sha256').update(f.readFileSync('tests/fixtures/evidence/spec-sample.md','utf8').replace(/\r\n/g,'\n'),'utf8').digest('hex'))"
const FIXTURE_SHA = 'd86dda77cbba04fe400a4e88e801d6e9bc95c9cdd769200c8eb64dd6691cacc2';

let pass = 0;
let fail = 0;

function check(name, cond, detail) {
  if (cond) {
    console.log(`  ✓ ${name}`);
    pass++;
  } else {
    console.log(`  ✗ ${name}${detail ? ` — ${detail}` : ''}`);
    fail++;
  }
}

function record(overrides = {}) {
  return Object.assign({
    criterion_id: 'LINT-03',
    evidence: [{
      artifact: ARTIFACT,
      line_start: 9,
      line_end: 9,
      exact_quote: TRUE_QUOTE,
    }],
    reasoning: 'Phase 2 names a reversal command.',
    verdict: 'MET',
  }, overrides);
}

console.log('\n1. Quote fidelity');

// A paraphrase is the cheapest possible fabrication: it reads as a citation, points
// at a real file and a real line range, and is wrong. If the validator accepts it,
// every downstream guarantee about evidence is decorative.
{
  const r = record({
    evidence: [{
      artifact: ARTIFACT,
      line_start: 9,
      line_end: 9,
      exact_quote: 'Rollback: revert migration 43 using npm run db:down.',
    }],
  });
  const out = validateRecord(r, ROOT);
  check('paraphrased quote forces UNMET', out.verdict === 'UNMET', `got ${out.verdict}`);
  check('paraphrased quote is flagged EVIDENCE-INVALID',
    (out.flags || []).includes('EVIDENCE-INVALID'),
    `flags=${JSON.stringify(out.flags)}`);
}

// The control. Without it the suite cannot tell "rejects paraphrase" from "rejects
// everything", and a validator that fails every record would score 2/2 above.
{
  const out = validateRecord(record(), ROOT);
  check('byte-equal quote is accepted', out.verdict === 'MET', `got ${out.verdict}`);
  check('byte-equal quote raises no flags',
    (out.flags || []).length === 0,
    `flags=${JSON.stringify(out.flags)}`);
}

console.log('\n2. Unverifiable claims');

// The PHV5-044 shape, mechanised. A judge that asserts a criterion is satisfied and
// produces nothing to check has not verified it, and "PARTIAL, no artifact" is a
// judgement call only while something is willing to make the call. Here it is an
// outcome: no evidence, no MET.
{
  const out = validateRecord(record({ evidence: [] }), ROOT);
  check('MET with an empty evidence array forces UNMET', out.verdict === 'UNMET', `got ${out.verdict}`);
  check('bare MET is flagged EVIDENCE-MISSING',
    (out.flags || []).includes('EVIDENCE-MISSING'),
    `flags=${JSON.stringify(out.flags)}`);
}

{
  const r = record();
  delete r.evidence;
  const out = validateRecord(r, ROOT);
  check('MET with no evidence key at all forces UNMET', out.verdict === 'UNMET', `got ${out.verdict}`);
}

// UNMET needs no evidence — you cannot cite the absence of a thing. Demoting it
// would make the validator reject every honest negative finding, which is the
// direction that quietly destroys a gate: the judge learns UNMET is expensive.
{
  const out = validateRecord(record({ verdict: 'UNMET', evidence: [] }), ROOT);
  check('UNMET with no evidence is left alone', out.verdict === 'UNMET', `got ${out.verdict}`);
  check('UNMET with no evidence raises no flags',
    (out.flags || []).length === 0,
    `flags=${JSON.stringify(out.flags)}`);
}

console.log('\n3. Staleness');

// The quote can still match its lines while the surrounding document has moved on.
// Pinning the artifact hash binds the record to the version that was audited, so a
// spec edited after the audit cannot keep carrying that audit's verdicts.
{
  const out = validateRecord(record({
    evidence: [{
      artifact: ARTIFACT, line_start: 9, line_end: 9,
      exact_quote: TRUE_QUOTE, sha256: 'deadbeef'.repeat(8),
    }],
  }), ROOT);
  check('stale artifact hash forces UNMET', out.verdict === 'UNMET', `got ${out.verdict}`);
  check('stale hash is flagged EVIDENCE-STALE',
    (out.flags || []).includes('EVIDENCE-STALE'),
    `flags=${JSON.stringify(out.flags)}`);
}

{
  const out = validateRecord(record({
    evidence: [{
      artifact: ARTIFACT, line_start: 9, line_end: 9,
      exact_quote: TRUE_QUOTE, sha256: FIXTURE_SHA,
    }],
  }), ROOT);
  check('matching artifact hash is accepted', out.verdict === 'MET', `got ${out.verdict}`);
}

// Platform portability, and the reason the hash is not over raw bytes. This repo
// converts LF to CRLF on Windows checkout while storing LF blobs, so a raw-byte
// hash would validate on a dev machine and fail on Ubuntu CI — a validator that
// only fails in CI is worse than none, because it trains people to ignore it.
{
  const os = require('os');
  const fs = require('fs');
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'tq-evidence-'));
  process.on('exit', () => { try { fs.rmSync(tmp, { recursive: true, force: true, maxRetries: 3 }); } catch { /* leave it */ } });
  const crlfDir = path.join(tmp, 'fixtures', 'evidence');
  fs.mkdirSync(crlfDir, { recursive: true });
  const lf = fs.readFileSync(path.join(ROOT, ARTIFACT), 'utf8').replace(/\r\n/g, '\n');
  fs.writeFileSync(path.join(crlfDir, 'spec-sample.md'), lf.replace(/\n/g, '\r\n'), 'utf8');

  const out = validateRecord(record({
    evidence: [{
      artifact: ARTIFACT, line_start: 9, line_end: 9,
      exact_quote: TRUE_QUOTE, sha256: FIXTURE_SHA,
    }],
  }), tmp);
  check('same content with CRLF endings hashes and quotes identically',
    out.verdict === 'MET', `got ${out.verdict} flags=${JSON.stringify(out.flags)}`);
  fs.rmSync(tmp, { recursive: true, force: true });
}

console.log('\n4. Command retention on executable criteria');

// Some criteria are settled by running something, not by reading something: does the
// test file exist, does the dashboard config exist. For those, a quote is not
// evidence — the command and its exit code are. The executable set is fixed inside
// the validator on purpose. If the record declared its own check type, a judge could
// avoid the requirement by calling an executable criterion textual, which is exactly
// the opt-out this rule exists to remove.
{
  const out = validateRecord({
    criterion_id: 'LINT-15',
    evidence: [{ artifact: ARTIFACT, line_start: 9, line_end: 9, exact_quote: TRUE_QUOTE }],
    reasoning: 'The scenario matrix names a test file.',
    verdict: 'MET',
  }, ROOT);
  check('executable criterion without a command forces UNMET', out.verdict === 'UNMET', `got ${out.verdict}`);
  check('missing command is flagged EVIDENCE-UNEXECUTED',
    (out.flags || []).includes('EVIDENCE-UNEXECUTED'),
    `flags=${JSON.stringify(out.flags)}`);
}

// A retained command that failed is not support for a MET. Recording the command
// without checking its outcome would let "I ran something" stand in for "it passed".
{
  const out = validateRecord({
    criterion_id: 'LINT-15',
    evidence: [{
      artifact: ARTIFACT, line_start: 9, line_end: 9, exact_quote: TRUE_QUOTE,
      command: 'test -f tests/does-not-exist.js', exit_code: 1,
    }],
    reasoning: 'Ran the existence check.',
    verdict: 'MET',
  }, ROOT);
  check('executable criterion with a failing command forces UNMET', out.verdict === 'UNMET', `got ${out.verdict}`);
  check('failing command is flagged EVIDENCE-COMMAND-FAILED',
    (out.flags || []).includes('EVIDENCE-COMMAND-FAILED'),
    `flags=${JSON.stringify(out.flags)}`);
}

{
  const out = validateRecord({
    criterion_id: 'LINT-15',
    evidence: [{
      artifact: ARTIFACT, line_start: 9, line_end: 9, exact_quote: TRUE_QUOTE,
      command: 'test -f tests/evidence-validate-test.js', exit_code: 0,
    }],
    reasoning: 'Existence check passed.',
    verdict: 'MET',
  }, ROOT);
  check('executable criterion with a passing command is accepted', out.verdict === 'MET',
    `got ${out.verdict} flags=${JSON.stringify(out.flags)}`);
}

// The control that keeps the rule scoped. A textual criterion settled by reading the
// document must NOT be made to produce a command — there is nothing to run. Without
// this, the validator would demand shell commands as proof that a plan contains a
// paragraph, and every honest textual verdict would fail.
{
  const out = validateRecord(record(), ROOT);
  check('textual criterion needs no command', out.verdict === 'MET',
    `got ${out.verdict} flags=${JSON.stringify(out.flags)}`);
}

console.log('\n5. CLI contract');

// The Phase 5 flow calls this as a command and branches on its exit code, so the
// exit code is the interface. Each case below is one the gate must distinguish.
{
  const os = require('os');
  const fs = require('fs');
  const { execFileSync } = require('child_process');
  const CLI = path.join(__dirname, '..', 'plugins', 'toque', 'scripts', 'tq-evidence-validate.js');

  const run = (args) => {
    try {
      const stdout = execFileSync('node', [CLI].concat(args), { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] });
      return { code: 0, stdout };
    } catch (err) {
      return { code: err.status, stdout: String(err.stdout || '') + String(err.stderr || '') };
    }
  };

  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'tq-cli-'));
  process.on('exit', () => { try { fs.rmSync(tmp, { recursive: true, force: true, maxRetries: 3 }); } catch { /* leave it */ } });
  const evd = path.join(tmp, 'evidence');
  fs.mkdirSync(evd, { recursive: true });

  const good = {
    criterion_id: 'LINT-03',
    evidence: [{ artifact: ARTIFACT, line_start: 9, line_end: 9, exact_quote: TRUE_QUOTE, sha256: FIXTURE_SHA }],
    reasoning: 'Phase 2 names a reversal command.',
    verdict: 'MET',
  };
  fs.writeFileSync(path.join(evd, 'LINT-03.json'), JSON.stringify(good));

  let r = run([evd, ROOT]);
  check('all-valid evidence exits 0', r.code === 0, `code=${r.code}\n${r.stdout}`);

  // One fabricated citation must fail the whole directory. A gate that passed the
  // set because most of it was fine would let a single invented quote through.
  const bad = JSON.parse(JSON.stringify(good));
  bad.criterion_id = 'LINT-07';
  bad.evidence[0].exact_quote = 'Rollback: something approximately like this.';
  fs.writeFileSync(path.join(evd, 'LINT-07.json'), JSON.stringify(bad));

  r = run([evd, ROOT]);
  check('one invalid record exits 1', r.code === 1, `code=${r.code}\n${r.stdout}`);
  check('output names the failing criterion', /LINT-07/.test(r.stdout), r.stdout);
  check('output names the reason', /EVIDENCE-INVALID/.test(r.stdout), r.stdout);

  // A missing directory is the worst case, not the quiet case. Exiting 0 would
  // report "nothing wrong" for an audit that produced no evidence at all — the
  // precise shape of the PARTIAL-with-no-artifact failure this replaces.
  r = run([path.join(tmp, 'nope'), ROOT]);
  check('missing evidence directory exits 2, not 0', r.code === 2, `code=${r.code}`);

  const empty = path.join(tmp, 'empty');
  fs.mkdirSync(empty, { recursive: true });
  r = run([empty, ROOT]);
  check('empty evidence directory exits 2, not 0', r.code === 2, `code=${r.code}`);

  fs.rmSync(tmp, { recursive: true, force: true });
}

// ---------------------------------------------------------------------------
// The verdict vocabulary is closed.
//
// Every test above this point builds its own record, in the shape the validator
// expects, with a verdict the validator recognises. That is why the suite was
// green while the validator had never successfully read a record the auditor
// actually wrote. These tests cover the gap in both directions: unrecognised
// verdicts, and records shaped like the ones on disk.
// ---------------------------------------------------------------------------
{
  console.log('\nVerdict vocabulary:');

  for (const bogus of ['PASS', 'FAIL', 'PARTIAL', 'met', '', undefined, null, 0]) {
    const out = validateRecord(record({ verdict: bogus }), ROOT);
    check(
      `${JSON.stringify(bogus)} is refused, not exempted`,
      out.verdict === 'UNMET' && out.flags.includes('EVIDENCE-VERDICT-INVALID'),
      `got ${out.verdict} [${out.flags}]`,
    );
  }

  // The direction that matters: PASS must not inherit the "not MET, nothing to
  // check" exemption. A record claiming PASS with evidence that does not survive
  // re-checking used to print a tick.
  const lying = record({ verdict: 'PASS', evidence: [{ artifact: ARTIFACT, line_start: 9, line_end: 9, exact_quote: 'not what line 9 says' }] });
  check('PASS with false evidence does not pass', validateRecord(lying, ROOT).verdict === 'UNMET');

  for (const good of ['MET', 'UNMET', 'N_A']) {
    const out = validateRecord(record({ verdict: good, evidence: good === 'MET' ? undefined : [] }), ROOT);
    check(`${good} is accepted`, !out.flags.includes('EVIDENCE-VERDICT-INVALID'), `flags=${out.flags}`);
  }
}

// ---------------------------------------------------------------------------
// A malformed citation demotes one record; it does not abort the run.
// ---------------------------------------------------------------------------
{
  console.log('\nMalformed citations:');

  for (const [name, item] of [
    ['artifact undefined', { line_start: 1, line_end: 1, exact_quote: 'x' }],
    ['artifact null', { artifact: null, line_start: 1, line_end: 1 }],
    ['artifact empty string', { artifact: '', line_start: 1, line_end: 1 }],
    ['artifact not a string', { artifact: 42, line_start: 1, line_end: 1 }],
    ['item is null', null],
    ['item is a string', 'docs/x.md'],
  ]) {
    let out;
    try {
      out = validateRecord(record({ evidence: [item] }), ROOT);
    } catch (err) {
      check(`${name} does not throw`, false, `threw ${err.code || err.message}`);
      continue;
    }
    check(
      `${name} demotes rather than throwing`,
      out.verdict === 'UNMET' && out.flags.includes('EVIDENCE-ARTIFACT-MISSING'),
      `got ${out.verdict} [${out.flags}]`,
    );
  }

  // One bad item among good ones must not cost the good ones their evaluation.
  const mixed = record({
    evidence: [
      { artifact: ARTIFACT, line_start: 9, line_end: 9, exact_quote: TRUE_QUOTE },
      { line_start: 1, line_end: 1, exact_quote: 'x' },
    ],
  });
  const out = validateRecord(mixed, ROOT);
  check('a bad item flags only itself', out.flags.length === 1 && out.flags[0] === 'EVIDENCE-ARTIFACT-MISSING', `flags=${out.flags}`);
}

// ---------------------------------------------------------------------------
// The regression this file existed to catch and did not.
//
// The validator read `item.artifact`; the records on disk were written with
// `path`. Nothing pointed the validator at a real record, so the mismatch
// survived every run of this suite and surfaced only when the script was invoked
// by hand — where it did not report a demotion, it threw ERR_INVALID_ARG_TYPE and
// validated nothing at all.
//
// This test asserts the property that was actually violated: real records are
// readable by the real validator. It deliberately does NOT assert that they all
// come back MET. Several cite live files the plan then edited, and demanding a
// clean run would create pressure to rewrite quotes until they matched — turning
// the evidence corpus into a record of what makes the test pass.
// ---------------------------------------------------------------------------
{
  console.log('\nReal evidence corpus:');

  const fs = require('fs');
  const REPO = path.join(__dirname, '..');
  const corpora = fs.existsSync(path.join(REPO, 'docs/plans'))
    ? fs.readdirSync(path.join(REPO, 'docs/plans'))
        .map((d) => path.join(REPO, 'docs/plans', d, 'evidence'))
        .filter((d) => fs.existsSync(d))
    : [];

  check('at least one real evidence corpus exists to test against', corpora.length > 0);

  for (const dir of corpora) {
    const rel = path.relative(REPO, dir).replace(/\\/g, '/');
    const files = fs.readdirSync(dir).filter((f) => f.endsWith('.json'));

    // Field names, checked directly. The crash was a schema mismatch, so the
    // schema is what gets asserted — reaching it through the validator's output
    // would only tell us a record failed, not that it was shaped wrongly.
    const wrong = [];
    for (const f of files) {
      const rec = JSON.parse(fs.readFileSync(path.join(dir, f), 'utf8'));
      if (!VALID_VERDICTS.has(rec.verdict)) wrong.push(`${f}: verdict ${JSON.stringify(rec.verdict)}`);
      for (const e of rec.evidence || []) {
        for (const legacy of ['path', 'lines', 'quote']) {
          if (legacy in e) wrong.push(`${f}: evidence uses legacy field "${legacy}"`);
        }
        if (typeof e.artifact !== 'string') wrong.push(`${f}: evidence.artifact is not a string`);
      }
    }
    check(`${rel}: every record uses the documented schema`, wrong.length === 0, wrong.slice(0, 5).join('; '));

    let result;
    try {
      result = validateDirectory(dir, REPO);
    } catch (err) {
      check(`${rel}: validates without throwing`, false, `threw ${err.code || err.message}`);
      continue;
    }
    check(`${rel}: validates without throwing`, true);
    check(`${rel}: every record produced a verdict`, result.records.every((r) => VALID_VERDICTS.has(r.verdict)),
      result.records.filter((r) => !VALID_VERDICTS.has(r.verdict)).map((r) => r.file).join(', '));
    console.log(`    ${result.records.length} record(s) read, ${result.demoted} demoted on re-check`);
  }
}

console.log(`\n${'═'.repeat(40)}`);
console.log(`Results: ${pass} passed, ${fail} failed`);
console.log(`${'═'.repeat(40)}\n`);
process.exit(fail > 0 ? 1 : 0);

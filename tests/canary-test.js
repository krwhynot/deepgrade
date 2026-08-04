#!/usr/bin/env node
/**
 * Tests for scripts/dg-canary.js  (PH5-030..033, spec §5.4)
 *
 * The canary checks the AUDITOR, not the plan: inject a known defect, and an audit
 * that fails to report it is not a clean audit, it is a broken one.
 *
 * Run with: node tests/canary-test.js
 */

const fs = require('fs');
const path = require('path');
const canary = require('../plugins/deepgrade/scripts/dg-canary.js');

const FIXTURE = path.join(__dirname, 'fixtures', 'canary', 'spec-full.md');
const SPEC = fs.readFileSync(FIXTURE, 'utf8').replace(/\r\n/g, '\n');

let pass = 0;
let fail = 0;
function check(name, cond, detail) {
  if (cond) { console.log(`  ✓ ${name}`); pass++; }
  else { console.log(`  ✗ ${name}${detail ? ` — ${detail}` : ''}`); fail++; }
}

console.log('\n1. Injection actually mutates');

{
  const out = canary.inject(SPEC, 'rollback-strip');
  check('rollback-strip changes the text', out.text !== SPEC);
  check('rollback-strip names the criterion it violates', out.criterion === 'LINT-03', `got ${out.criterion}`);
  check('rollback-strip removes exactly one rollback line',
    (SPEC.match(/^Rollback:/gm) || []).length - (out.text.match(/^Rollback:/gm) || []).length === 1,
    `before=${(SPEC.match(/^Rollback:/gm) || []).length} after=${(out.text.match(/^Rollback:/gm) || []).length}`);
}

// The failure that matters most. A mutation that silently does not apply produces a
// canary nothing can find, and then every audit looks untrustworthy for a reason
// that has nothing to do with the audit. Worse, if a no-op were ever treated as
// "not applicable, skip", the canary would go permanently vacuous — present in the
// pipeline, incapable of failing, which is the exact species this repo keeps hitting.
{
  const barren = '# Plan\n\nNo phases here.\n';
  let threw = false;
  let msg = '';
  try { canary.inject(barren, 'rollback-strip'); }
  catch (err) { threw = true; msg = err.message; }
  check('injection into a spec with nothing to strip THROWS', threw, 'it returned quietly');
  check('the error names the class that could not apply', /rollback-strip/.test(msg), `msg=${msg}`);
}

console.log('\n2. Every class in the bank is live');

// Rotation is the only thing raising the cost of pre-empting the canary, and it is
// worth exactly as much as the number of classes that actually work. A class that
// silently stopped applying would shrink the bank without shrinking the advertised
// count — the bank would look like five and behave like four.
{
  const seen = {};
  let allApplied = true;
  for (const name of canary.CLASS_NAMES) {
    try {
      const out = canary.inject(SPEC, name);
      if (out.text === SPEC) { allApplied = false; }
      seen[name] = out.criterion;
    } catch (err) {
      allApplied = false;
      seen[name] = `THREW: ${err.message.slice(0, 40)}`;
    }
  }
  check('the bank holds 5 classes', canary.CLASS_NAMES.length === 5, `got ${canary.CLASS_NAMES.length}`);
  check('every class applies to the fixture', allApplied, JSON.stringify(seen, null, 1));

  const criteria = Object.values(seen);
  check('each class targets a distinct criterion',
    new Set(criteria).size === criteria.length, JSON.stringify(seen));
}

console.log('\n3. Detection');

// The whole point: an audit that did not report the planted defect did not audit.
{
  const c = canary.inject(SPEC, 'criteria-strip');
  check('audit that reports the canary criterion is trusted',
    canary.wasFound(c, ['LINT-10', 'LINT-04']) === true);
  check('audit that misses it is not trusted',
    canary.wasFound(c, ['LINT-04', 'LINT-07']) === false);

  // Zero findings is the case that matters. A perfectly clean audit of a document
  // containing a defect you planted is not a clean audit — it is a broken one, and
  // no amount of reading its output would tell you that.
  check('audit reporting zero gaps is not trusted',
    canary.wasFound(c, []) === false);
}

console.log('\n4. Strip and recheck');

// The audit ran against a mutated copy, so its canary finding is an artefact of the
// harness and must not reach the report. But stripping alone is unsafe: if the plan
// has a GENUINE gap on the same criterion the canary targets, removing "the LINT-03
// finding" removes the real one too. That is why the strip is paired with a recheck
// of that one criterion against the unmutated original — the strip removes the
// artefact, the recheck decides the truth.
{
  const c = canary.inject(SPEC, 'rollback-strip');
  const out = canary.stripFinding(c, ['LINT-03', 'LINT-07']);
  check('canary finding is removed from the report',
    !out.findings.includes('LINT-03'), JSON.stringify(out.findings));
  check('unrelated findings survive',
    out.findings.includes('LINT-07'), JSON.stringify(out.findings));
  check('the stripped criterion is queued for recheck',
    out.recheck === 'LINT-03', `got ${out.recheck}`);
  check('recheck is mandatory, not advisory',
    out.recheckRequired === true, `got ${out.recheckRequired}`);
}

// The dangerous case, stated as a test so it cannot regress into a silent pass.
{
  const c = canary.inject(SPEC, 'rollback-strip');
  const out = canary.stripFinding(c, ['LINT-03']);
  check('stripping the only finding still demands a recheck',
    out.findings.length === 0 && out.recheckRequired === true,
    JSON.stringify(out));
  check('resolve() keeps a gap the recheck confirms on the original',
    canary.resolve(out, { stillFails: true }).findings.includes('LINT-03'));
  check('resolve() drops it when the original is clean',
    !canary.resolve(out, { stillFails: false }).findings.includes('LINT-03'));
}

console.log('\n5. Two misses end the audit');

{
  check('found on the first round is trustworthy',
    canary.assess([true]).trustworthy === true);
  check('one miss asks for a re-run, not a failure',
    canary.assess([false]).retry === true && canary.assess([false]).fatal === false);
  check('one miss is not yet trustworthy',
    canary.assess([false]).trustworthy === false);
  check('found on the re-run is trustworthy',
    canary.assess([false, true]).trustworthy === true);
  check('two consecutive misses are fatal',
    canary.assess([false, false]).fatal === true);

  // A revision loop driven by an audit that cannot see a planted defect is worse
  // than no loop: it rewrites the plan to satisfy findings that were never derived.
  check('a fatal canary forbids the revision loop',
    canary.assess([false, false]).allowRevision === false);
  check('a trustworthy audit permits the revision loop',
    canary.assess([true]).allowRevision === true);
}

console.log('\n6. CLI contract');

{
  const os = require('os');
  const { execFileSync } = require('child_process');
  const CLI = path.join(__dirname, '..', 'plugins', 'deepgrade', 'scripts', 'dg-canary.js');
  const run = (args) => {
    try { return { code: 0, out: execFileSync('node', [CLI].concat(args), { encoding: 'utf8' }) }; }
    catch (e) { return { code: e.status, out: String(e.stdout || '') + String(e.stderr || '') }; }
  };

  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'dg-canary-'));
  process.on('exit', () => { try { fs.rmSync(tmp, { recursive: true, force: true, maxRetries: 3 }); } catch { /* leave it */ } });
  const specCopy = path.join(tmp, 'spec.md');
  fs.writeFileSync(specCopy, SPEC);
  const outDir = path.join(tmp, '.canary');

  const r = run(['inject', specCopy, outDir, 'seed-a']);
  check('inject exits 0 on a spec it can mark', r.code === 0, `code=${r.code} ${r.out}`);

  const rec = JSON.parse(fs.readFileSync(path.join(outDir, 'canary.json'), 'utf8'));
  check('the record names the class and criterion',
    !!rec.className && !!rec.criterion, JSON.stringify(rec));
  const mutated = fs.readFileSync(rec.mutated, 'utf8');
  check('the mutated copy differs from the original', mutated !== SPEC);
  check('the ORIGINAL spec is left untouched',
    fs.readFileSync(specCopy, 'utf8') === SPEC, 'injection modified the real spec');

  // Reproducibility. A failed audit that cannot be replayed is a failed audit nobody
  // can diagnose, which is why the class comes from a seed and not Math.random.
  const outDir2 = path.join(tmp, '.canary2');
  run(['inject', specCopy, outDir2, 'seed-a']);
  const rec2 = JSON.parse(fs.readFileSync(path.join(outDir2, 'canary.json'), 'utf8'));
  check('the same seed reproduces the same class', rec.className === rec2.className,
    `${rec.className} vs ${rec2.className}`);

  // A spec no class can mark must be fatal, not a quiet pass. Emitting nothing and
  // exiting 0 would mean the audit proceeds unchecked while the pipeline reports a
  // canary step that did nothing.
  const barren = path.join(tmp, 'barren.md');
  fs.writeFileSync(barren, '# Plan\n\nNothing here.\n');
  const rb = run(['inject', barren, path.join(tmp, '.canary3')]);
  check('a spec no class can mark exits 2, not 0', rb.code === 2, `code=${rb.code}`);
  check('and says so', /no canary class could be applied/.test(rb.out), rb.out);

  fs.rmSync(tmp, { recursive: true, force: true });
}

console.log(`\n${'═'.repeat(40)}`);
console.log(`Results: ${pass} passed, ${fail} failed`);
console.log(`${'═'.repeat(40)}\n`);
process.exit(fail > 0 ? 1 : 0);

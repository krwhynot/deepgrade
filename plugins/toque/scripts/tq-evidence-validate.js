#!/usr/bin/env node
/**
 * Evidence record validator — PH5-020, spec §5.3.
 *
 * The Phase 5 gate treats a criterion as MET only when the judge produced evidence
 * that survives mechanical re-checking. This module does the re-checking.
 *
 * The point is narrow and worth stating: it decides byte-equality between a quoted
 * string and the lines it claims to come from. It does not, and cannot, decide
 * whether the quoted text actually satisfies the criterion. That limit is the
 * design — equality is a question text comparison answers soundly, and confining
 * the judge to claims of that shape is what makes the gate a verifier rather than
 * a better-instructed grader.
 */

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

/**
 * Hash an artifact's LF-normalized content, never its raw bytes.
 *
 * This repository stores LF blobs and converts to CRLF on Windows checkout, so a
 * raw-byte hash would validate on a developer machine and fail on Ubuntu CI. A
 * validator that only fails in CI is worse than no validator: it produces failures
 * nobody can reproduce locally, and people learn to re-run it until it goes away.
 */
function hashContent(text) {
  return crypto.createHash('sha256')
    .update(String(text).replace(/\r\n/g, '\n'), 'utf8')
    .digest('hex');
}

/**
 * Criteria settled by running something rather than by reading something.
 *
 * Fixed here, deliberately, rather than declared by the record. If a record could
 * state its own check type, a judge could relabel an executable criterion as textual
 * and satisfy it with a quote — which is precisely the opt-out this rule removes.
 * The judge does not get a vote on which rules apply to it.
 *
 * Kept in sync with docs/planning-techniques/lint-registry.md by
 * tests/evidence-validate-test.js; see the registry for what each id means.
 */
const EXECUTABLE_CRITERIA = new Set(['LINT-15', 'LINT-16']);

function isExecutableCriterion(id) {
  return EXECUTABLE_CRITERIA.has(id) || /^INFRA-/.test(String(id || ''));
}

/**
 * Re-read the cited lines and compare them with the quote the judge supplied.
 * Returns null when they agree, or a flag string naming the disagreement.
 */
function checkQuote(item, rootDir) {
  const abs = path.resolve(rootDir, item.artifact);

  let raw;
  try {
    raw = fs.readFileSync(abs, 'utf8');
  } catch (err) {
    return 'EVIDENCE-ARTIFACT-MISSING';
  }

  // Staleness dominates every other check. If the artifact has moved on since the
  // record was written, the line numbers and the quote are being compared against a
  // document the auditor never saw, and agreement would be coincidence rather than
  // evidence.
  if (item.sha256 && hashContent(raw) !== String(item.sha256).toLowerCase()) {
    return 'EVIDENCE-STALE';
  }

  const start = Number(item.line_start);
  const end = Number(item.line_end);
  if (!Number.isInteger(start) || !Number.isInteger(end) || start < 1 || end < start) {
    return 'EVIDENCE-RANGE-INVALID';
  }

  // Split on \n after stripping \r, so a CRLF checkout on Windows and an LF
  // checkout on CI slice identically. Line numbers are 1-based.
  const lines = raw.replace(/\r\n/g, '\n').split('\n');
  if (end > lines.length) {
    return 'EVIDENCE-RANGE-INVALID';
  }

  const actual = lines.slice(start - 1, end).join('\n');
  const quoted = String(item.exact_quote == null ? '' : item.exact_quote)
    .replace(/\r\n/g, '\n');

  return actual === quoted ? null : 'EVIDENCE-INVALID';
}

/**
 * Validate one criterion record.
 *
 * Returns { criterion_id, verdict, flags }. The verdict returned is the verdict
 * the gate must use: a MET whose evidence does not survive re-checking comes back
 * UNMET. Nothing here can raise a verdict — validation only ever demotes.
 */
function validateRecord(rec, rootDir) {
  const flags = [];
  const claimed = rec && rec.verdict;

  if (claimed !== 'MET') {
    return { criterion_id: rec && rec.criterion_id, verdict: claimed, flags };
  }

  const evidence = Array.isArray(rec.evidence) ? rec.evidence : [];

  // An externally checkable claim with nothing to check is not a weak pass, a
  // warning, or a PARTIAL — it is UNMET. This is the rule that converts a judgement
  // call into an outcome, and it is the one this repository has already lost twice:
  // PHV5-044 sat at PARTIAL with its result asserted in a commit message and no
  // artifact in any commit, and Wave 5 closed nine findings against greps typed at
  // a terminal. Both would fail here without anyone having to notice.
  if (evidence.length === 0) {
    flags.push('EVIDENCE-MISSING');
  }

  for (const item of evidence) {
    const flag = checkQuote(item, rootDir);
    if (flag && !flags.includes(flag)) flags.push(flag);
  }

  // For an executable criterion a quote is not evidence. "The scenario matrix says
  // there is a test" and "the test file exists" are different claims, and only the
  // second settles the rule — the first is the plan restating its own assertion.
  if (isExecutableCriterion(rec.criterion_id)) {
    const ran = evidence.filter((e) => e && e.command != null);
    if (ran.length === 0) {
      flags.push('EVIDENCE-UNEXECUTED');
    } else if (ran.some((e) => Number(e.exit_code) !== 0)) {
      // A retained command that failed is not support for a MET. Without this,
      // "I ran something" would stand in for "it passed".
      flags.push('EVIDENCE-COMMAND-FAILED');
    }
  }

  const verdict = flags.length > 0 ? 'UNMET' : 'MET';
  return { criterion_id: rec.criterion_id, verdict, flags };
}

/**
 * Validate every record in a directory.
 *
 * Returns { records, demoted } where demoted counts verdicts the auditor claimed as
 * MET that did not survive re-checking.
 */
function validateDirectory(dir, rootDir) {
  const entries = fs.readdirSync(dir)
    .filter((f) => f.endsWith('.json'))
    .sort();

  const records = entries.map((f) => {
    const full = path.join(dir, f);
    let rec;
    try {
      rec = JSON.parse(fs.readFileSync(full, 'utf8'));
    } catch (err) {
      // A record that will not parse is not a record. Treating it as absent would
      // let a malformed file silently remove a criterion from the audit.
      return { file: f, criterion_id: null, claimed: null, verdict: 'UNMET', flags: ['EVIDENCE-UNPARSEABLE'] };
    }
    const out = validateRecord(rec, rootDir);
    return { file: f, criterion_id: out.criterion_id, claimed: rec.verdict, verdict: out.verdict, flags: out.flags };
  });

  const demoted = records.filter((r) => r.claimed === 'MET' && r.verdict !== 'MET').length;
  return { records, demoted };
}

if (require.main === module) {
  const dir = process.argv[2];
  const rootDir = process.argv[3] || process.cwd();

  if (!dir) {
    console.error('usage: tq-evidence-validate.js <evidence-dir> [root-dir]');
    process.exit(2);
  }
  if (!fs.existsSync(dir)) {
    // An audit whose evidence directory does not exist has not produced evidence.
    // Exiting 0 here would report "nothing wrong" for the worst possible case.
    console.error(`evidence directory not found: ${dir}`);
    console.error('An audit with no evidence directory has not been completed.');
    process.exit(2);
  }

  const { records, demoted } = validateDirectory(dir, rootDir);

  for (const r of records) {
    const mark = r.flags.length ? '✗' : '✓';
    const why = r.flags.length ? `  [${r.flags.join(', ')}]` : '';
    console.log(`  ${mark} ${r.criterion_id || r.file}: ${r.verdict}${why}`);
  }
  console.log(`\n${records.length} record(s), ${demoted} demoted`);

  if (records.length === 0) {
    console.error('No records found — an empty evidence directory is not a pass.');
    process.exit(2);
  }
  process.exit(demoted > 0 ? 1 : 0);
}

module.exports = {
  validateRecord, checkQuote, hashContent, isExecutableCriterion, validateDirectory,
};

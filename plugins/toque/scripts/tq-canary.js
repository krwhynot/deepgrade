#!/usr/bin/env node
/**
 * Seeded canary — PH5-030..033, spec §5.4.
 *
 * Every other mechanism in the Phase 5 gate checks the PLAN. This one checks the
 * AUDITOR. A known defect is injected into a working copy before the audit runs; an
 * audit that does not report it has not audited anything, and its clean verdicts are
 * worth nothing regardless of how well evidenced they look.
 *
 * The honest claim, per spec §5.4: this reliably detects a LAZY audit and only
 * incidentally an adversarial one. The judge holds Read/Grep/Glob over the
 * repository and can therefore read this file, including the defect table below.
 * Rotating the class per run raises the cost of pre-empting it; it does not make
 * the canary tamper-proof, and it is not claimed to.
 */

/**
 * Each class removes or adds one thing, and names the criterion that thing exists to
 * satisfy. `apply` returns null when it has nothing to act on — never a silent no-op,
 * because a canary that cannot be found makes every audit look broken for a reason
 * unrelated to the audit.
 */
const CLASSES = {
  'rollback-strip': {
    criterion: 'LINT-03',
    describe: 'removed the rollback line from one deployment phase',
    apply(text) {
      const lines = text.split('\n');
      const i = lines.findIndex((l) => /^Rollback:/.test(l));
      if (i === -1) return null;
      lines.splice(i, 1);
      return lines.join('\n');
    },
  },

  'owner-strip': {
    criterion: 'LINT-04',
    describe: 'blanked the owner of one external dependency',
    apply(text) {
      const lines = text.split('\n');
      // A dependency row: | name | owner | status |
      const i = lines.findIndex((l) => /^\|[^|]+\|[^|]+\|[^|]+\|\s*$/.test(l)
        && !/^\|\s*-+/.test(l)
        && !/Dependency\s*\|/i.test(l)
        && /\|\s*[a-z][a-z ]+team\s*\|/i.test(l));
      if (i === -1) return null;
      lines[i] = lines[i].replace(/\|\s*[a-z][a-z ]+team\s*\|/i, '|  |');
      return lines.join('\n');
    },
  },

  'assumption-inject': {
    criterion: 'LINT-08',
    describe: 'added an unverified HIGH-impact assumption',
    apply(text) {
      const lines = text.split('\n');
      const i = lines.findIndex((l) => /^\|\s*1\s*\|/.test(l));
      if (i === -1) return null;
      lines.splice(i + 1, 0,
        '| 2 | Peak write throughput fits the current connection pool | Writes stall at launch | unverified |');
      return lines.join('\n');
    },
  },

  'criteria-strip': {
    criterion: 'LINT-10',
    describe: 'removed the go/no-go criteria from one phase',
    apply(text) {
      const lines = text.split('\n');
      const i = lines.findIndex((l) => /^Go\/No-Go:/.test(l));
      if (i === -1) return null;
      lines.splice(i, 1);
      return lines.join('\n');
    },
  },

  'test-claim-inject': {
    criterion: 'LINT-15',
    describe: 'claimed coverage from a test file that does not exist',
    apply(text) {
      const lines = text.split('\n');
      const i = lines.findIndex((l) => /tests?\/.*\.test\.js/.test(l));
      if (i === -1) return null;
      lines.splice(i + 1, 0,
        'Rollback behaviour is asserted in tests/integration/rollback-guarantees.test.js.');
      return lines.join('\n');
    },
  },
};

const CLASS_NAMES = Object.keys(CLASSES);

/**
 * Inject one defect. Throws when the class cannot apply — a silent no-op would
 * produce a canary that can never be found.
 */
function inject(text, className) {
  const spec = CLASSES[className];
  if (!spec) {
    throw new Error(`unknown canary class: ${className}`);
  }

  const normalized = String(text).replace(/\r\n/g, '\n');
  const mutated = spec.apply(normalized);

  if (mutated === null) {
    throw new Error(
      `canary class ${className} found nothing to act on in this spec. `
      + 'Refusing to emit a canary that cannot be found: an undetectable canary '
      + 'makes every audit look untrustworthy for a reason unrelated to the audit.'
    );
  }
  if (mutated === normalized) {
    throw new Error(
      `canary class ${className} produced no change. A no-op canary is vacuous.`
    );
  }

  return {
    text: mutated,
    className,
    criterion: spec.criterion,
    describe: spec.describe,
  };
}

/**
 * Did the audit report the planted defect?
 *
 * `unmetCriteria` is the set of criterion ids the audit returned as UNMET. Note what
 * this deliberately does NOT do: it does not look for a finding that "resembles" the
 * canary, or score how close the audit got. The planted defect violates exactly one
 * criterion; either that id came back UNMET or the audit did not see it.
 *
 * An audit reporting zero gaps therefore fails here, which is the point. A perfectly
 * clean result on a document known to contain a defect is not evidence of a good
 * plan — it is evidence of an audit that did not run.
 */
function wasFound(canaryRecord, unmetCriteria) {
  if (!canaryRecord || !canaryRecord.criterion) {
    throw new Error('wasFound requires a canary record produced by inject()');
  }
  const unmet = new Set((unmetCriteria || []).map((c) => String(c).trim()));
  return unmet.has(canaryRecord.criterion);
}

/**
 * Remove the canary's finding from the report and queue that criterion for recheck.
 *
 * The audit ran against a mutated copy, so its canary finding is an artefact of the
 * harness and must not reach the reader. Stripping alone would be unsafe: if the plan
 * has a GENUINE gap on the same criterion, removing "the LINT-03 finding" removes the
 * real one with it. The strip therefore only removes the artefact; `resolve` decides
 * the truth once that one criterion has been re-checked against the unmutated
 * original. `recheckRequired` is not advisory — a caller that ignores it has silently
 * deleted a real finding.
 */
function stripFinding(canaryRecord, findings) {
  const list = (findings || []).map((f) => String(f).trim());
  return {
    findings: list.filter((f) => f !== canaryRecord.criterion),
    recheck: canaryRecord.criterion,
    recheckRequired: true,
    className: canaryRecord.className,
  };
}

/**
 * Fold the recheck result back in. `stillFails` is the verdict for the stripped
 * criterion evaluated against the ORIGINAL, unmutated spec.
 */
function resolve(stripped, recheckResult) {
  if (!stripped.recheckRequired) {
    throw new Error('resolve() called on a report that was never stripped');
  }
  if (!recheckResult || typeof recheckResult.stillFails !== 'boolean') {
    throw new Error(
      'resolve() needs the recheck verdict for ' + stripped.recheck
      + ' against the unmutated original. Skipping it would either hide a real gap '
      + 'or report the canary as one.'
    );
  }
  const findings = stripped.findings.slice();
  if (recheckResult.stillFails && !findings.includes(stripped.recheck)) {
    findings.push(stripped.recheck);
  }
  return { findings, recheckRequired: false, recheck: stripped.recheck };
}

/**
 * Decide what the canary rounds mean for the gate.
 *
 * One miss buys a re-run with a different defect class — a single miss can be a
 * genuinely awkward injection site rather than a bad audit. Two consecutive misses
 * end it: the audit is untrustworthy and the gate fails.
 *
 * Critically, a fatal canary also FORBIDS the revision loop. Revising a plan against
 * findings from an audit that could not see a planted defect is worse than not
 * revising: it rewrites the spec to satisfy conclusions that were never derived from
 * reading it.
 */
function assess(rounds) {
  const r = Array.isArray(rounds) ? rounds : [];
  const found = r.some(Boolean);
  const misses = r.filter((x) => x === false).length;
  const fatal = !found && misses >= 2;

  return {
    trustworthy: found,
    retry: !found && misses === 1,
    fatal,
    allowRevision: found,
    reason: fatal
      ? 'audit untrustworthy: the planted defect was missed twice'
      : (found ? 'canary found' : 'canary missed, re-running with a different class'),
  };
}

/**
 * Choose a class deterministically from a seed, so a run can be reproduced from its
 * record while still rotating between runs. Math.random would make a failed audit
 * impossible to replay, and replaying a failure is the first thing anyone wants.
 */
function pickClass(seed) {
  const s = String(seed == null ? '' : seed);
  let h = 0;
  for (let i = 0; i < s.length; i++) {
    h = ((h << 5) - h + s.charCodeAt(i)) | 0;
  }
  return CLASS_NAMES[Math.abs(h) % CLASS_NAMES.length];
}

if (require.main === module) {
  const fs = require('fs');
  const path = require('path');

  const [cmd, specPath, outDir, seedArg] = process.argv.slice(2);

  if (cmd !== 'inject' || !specPath || !outDir) {
    console.error('usage: tq-canary.js inject <spec-path> <out-dir> [seed]');
    process.exit(2);
  }
  if (!fs.existsSync(specPath)) {
    console.error(`spec not found: ${specPath}`);
    process.exit(2);
  }

  const original = fs.readFileSync(specPath, 'utf8');
  const seed = seedArg || `${path.basename(specPath)}:${original.length}`;

  // Try classes in rotation from the seed. A spec may genuinely lack the site one
  // class needs; that is not a reason to emit an undetectable canary, so we move to
  // the next. Exhausting every class is fatal — a spec no class can mark is a spec
  // whose audit cannot be checked, and proceeding would mean trusting it blindly.
  const start = CLASS_NAMES.indexOf(pickClass(seed));
  let record = null;
  const tried = [];
  for (let k = 0; k < CLASS_NAMES.length; k++) {
    const name = CLASS_NAMES[(start + k) % CLASS_NAMES.length];
    tried.push(name);
    try {
      record = inject(original, name);
      break;
    } catch (err) {
      // fall through to the next class
    }
  }

  if (!record) {
    console.error(`no canary class could be applied to ${specPath}`);
    console.error(`tried: ${tried.join(', ')}`);
    console.error('A spec that cannot carry a canary is a spec whose audit cannot be');
    console.error('checked. Refusing to proceed unchecked.');
    process.exit(2);
  }

  fs.mkdirSync(outDir, { recursive: true });
  const mutatedPath = path.join(outDir, path.basename(specPath));
  fs.writeFileSync(mutatedPath, record.text, 'utf8');
  fs.writeFileSync(
    path.join(outDir, 'canary.json'),
    JSON.stringify({
      className: record.className,
      criterion: record.criterion,
      describe: record.describe,
      seed,
      spec: specPath,
      mutated: mutatedPath,
    }, null, 2) + '\n',
    'utf8'
  );

  console.log(`canary: ${record.className} -> ${record.criterion}`);
  console.log(`  ${record.describe}`);
  console.log(`  audit this copy: ${mutatedPath}`);
  process.exit(0);
}

module.exports = {
  inject, wasFound, stripFinding, resolve, assess, pickClass, CLASSES, CLASS_NAMES,
};

#!/usr/bin/env node
// Toque: SessionStart handler — lane N
//
// Ledger row 10 (expanded status reporting) and F26 (exit-0 output must be JSON).
// Also lane N's SINGLE dependency-check handler per 3.1.6: node present means this
// runs cleanly; node absent means it cannot spawn and the vendor's own hook-error
// notice is the signal (CR-1, U6 — verified user-visible in interactive sessions,
// suppressed under `claude -p`).
//
// TWO BUGS in tq-session-start.sh that a naive port would have carried, both from
// grepping JSON instead of parsing it:
//   1. the pattern `"current_phase":"` requires no space after the colon, so a
//      pretty-printed status.json yields "phase: unknown" — measured against this
//      repo's own plan, which has current_phase set.
//   2. `grep -o '"status":"..."' | head -1` returns the FIRST "status" anywhere in
//      the file — phases.brainstorm.status — and reports that nested value as the
//      plan's status.
// JSON.parse plus named lookups make both unrepresentable.
'use strict';
const fs = require('fs');
const path = require('path');

function emit(message, context) {
  const out = { systemMessage: message };
  if (context) {
    out.hookSpecificOutput = { hookEventName: 'SessionStart', additionalContext: context };
  }
  process.stdout.write(JSON.stringify(out) + '\n');
  process.exit(0);
}
function quiet() { process.exit(0); }

// Payload is read but not required — SessionStart carries a `source` field
// (startup | resume | compact) that the 3.1.6 fallback chain depends on.
let source = '';
try {
  const raw = fs.readFileSync(0, 'utf8');
  if (raw.trim()) {
    const p = JSON.parse(raw);
    if (p && typeof p.source === 'string') source = p.source;
  }
} catch { /* absent or unparseable payload must never break a status report */ }

let plansDir = 'docs/plans';
if (!fs.existsSync(plansDir) && fs.existsSync('plans')) plansDir = 'plans';
if (!fs.existsSync(plansDir)) quiet();

let latest = null;
try {
  latest = fs.readdirSync(plansDir, { withFileTypes: true })
    .filter((e) => e.isDirectory())
    .map((e) => ({ name: e.name, mtime: fs.statSync(path.join(plansDir, e.name)).mtimeMs }))
    .sort((a, b) => b.mtime - a.mtime)[0] || null;
} catch { quiet(); }
if (!latest) quiet();

const statusPath = path.join(plansDir, latest.name, 'status.json');
if (!fs.existsSync(statusPath)) quiet();

let status = null;
try { status = JSON.parse(fs.readFileSync(statusPath, 'utf8')); } catch { status = null; }
if (!status) {
  // A plan folder with an unreadable status.json is worth saying out loud rather
  // than reporting "unknown" as though the field were missing.
  emit(`[Toque] Active plan: ${latest.name} — status.json is present but not valid JSON.`);
}

const phase = typeof status.current_phase === 'string' ? status.current_phase : 'unknown';
// Named path, not a first-match scan: the phase's OWN status, never a sibling's.
const phaseStatus = status.phases && status.phases[phase] && typeof status.phases[phase].status === 'string'
  ? status.phases[phase].status
  : 'unknown';

const parts = [`Active plan: ${latest.name} (phase: ${phase}, status: ${phaseStatus})`];

const report = 'docs/audit/toque-report.md';
try {
  const ageDays = Math.floor((Date.now() - fs.statSync(report).mtimeMs) / 86400000);
  if (ageDays > 7) parts.push(`Audit report is ${ageDays} days old.`);
} catch { /* no audit report yet */ }

if (source === 'compact') {
  // 3.1.6 locked fallback: if PreCompact cannot surface a message (U5 negative),
  // the compact-resume line is delivered here instead.
  parts.push(`Resuming after compaction. Continue with /toque:plan ${latest.name}`);
}

emit(`[Toque] ${parts.join(' ')}`, `Active Toque plan: ${latest.name}, phase ${phase} (${phaseStatus}).`);

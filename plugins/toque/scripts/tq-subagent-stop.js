#!/usr/bin/env node
// Toque: SubagentStop handler — lane N
//
// Ledger row 4. WIRED and live: hooks/hooks.json registers this under
// SubagentStop, so it runs on every subagent completion.
//
// This header said the opposite for several releases — "wired to NOTHING",
// activation deferred to a later step. That step landed; the comment did not
// move. Left uncorrected it is the kind of note that sends the next reader
// looking for a bug in the wiring instead of in the handler.
//
// Informational: fails open, always exits 0.
'use strict';
const fs = require('fs');
const path = require('path');

function quiet() { process.exit(0); }

let payload = null;
try { payload = JSON.parse(fs.readFileSync(0, 'utf8')); } catch { payload = null; }
if (payload && payload.stop_hook_active === true) quiet();

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

// Only log into a plan that has opted in by having the folder. Never create it —
// a stop hook silently making directories in someone's repo is a surprise.
const dir = path.join(plansDir, latest.name, 'troubleshooting');
if (!fs.existsSync(dir)) quiet();

// The reason is written by whatever produced the payload, and it lands in a log
// a human later reads as a record of what happened. A newline in it forges a new
// entry — timestamp, prefix and all — so the log stops being a record and becomes
// a place to write whatever you like. Control characters are collapsed to spaces
// and the value is capped, because one line in means one line out.
const rawReason = payload && typeof payload.reason === 'string' && payload.reason
  ? payload.reason
  : 'completed';
const reason = rawReason
  .replace(/[\r\n\u0000-\u001f\u007f]+/g, ' ')
  .trim()
  .slice(0, 200) || 'completed';
try {
  fs.appendFileSync(path.join(dir, 'subagent-log.txt'),
    `[${new Date().toISOString()}] Subagent stopped: ${reason}\n`);
} catch { /* fail open */ }

quiet();

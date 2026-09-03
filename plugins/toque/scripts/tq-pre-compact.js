#!/usr/bin/env node
// Toque: PreCompact handler — lane N
//
// F26: exit-0 output must be JSON. tq-pre-compact.sh wrote a bare line to stdout,
// which is not the documented contract.
//
// U5 is OPEN: whether PreCompact can surface a message at all is unverified and is
// settled by 4c runtime observation, not here. 3.1.6 locks the fallback in advance —
// if it cannot, the compact-resume line moves to tq-session-start.js's
// `source === "compact"` path, which is already implemented. So this handler being
// invisible costs nothing; it is not the only carrier of the message.
//
// Informational: fails open, always exits 0.
'use strict';
const fs = require('fs');
const path = require('path');

function quiet() { process.exit(0); }

try { fs.readFileSync(0, 'utf8'); } catch { /* payload not needed */ }

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

let phase = 'unknown';
try {
  const s = JSON.parse(fs.readFileSync(statusPath, 'utf8'));
  if (s && typeof s.current_phase === 'string') phase = s.current_phase;
} catch { /* keep 'unknown' rather than failing */ }

process.stdout.write(JSON.stringify({
  systemMessage: `[Toque] Compacting. Active plan: ${latest.name} at phase: ${phase}. Resume with /toque:plan ${latest.name}`,
}) + '\n');
process.exit(0);

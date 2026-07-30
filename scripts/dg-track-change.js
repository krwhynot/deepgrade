#!/usr/bin/env node
// DeepGrade: Change tracker (PostToolUse: Write|Edit) — lane N
//
// Ledger row 7: audit-staleness nudge at DG_CHANGE_THRESHOLD (default 15).
// Ledger row 8: read the tracker TOLERANTLY across both key names. The inline
//   implementation wrote `total`, the script wrote `total_changes_since_audit`;
//   whichever single key a reader assumed, the other one silently read as 0 and
//   the nudge never fired. Writes both, reads either.
//
// Informational hook: fails OPEN in every state (3.1.6 — "a tracker that blocks
// work costs more than one that miscounts"). Never exits non-zero.
'use strict';
const fs = require('fs');
const os = require('os');
const path = require('path');

function quiet() { process.exit(0); }
function notify(message) {
  // F26: exit-0 output must be JSON. dg-track-change.sh wrote this to stderr and
  // exited 0, where it is never surfaced — the nudge has never been seen.
  process.stdout.write(JSON.stringify({ systemMessage: message }) + '\n');
  process.exit(0);
}

let payload = null;
try { payload = JSON.parse(fs.readFileSync(0, 'utf8')); } catch { quiet(); }

const filePath = payload && payload.tool_input && typeof payload.tool_input.file_path === 'string'
  ? payload.tool_input.file_path
  : '';
if (!filePath.trim()) quiet();

const sessionId = (payload && typeof payload.session_id === 'string' && payload.session_id) || 'default';
const tmp = process.env.TMPDIR || process.env.TEMP || os.tmpdir();
const tracker = path.join(tmp, `dg-baseline-${sessionId}`);
const threshold = Number(process.env.DG_CHANGE_THRESHOLD || 15);

// Row 8, read side.
function readCount(obj, text, keys) {
  if (obj) for (const k of keys) if (typeof obj[k] === 'number') return obj[k];
  const re = new RegExp(`"(?:${keys.join('|')})"\\s*:\\s*(\\d+)`);
  const m = text.match(re);
  return m ? Number(m[1]) : 0;
}

let text = '';
let obj = null;
try { text = fs.readFileSync(tracker, 'utf8'); } catch { text = ''; }
if (text) { try { obj = JSON.parse(text); } catch { obj = null; } }

const session = readCount(obj, text, ['session_changes']) + 1;
const total = readCount(obj, text, ['total_changes_since_audit', 'total']) + 1;

try {
  // Row 8, write side: both key names, so a reader of either generation agrees.
  fs.writeFileSync(tracker, JSON.stringify({
    session_changes: session,
    total_changes_since_audit: total,
    total,
  }));
} catch { quiet(); }  // fail open: a tracker that cannot be written must not block the edit

if (Number.isFinite(threshold) && threshold > 0 && total >= threshold) {
  notify(`[DeepGrade] ${total} files changed since the last audit. Consider /deepgrade:codebase-delta.`);
}
quiet();

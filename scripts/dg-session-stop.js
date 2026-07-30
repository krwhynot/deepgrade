#!/usr/bin/env node
// DeepGrade: Stop handler — lane N
//
// Ledger row 9: "N files changed but no tests ran". This exists only in the
// script, and it has NEVER BEEN SEEN by a user: dg-session-stop.sh:30 writes it to
// stderr and exits 0, which Claude Code does not surface (F26). Emitted as JSON now.
// Ledger row 8: tolerant tracker read across both key names.
//
// Informational: fails open, always exits 0. Never exit 2 from a Stop hook —
// approach.md notes that causes an infinite loop.
'use strict';
const fs = require('fs');
const os = require('os');
const path = require('path');

function quiet() { process.exit(0); }
function notify(message) {
  process.stdout.write(JSON.stringify({ systemMessage: message }) + '\n');
  process.exit(0);
}

let payload = null;
try { payload = JSON.parse(fs.readFileSync(0, 'utf8')); } catch { payload = null; }

const sessionId = (payload && typeof payload.session_id === 'string' && payload.session_id) || 'default';
const tmp = process.env.TMPDIR || process.env.TEMP || os.tmpdir();

let text = '', obj = null;
try { text = fs.readFileSync(path.join(tmp, `dg-baseline-${sessionId}`), 'utf8'); } catch { quiet(); }
if (!text) quiet();
try { obj = JSON.parse(text); } catch { obj = null; }

function count(keys) {
  if (obj) for (const k of keys) if (typeof obj[k] === 'number') return obj[k];
  const m = text.match(new RegExp(`"(?:${keys.join('|')})"\\s*:\\s*(\\d+)`));
  return m ? Number(m[1]) : 0;
}
const changes = count(['session_changes']);
if (changes <= 0) quiet();

const testMarker = path.join(tmp, `dg-test-${sessionId}`);
const testsRan = fs.existsSync(testMarker);

if (!testsRan) {
  // Only nag if the project actually has tests to run.
  let hasTests = false;
  try { hasTests = /"test"\s*:/.test(fs.readFileSync('package.json', 'utf8')); } catch {}
  if (!hasTests) {
    for (const marker of ['pytest.ini', 'conftest.py', 'tox.ini', 'Cargo.toml', 'go.mod', 'phpunit.xml']) {
      if (fs.existsSync(marker)) { hasTests = true; break; }
    }
  }
  // This repo's own suite lives in tests/run-all.sh with no package.json test
  // script, so the .sh check reported "no tests" for the very project it ships in.
  if (!hasTests && fs.existsSync(path.join('tests', 'run-all.sh'))) hasTests = true;

  if (hasTests) {
    notify(`[DeepGrade] ${changes} file${changes === 1 ? '' : 's'} changed this session but no test run was detected. Run the suite before finishing.`);
  }
}

notify(`[DeepGrade] Session summary: ${changes} file${changes === 1 ? '' : 's'} changed.`);

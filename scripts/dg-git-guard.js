#!/usr/bin/env node
// DeepGrade: Git / deploy guard (PreToolUse: Bash) — lane N
//
// Contract: approach.md 3.1.6. Enforce ONLY what is parsed.
//   - real parser present (this is node, so always): extract the NAMED field
//     tool_input.command, enforce, and fail CLOSED on a payload JSON.parse rejects
//   - never deny on the basis of an unparsed blob
//   - deny  -> exit 2 + "BLOCKED" on stderr (stderr IS surfaced on exit 2)
//   - ask   -> exit 0 + JSON permissionDecision "ask"   (F22)
//   - allow -> exit 0, silent
//   - never stderr on exit 0                             (F26)
//
// Acceptance is tests/fixtures/hook-corpus.json. That corpus is the falsifier:
// a matcher that fails any row fails PHV5-041 regardless of how it is written.
'use strict';

const DENY = 2, OK = 0;

function deny(msg) { process.stderr.write(`[DeepGrade] BLOCKED: ${msg}\n`); process.exit(DENY); }
function ask(msg) {
  process.stdout.write(JSON.stringify({
    hookSpecificOutput: { hookEventName: 'PreToolUse', permissionDecision: 'ask', permissionDecisionReason: msg },
  }) + '\n');
  process.exit(OK);
}
function allow() { process.exit(OK); }

// ---------------------------------------------------------------------------
// Tokenizer. THE central mechanism, and the reason a bare regex cannot pass.
//
// Quoted text inside a command is data, not an instruction: `git commit -m "do
// not git push --force"` must be ALLOWED. So the contents of every quoted span
// are removed before any pattern is applied, leaving a skeleton that preserves
// the command's structure. Discovered while writing the corpus: the live inline
// guard denies a read-only `grep 'supabase db push'`, and it denied this file's
// own test harness for containing the strings.
//
// Rules follow POSIX sh: single quotes are literal (no escapes inside), double
// quotes honour a backslash escape, and a backslash outside quotes escapes one
// character.
// ---------------------------------------------------------------------------
function skeleton(cmd) {
  let out = '';
  let i = 0;
  while (i < cmd.length) {
    const ch = cmd[i];
    if (ch === '\\') { i += 2; continue; }          // escaped char outside quotes: drop both
    if (ch === "'") {
      const end = cmd.indexOf("'", i + 1);
      out += "''";
      if (end === -1) return out;                    // unterminated: nothing further is enforceable
      i = end + 1;
      continue;
    }
    if (ch === '"') {
      i++;
      while (i < cmd.length && cmd[i] !== '"') { i += cmd[i] === '\\' ? 2 : 1; }
      out += '""';
      if (i >= cmd.length) return out;               // unterminated
      i++;
      continue;
    }
    out += ch;
    i++;
  }
  return out;
}

function words(skel) {
  return skel.split(/[\s;|&()]+/).filter(Boolean);
}

// ---------------------------------------------------------------------------
// Read the payload. A malformed payload under a real parser is a true anomaly,
// not a quoting artifact, so it fails closed (F24 acceptance row).
// ---------------------------------------------------------------------------
let raw = '';
try { raw = require('fs').readFileSync(0, 'utf8'); } catch { raw = ''; }

if (raw.trim() === '') allow();                      // nothing to enforce

let payload;
try { payload = JSON.parse(raw); }
catch { deny('hook payload is not valid JSON — refusing to guess at its contents.'); }

// Enforce only the NAMED field. A danger string in `description` or `content`
// is not a command (F24 cross-field decoys).
const command = payload && payload.tool_input && typeof payload.tool_input.command === 'string'
  ? payload.tool_input.command
  : '';
if (!command.trim()) allow();

const skel = skeleton(command);
const toks = words(skel);
const has = (re) => re.test(skel);

// ---------------------------------------------------------------------------
// LAYER 1 — blocking checks. ALL of them run before any early exit.
//
// Ledger row 1 exists only in the inline implementation today, and the .sh port
// placed the database guard BELOW `grep -qE 'git\s+(commit|push)' || exit 0`
// (dg-git-guard.sh:28), which makes it dead code for every non-git deploy —
// precisely the commands it is meant to stop. Order is load-bearing here.
// ---------------------------------------------------------------------------

// Row 1: database deploy to a remote environment.
const DB_DEPLOY = [
  /\bsupabase\s+db\s+push\b/,
  /\bprisma\s+migrate\s+deploy\b/,
  /\bdotnet\s+ef\s+database\s+update\b/,
  /\bflyway\s+(migrate|clean)\b/,
  /\brails\s+db:migrate\b/,
];
// Exemptions count ONLY inside the command field, and only outside quotes.
const DB_EXEMPT = /(^|\s)(--local|--dry-run|--dry)(\s|$)|RAILS_ENV=(test|development)/;
if (DB_DEPLOY.some((re) => re.test(skel)) && !DB_EXEMPT.test(skel)) {
  deny('Direct database deploy to a remote environment. Validate with --dry-run, or deploy via CI/CD.');
}

// F25: force push. `--force-with-lease` is the SAFE form and must survive.
// A /--force\b/ pattern matches inside `--force-with-lease` because '-' is a
// word boundary — that was the defect. Match whole tokens instead.
if (has(/\bgit\s+push\b/)) {
  const forced = toks.some((t) => t === '--force' || /^-[A-Za-z]*f[A-Za-z]*$/.test(t));
  if (forced) deny('Force push is not allowed. Use --force-with-lease if you must overwrite a remote branch.');
}

// F22: destructive but legitimate — ASK, never deny, and never stderr on exit 0.
if (has(/\bgit\s+reset\s+(--hard|--merge\s+--hard)\b/) || toks.includes('--hard')) {
  if (has(/\bgit\s+reset\b/)) {
    ask('git reset --hard discards every uncommitted change in the working tree. Confirm this is intended.');
  }
}

// ---------------------------------------------------------------------------
// Ledger rows 5-6 — opt-in only. F05(c): DG_STRICT_GIT defaults OFF, so these
// ship documented as opt-in rather than advertised as active.
// ---------------------------------------------------------------------------
if (process.env.DG_STRICT_GIT !== '1') allow();
if (!has(/\bgit\s+(commit|push)\b/)) allow();

const fs = require('fs');
const os = require('os');
const path = require('path');
const { execFileSync } = require('child_process');
const sessionId = (payload && typeof payload.session_id === 'string' && payload.session_id) || 'default';
const tmp = process.env.TMPDIR || process.env.TEMP || os.tmpdir();

// Row 8: read BOTH tracker key names. The inline implementation wrote `total`,
// the script wrote `total_changes_since_audit`; a single-key read silently sees 0.
function trackerCount(file) {
  let txt = '';
  try { txt = fs.readFileSync(file, 'utf8'); } catch { return null; }
  let obj = null;
  try { obj = JSON.parse(txt); } catch { obj = null; }
  if (obj) {
    for (const k of ['session_changes', 'total_changes_since_audit', 'total']) {
      if (typeof obj[k] === 'number') return obj[k];
    }
  }
  const m = txt.match(/"(?:session_changes|total_changes_since_audit|total)"\s*:\s*(\d+)/);
  return m ? Number(m[1]) : null;
}

// Row 6: staging-count sanity check.
if (has(/\bgit\s+commit\b/)) {
  let staged = 0;
  try {
    staged = execFileSync('git', ['diff', '--cached', '--name-only'], { encoding: 'utf8' })
      .split('\n').filter(Boolean).length;
  } catch { staged = 0; }
  const edits = trackerCount(path.join(tmp, `dg-baseline-${sessionId}`));
  if (staged > 0 && edits !== null && edits > 0 && staged > edits * 2 + 5) {
    deny(`Staging check: ${edits} files edited this session but ${staged} staged. Review with 'git diff --cached --stat'.`);
  }
}

// Row 5: build verification before commit.
const marker = path.join(tmp, `dg-build-${sessionId}`);
try {
  const age = (Date.now() - fs.statSync(marker).mtimeMs) / 60000;
  if (age < 120) allow();
} catch { /* no marker */ }

let buildCmd = '';
try {
  const pkg = fs.readFileSync('package.json', 'utf8');
  if (/"build"/.test(pkg)) buildCmd = 'npm run build';
  else if (/"typecheck"/.test(pkg)) buildCmd = 'npm run typecheck';
} catch { /* not a node project */ }
if (!buildCmd) {
  try { if (fs.readdirSync('.').some((f) => f.endsWith('.sln'))) buildCmd = 'dotnet build'; } catch {}
}
if (!buildCmd && fs.existsSync('Cargo.toml')) buildCmd = 'cargo check';
if (!buildCmd && fs.existsSync('go.mod')) buildCmd = 'go vet ./...';
if (!buildCmd) allow();

deny(`No successful build recorded this session. Run '${buildCmd}' before committing.`);

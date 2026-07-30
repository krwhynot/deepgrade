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
// Shell-style word splitting. THE central mechanism.
//
// The first implementation of this guard DELETED the contents of quoted spans.
// That fixed the false positives (a commit message naming a force-push) and
// opened five bypasses, because a shell does not delete quoted text — it strips
// the quote CHARACTERS and keeps the content as part of the surrounding word.
// `git push "--force"` is an ordinary working command; span-deletion turned it
// into `git push ""` and allowed it, which the old bare-regex guard had caught.
// Found by an adversarial probe, not by the corpus: all 18 corpus rows quoted
// PROSE, none quoted a FLAG.
//
// So: split into words the way sh does — quotes contribute their content and
// vanish as delimiters, adjacent segments join into one word — and match on word
// SEQUENCES rather than on substrings. Both properties then hold at once:
//
//   git commit -m "no git push --force"  -> [git, commit, -m, "no git push --force"]
//        the message is ONE word, so the sequence [git, push] is absent -> allow
//   git push "--force"                   -> [git, push, --force]        -> deny
//   git push --fo''rce                   -> [git, push, --force]        -> deny
//   grep -rn 'supabase db push' docs/    -> [grep, -rn, "supabase db push", docs/]
//        one word again -> allow
//
// Commands are also split into SEGMENTS on ; && || | ( ), so a flag in one
// command cannot satisfy a guard aimed at another (`git reset --soft && tar --hard`).
//
// Known and accepted limit: UNQUOTED prose is indistinguishable from an
// invocation without full shell semantics, so `echo git push --force` is denied.
// The old guard denied it too. Over-blocking a benign `echo` is the correct side
// to err on for a security control; under-blocking is not.
// ---------------------------------------------------------------------------
function segments(cmd) {
  const segs = [[]];
  let word = '';
  let started = false;   // distinguishes an empty quoted word from no word at all
  let i = 0;
  const endWord = () => { if (started) { segs[segs.length - 1].push(word); word = ''; started = false; } };
  const endSeg = () => { endWord(); if (segs[segs.length - 1].length) segs.push([]); };

  while (i < cmd.length) {
    const c = cmd[i];
    if (c === '\\') {                      // escapes the next character
      if (i + 1 < cmd.length) { word += cmd[i + 1]; started = true; i += 2; } else i++;
      continue;
    }
    if (c === "'") {                       // literal, no escapes inside
      i++;
      while (i < cmd.length && cmd[i] !== "'") { word += cmd[i]; i++; }
      started = true; i++;
      continue;
    }
    if (c === '"') {                       // honours backslash escapes
      i++;
      while (i < cmd.length && cmd[i] !== '"') {
        if (cmd[i] === '\\' && i + 1 < cmd.length) { word += cmd[i + 1]; i += 2; }
        else { word += cmd[i]; i++; }
      }
      started = true; i++;
      continue;
    }
    if (/\s/.test(c)) { endWord(); i++; continue; }
    if (c === ';' || c === '(' || c === ')' || c === '\n') { endSeg(); i++; continue; }
    if (c === '&' || c === '|') { endSeg(); while (i < cmd.length && (cmd[i] === '&' || cmd[i] === '|')) i++; continue; }
    word += c; started = true; i++;
  }
  endWord();
  return segs.filter((s) => s.length);
}

// Consecutive-word match. `[git, push]` must appear adjacently, which is what
// makes a quoted multi-word string unable to satisfy it.
function hasSeq(words, seq) {
  outer:
  for (let i = 0; i + seq.length <= words.length; i++) {
    for (let j = 0; j < seq.length; j++) if (words[i + j] !== seq[j]) continue outer;
    return true;
  }
  return false;
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

const segs = segments(command);

// ---------------------------------------------------------------------------
// LAYER 1 — blocking checks, evaluated PER SEGMENT so a flag belonging to one
// command cannot satisfy a guard aimed at another. ALL of them run before any
// early exit.
//
// Ledger row 1 exists only in the inline implementation today, and the .sh port
// placed the database guard BELOW `grep -qE 'git\s+(commit|push)' || exit 0`
// (dg-git-guard.sh:28), which makes it dead code for every non-git deploy —
// precisely the commands it is meant to stop. Order is load-bearing here.
// ---------------------------------------------------------------------------

// Row 1: database deploy to a remote environment.
const DB_DEPLOY = [
  ['supabase', 'db', 'push'],
  ['prisma', 'migrate', 'deploy'],
  ['dotnet', 'ef', 'database', 'update'],
  ['flyway', 'migrate'],
  ['flyway', 'clean'],
  ['rails', 'db:migrate'],
];
const isExempt = (w) => w === '--local' || w === '--dry-run' || w === '--dry'
  || /^RAILS_ENV=(test|development)$/.test(w);

for (const words of segs) {
  if (!DB_DEPLOY.some((seq) => hasSeq(words, seq))) continue;
  // Exemptions count only within the SAME segment as the deploy itself.
  if (words.some(isExempt)) continue;
  deny('Direct database deploy to a remote environment. Validate with --dry-run, or deploy via CI/CD.');
}

// F25: force push. `--force-with-lease` is the SAFE form and must survive.
// A /--force\b/ pattern matches inside `--force-with-lease` because '-' is a
// word boundary — that was the original defect. Whole-word equality avoids it,
// and word splitting means a quoted flag still counts as that word.
const isForceFlag = (w) => w === '--force' || /^-[A-Za-z]*f[A-Za-z]*$/.test(w);
for (const words of segs) {
  if (hasSeq(words, ['git', 'push']) && words.some(isForceFlag)) {
    deny('Force push is not allowed. Use --force-with-lease if you must overwrite a remote branch.');
  }
}

// F22: destructive but legitimate — ASK, never deny, and never stderr on exit 0.
// `--hard` must be in the same segment as `git reset`, so `git reset --soft &&
// tar --hard` does not prompt.
for (const words of segs) {
  if (hasSeq(words, ['git', 'reset']) && words.includes('--hard')) {
    ask('A hard reset discards every uncommitted change in the working tree. Confirm this is intended.');
  }
}

// ---------------------------------------------------------------------------
// Ledger rows 5-6 — opt-in only. F05(c): DG_STRICT_GIT defaults OFF, so these
// ship documented as opt-in rather than advertised as active.
// ---------------------------------------------------------------------------
if (process.env.DG_STRICT_GIT !== '1') allow();
const isCommitOrPush = segs.some((w) => hasSeq(w, ['git', 'commit']) || hasSeq(w, ['git', 'push']));
if (!isCommitOrPush) allow();

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
if (segs.some((w) => hasSeq(w, ['git', 'commit']))) {
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

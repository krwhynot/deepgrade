#!/usr/bin/env node
// DeepGrade: Git / deploy guard (PreToolUse: Bash) — lane N
//
// Contract: approach.md 3.1.6. Enforce ONLY what is parsed.
//   - real parser present (this is node, so always): extract the NAMED field
//     tool_input.command, enforce, and fail CLOSED on a payload JSON.parse rejects
//   - never DENY on the basis of something unparsed. `ask` is not a deny, so a
//     construct this cannot evaluate becomes a prompt rather than a silent allow
//   - deny  -> exit 2 + "BLOCKED" on stderr (stderr IS surfaced on exit 2)
//   - ask   -> exit 0 + JSON permissionDecision "ask"   (F22)
//   - allow -> exit 0, silent
//   - never stderr on exit 0                             (F26)
//
// Acceptance is tests/fixtures/hook-corpus.json. A matcher that fails any row fails
// PHV5-041 regardless of how it is written.
//
// REVISION HISTORY, because two of these were regressions I introduced:
//   cf46aab  deleted quoted spans -> `git push "--force"` was ALLOWED while the old
//            bare-regex guard denied it. Fixed at bcf691c by word splitting.
//   bcf691c  word splitting, but matched command words by strict ADJACENCY, so any
//            global option between them slipped through (`git -c x=y push --force`),
//            and `\n` never ended a segment because /\s/ caught it first.
//   this     command-position matching that tolerates global options, `\n` as a real
//            separator, `+refspec` force pushes, and ask-on-unparseable.
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
// Shell-style word splitting.
//
// Quotes contribute their CONTENT and vanish as delimiters; adjacent segments join
// into one word. That is what a shell does, and it is why `git push "--force"` must
// still be caught while `git commit -m "no git push --force"` must not: in the
// second case the message is a single word, so the command words are not adjacent.
//
// Segments split on ; && || | ( ) and NEWLINE. The newline case is load-bearing and
// was previously dead code — `/\s/.test(c)` matched it first, so a multi-line command
// was one segment. That both laundered exemptions across commands and produced false
// denials (a benign push followed by `grep -f` looked like a force push).
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
    if (c === '\\') {
      // A backslash before a newline is a LINE CONTINUATION: it joins the lines and
      // contributes nothing. Previously the newline was appended to the next word,
      // producing "\n--force", which matched no flag and no sequence.
      if (cmd[i + 1] === '\n') { i += 2; continue; }
      if (cmd[i + 1] === '\r' && cmd[i + 2] === '\n') { i += 3; continue; }
      if (i + 1 < cmd.length) { word += cmd[i + 1]; started = true; i += 2; } else i++;
      continue;
    }
    if (c === "'") {
      i++;
      while (i < cmd.length && cmd[i] !== "'") { word += cmd[i]; i++; }
      started = true; i++;
      continue;
    }
    if (c === '"') {
      i++;
      while (i < cmd.length && cmd[i] !== '"') {
        if (cmd[i] === '\\' && i + 1 < cmd.length) { word += cmd[i + 1]; i += 2; }
        else { word += cmd[i]; i++; }
      }
      started = true; i++;
      continue;
    }
    // NEWLINE FIRST. It is whitespace, so the generic test below would swallow it.
    if (c === '\n' || c === '\r') { endSeg(); i++; continue; }
    if (c === ';' || c === '(' || c === ')') { endSeg(); i++; continue; }
    if (c === '&' || c === '|') { endSeg(); while (i < cmd.length && (cmd[i] === '&' || cmd[i] === '|')) i++; continue; }
    if (/\s/.test(c)) { endWord(); i++; continue; }
    word += c; started = true; i++;
  }
  endWord();
  return segs.filter((s) => s.length);
}

// `/usr/bin/git`, `git.exe` and `git` are the same program.
function basename(w) {
  return w.replace(/\\/g, '/').split('/').pop().replace(/\.(exe|cmd|bat|ps1)$/i, '');
}

const WRAPPERS = new Set(['sudo', 'env', 'command', 'nohup', 'time', 'timeout', 'npx', 'bunx', 'winpty', 'stdbuf']);

// Match a command and its subcommand words at a COMMAND POSITION, tolerating leading
// environment assignments, wrappers, and global options with their values.
//
// Strict adjacency was the bug: `git -c core.pager=cat push --force`,
// `git --no-pager push --force`, `git -C . push --force`,
// `supabase --workdir . db push` and `dotnet ef --project X database update` all
// evaded every rule at once.
function hasCommandSeq(words, seq) {
  let i = 0;
  while (i < words.length) {
    const w = words[i];
    if (/^[A-Za-z_][A-Za-z0-9_]*=/.test(w)) { i++; continue; }   // FOO=bar prefix
    if (WRAPPERS.has(basename(w))) { i++; continue; }
    break;
  }
  if (i >= words.length || basename(words[i]) !== seq[0]) return false;

  let j = i + 1;
  for (let k = 1; k < seq.length; k++) {
    // Skip option tokens, and a token that is the VALUE of the option before it.
    while (j < words.length && words[j] !== seq[k]) {
      const prev = words[j - 1];
      const isOption = words[j].startsWith('-');
      const isOptionValue = prev && prev.startsWith('-') && !prev.includes('=');
      if (!isOption && !isOptionValue) break;
      j++;
    }
    if (j >= words.length || words[j] !== seq[k]) return false;
    j++;
  }
  return true;
}

// ---------------------------------------------------------------------------
// Read the payload. A malformed payload under a real parser is a true anomaly, not a
// quoting artifact, so it fails closed (F24 acceptance row).
// ---------------------------------------------------------------------------
let raw = '';
try { raw = require('fs').readFileSync(0, 'utf8'); } catch { raw = ''; }
if (raw.trim() === '') allow();

let payload;
try { payload = JSON.parse(raw); }
catch { deny('hook payload is not valid JSON — refusing to guess at its contents.'); }

// Enforce only the NAMED field. A danger string in `description` or `content` is not
// a command (F24 cross-field decoys).
const command = payload && payload.tool_input && typeof payload.tool_input.command === 'string'
  ? payload.tool_input.command
  : '';
if (!command.trim()) allow();

const segs = segments(command);

// ---------------------------------------------------------------------------
// LAYER 1 — blocking checks, PER SEGMENT so a flag belonging to one command cannot
// satisfy a guard aimed at another. ALL of them run before any early exit: the .sh
// port placed the database guard below `grep -qE 'git\s+(commit|push)' || exit 0`,
// which is dead code for every non-git deploy. Order is load-bearing.
// ---------------------------------------------------------------------------

const DB_DEPLOY = [
  ['supabase', 'db', 'push'],
  ['prisma', 'migrate', 'deploy'],
  ['dotnet', 'ef', 'database', 'update'],
  ['flyway', 'migrate'],
  ['flyway', 'clean'],
  ['rails', 'db:migrate'],
  ['rake', 'db:migrate'],          // the classic Rails form, previously absent
];
const isExempt = (w) => w === '--local' || w === '--dry-run' || w === '--dry'
  || /^RAILS_ENV=(test|development)$/.test(w);

for (const words of segs) {
  if (!DB_DEPLOY.some((seq) => hasCommandSeq(words, seq))) continue;
  if (words.some(isExempt)) continue;   // exemptions count only within the same segment
  deny('Direct database deploy to a remote environment. Validate with --dry-run, or deploy via CI/CD.');
}

// F25 + H5. `--force-with-lease` is the SAFE form and must survive: whole-word
// equality avoids the `/--force\b/` trap, where '-' is a word boundary. `-4f` and
// `-6f` are real bundles (`-4`/`-6` are git's address-family flags), so digits count.
// A leading '+' on a refspec is a force push with no flag at all to find.
const isForceFlag = (w) => w === '--force' || /^-[A-Za-z0-9]*f[A-Za-z0-9]*$/.test(w);
const isForceRefspec = (w) => /^\+[A-Za-z0-9._/^~-]+(:[A-Za-z0-9._/^~-]+)?$/.test(w);
for (const words of segs) {
  if (!hasCommandSeq(words, ['git', 'push'])) continue;
  if (words.some(isForceFlag)) {
    deny('Force push is not allowed. Use --force-with-lease if you must overwrite a remote branch.');
  }
  if (words.some(isForceRefspec)) {
    deny('A leading "+" on a refspec is a force push. Use --force-with-lease, or push without the "+".');
  }
}

// F22: destructive but legitimate — ASK, never deny, never stderr on exit 0.
for (const words of segs) {
  if (hasCommandSeq(words, ['git', 'reset']) && words.includes('--hard')) {
    ask('A hard reset discards every uncommitted change in the working tree. Confirm this is intended.');
  }
}

// ---------------------------------------------------------------------------
// Constructs this cannot evaluate -> ASK, not allow.
//
// A shell expands things a static matcher cannot see: `git push $'--force'`,
// `git${IFS}push${IFS}--force`, `F=--force; git push $F`, `bash -c "git push --force"`.
// No amount of tokenizer work reaches these, so the honest response is to stop
// pretending. 3.1.6 forbids DENYING on something unparsed; asking is permitted and is
// what F22 already uses for "destructive but legitimate".
//
// Scoped deliberately to segments that mention a guarded program or run a nested
// shell, so an everyday `echo $HOME` does not prompt.
// ---------------------------------------------------------------------------
const GUARDED = new Set(['git', 'supabase', 'prisma', 'dotnet', 'flyway', 'rails', 'rake']);
const NESTED_SHELL = new Set(['bash', 'sh', 'zsh', 'dash', 'eval', 'xargs', 'source']);

// A word carrying an expansion or a substitution is not a clean program name:
// `git${IFS}push${IFS}--force` is ONE word, and in `echo \`git push --force\`` the
// word is "`git". Both slipped past a basename-equality test, so when a word contains
// `$` or a backtick, look for a guarded name as a SUBSTRING.
const wordMentionsGuarded = (w) => {
  if (GUARDED.has(basename(w))) return true;
  if (/[$`]/.test(w)) { for (const g of GUARDED) if (w.includes(g)) return true; }
  return false;
};

for (const words of segs) {
  const mentionsGuarded = words.some(wordMentionsGuarded);
  const nested = words.some((w) => NESTED_SHELL.has(basename(w)));
  if (!mentionsGuarded && !nested) continue;

  // An unexpanded parameter or command substitution: the real argv is unknowable here.
  const unexpanded = words.some((w) => /[$`]/.test(w));
  // A nested shell carries its whole program inside one word.
  const nestedProgram = nested && words.some((w) => /\s/.test(w) || GUARDED.has(basename(w)));

  if (unexpanded || nestedProgram) {
    ask('This command contains a shell construct the guard cannot evaluate '
      + '(a variable, a substitution, or a nested shell), so its real effect is unknown. '
      + 'Confirm it does not force-push or deploy to a remote database.');
  }
}

// ---------------------------------------------------------------------------
// Ledger rows 5-6 — opt-in only. F05(c): DG_STRICT_GIT defaults OFF, so these ship
// documented as opt-in rather than advertised as active.
// ---------------------------------------------------------------------------
if (process.env.DG_STRICT_GIT !== '1') allow();
const isCommitOrPush = segs.some((w) => hasCommandSeq(w, ['git', 'commit']) || hasCommandSeq(w, ['git', 'push']));
if (!isCommitOrPush) allow();

const fs = require('fs');
const os = require('os');
const path = require('path');
const { execFileSync } = require('child_process');

// A session id is interpolated into a filename, so it is validated before use.
// Unvalidated, `session_id: "../../../../../../x/y"` wrote tracker JSON OVER a file
// outside TMPDIR — confirmed by probe. path.join eats the first `..` against the
// `dg-baseline-..` component, which is why a shallow test looks safe.
function safeSessionId(v) {
  return (typeof v === 'string' && /^[A-Za-z0-9._-]{1,64}$/.test(v) && v !== '.' && v !== '..')
    ? v : 'default';
}
const sessionId = safeSessionId(payload && payload.session_id);
const tmp = process.env.TMPDIR || process.env.TEMP || os.tmpdir();

// Ledger row 8: read BOTH tracker key names. The inline implementation wrote `total`,
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
if (segs.some((w) => hasCommandSeq(w, ['git', 'commit']))) {
  let staged = 0;
  try {
    // stdio: stderr must be IGNORED, not inherited. Node's default inherits it, so a
    // git error (e.g. cwd is not a repository) emitted 7kB on stderr at exit 0 —
    // violating this file's own F26 rule.
    staged = execFileSync('git', ['diff', '--cached', '--name-only'],
      { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] })
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

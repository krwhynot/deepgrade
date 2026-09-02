# Mutation-test the guards rebuilt after the Codex review. Every mutation below is a
# false pass Codex DEMONSTRATED against the previous versions; each must now be CAUGHT.
# Plus controls that must stay silent.
#
# Lock + per-file preconditions, both earned the hard way earlier today.
import io, os, re, subprocess, sys, atexit

# Repo-relative: this harness is tracked, so it must not carry an absolute path from
# whichever machine happened to write it.
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
SCRATCH = os.environ.get('TMPDIR') or os.environ.get('TEMP') or '/tmp'
os.chdir(ROOT)

LOCK = os.path.join(SCRATCH, 'dg-wave5-guards.lock')
try:
    _fd = os.open(LOCK, os.O_CREAT | os.O_EXCL | os.O_WRONLY)
    os.write(_fd, str(os.getpid()).encode()); os.close(_fd)
except FileExistsError:
    print('REFUSING: %s exists — another instance holds the lock.' % LOCK); sys.exit(3)
atexit.register(lambda: os.path.exists(LOCK) and os.unlink(LOCK))


FILES = ['plugins/deepgrade/commands/quick-cleanup.md', 'plugins/deepgrade/commands/plan-status.md', 'plugins/deepgrade/commands/plan-export.md',
         'plugins/deepgrade-readiness/commands/readiness-generate.md', 'plugins/deepgrade/skills/plan/stages/stage-1-plan.md', 'plugins/deepgrade/commands/help.md',
         'plugins/deepgrade-audit/commands/codebase-gates.md',
         'plugins/deepgrade-audit/agents/gate-generator.md', 'plugins/deepgrade/skills/documentation/SKILL.md',
         'plugins/deepgrade/skills/mcp-research/SKILL.md', 'README.md', 'CHANGELOG.md',
         'docs/specs/mcp-research-integration.md']
BAK = {f: io.open(f, encoding='utf-8', newline='').read() for f in FILES}

REQUIRED = {
    'plugins/deepgrade/commands/plan-status.md':   'PLANS_DIR="docs/plans"',
    'plugins/deepgrade/commands/quick-cleanup.md': 'No source folder given',
    'plugins/deepgrade-audit/agents/gate-generator.md':  'PowerShell variant',
    'plugins/deepgrade/skills/plan/stages/stage-1-plan.md':          'deepgrade:mcp-research',
}
FORBIDDEN = {
    'README.md':    'deepgrade:doc adr topic',
    'CHANGELOG.md': '## Unreleased',
}
_bad = ['%s: missing %r' % (f, m) for f, m in REQUIRED.items() if m not in BAK[f]] \
     + ['%s: contains %r' % (f, m) for f, m in FORBIDDEN.items() if m in BAK[f]]
if _bad:
    print('REFUSING — tree not pristine:'); [print('  ' + b) for b in _bad]; sys.exit(4)

for f, s in BAK.items():
    # Keyed by FULL PATH: basename collided — skills/documentation/SKILL.md and
    # skills/mcp-research/SKILL.md both wrote SKILL.md.pristine (Codex round 4, N5).
    io.open(os.path.join(SCRATCH, 'dgmut-' + f.replace('/', '__') + '.pristine'), 'w',
            encoding='utf-8', newline='').write(s)

# RESTORE ON TERMINATION, not just on the happy path.
#
# A run killed mid-mutation left `skills/mcp-research/SKILL.md` carrying mutant W6 in the
# working tree: atexit removed the lock and nothing put the file back. Every earlier
# safeguard here addressed a DIFFERENT stranding cause (foreground timeout, concurrent
# instance, un-backed-up target, failed restore) — this is the termination path, which
# Codex round 4 N5 named and which then happened.
#
# atexit fires on a normal exit and on an unhandled exception; the signal handlers cover
# SIGINT/SIGTERM. SIGKILL cannot be caught, which is why the per-file preconditions at
# startup remain the real backstop: the next run refuses a dirty tree rather than
# snapshotting the damage.
def _emergency_restore():
    try:
        for _f, _s in BAK.items():
            if io.open(_f, encoding='utf-8', newline='').read() != _s:
                io.open(_f, 'w', encoding='utf-8', newline='').write(_s)
                print('emergency restore: %s' % _f)
    except Exception as _e:
        print('EMERGENCY RESTORE FAILED: %s — check `git status` before committing' % _e)

import signal
def _on_signal(signum, _frame):
    print('\nsignal %d received — restoring before exit' % signum)
    _emergency_restore()
    os.path.exists(LOCK) and os.unlink(LOCK)
    sys.exit(130)
for _sig in (signal.SIGINT, signal.SIGTERM):
    try:
        signal.signal(_sig, _on_signal)
    except (ValueError, AttributeError, OSError):
        pass  # not all platforms/contexts allow every handler

def restore():
    """Restore AND verify. Previously wrote the bytes back and assumed success; a partial
    or failed write was invisible until the final baseline happened to go red."""
    bad = []
    for f, s in BAK.items():
        io.open(f, 'w', encoding='utf-8', newline='').write(s)
        if io.open(f, encoding='utf-8', newline='').read() != s:
            bad.append(f)
    if bad:
        print('RESTORE BYTE-MISMATCH: ' + ', '.join(bad))
    return not bad

def run(script):
    """Returns (fail_lines, crashed). A TAG-ONLY ORACLE IS NOT ENOUGH.

    The previous version returned only lines starting with [FAIL] and discarded the
    subprocess status entirely, so a suite that crashed mid-run — set -u, a syntax
    error, an unlabelled abort — produced an empty list and read as CLEAN. A mutation
    that broke the harness rather than tripping the guard therefore counted as
    'caught' for a catch case, and as 'quiet' for a control (Codex round 3, N3).
    """
    try:
        # TIMEOUT: a hung suite previously blocked the run indefinitely (Codex round 4, N5).
        r = subprocess.run(['bash', script], capture_output=True, text=True,
                           encoding='utf-8', errors='replace', timeout=600)
    except subprocess.TimeoutExpired:
        return [], True
    out = r.stdout or ''
    fails = [l for l in out.splitlines() if l.startswith('[FAIL]')]
    # ANCHORED completion record. An unanchored 'Results:' substring could be produced by
    # any line of output, including a mutation's own text.
    completed = any(re.match(r'^Results: \d+ passed', l) for l in out.splitlines())
    crashed = (not completed) or (r.returncode != 0 and not fails)
    return fails, crashed

def l1(): return run('tests/layer1-config-wiring.sh')
def l4(): return run('tests/layer4-behavioral-smoke.sh')

def patch(f, old, new, count=1):
    # REFUSE to mutate a file that was never backed up. V1 targeted
    # commands/codebase-gates.md, which was absent from FILES, so restore() could not undo
    # it and the mutant was left in the working tree — reintroducing the live shipping
    # defect the mutation was written to detect. Caught only by the new red-final-baseline
    # check. A harness that can edit outside its backup set is a corruption tool.
    if f not in BAK:
        raise AssertionError('%s is not in FILES; refusing to mutate a file with no backup' % f)
    s = io.open(f, encoding='utf-8', newline='').read()
    # EOL-AWARE. This tree has mixed line endings (core.autocrlf=true on the reference
    # host), and a multi-line anchor written with '\n' silently matches nothing in a CRLF
    # file. That produced a NO-OP mutant four separate times in this plan before being
    # fixed at the source instead of per-anchor. Translate the anchor to the file's own
    # terminator; on an LF file this is the identity.
    nl = '\r\n' if '\r\n' in s else '\n'
    if nl != '\n':
        old = old.replace('\n', nl)
        new = new.replace('\n', nl)
    if old not in s: return False
    io.open(f, 'w', encoding='utf-8', newline='').write(s.replace(old, new, count))
    return True

def append_prose(f, text):
    """Append a plain prose line — NOT a fenced block. Used by controls, which must be
    edits a maintainer would plausibly make."""
    assert f in BAK, '%s is not in FILES; refusing to mutate a file with no backup' % f
    s = io.open(f, encoding='utf-8', newline='').read()
    nl = '\r\n' if '\r\n' in s else '\n'
    io.open(f, 'w', encoding='utf-8', newline='').write(s + nl + text + nl)
    return True

def append_block(f, body):
    """Append a fenced bash block to a command file."""
    assert f in BAK, '%s is not in FILES; refusing to mutate a file with no backup' % f
    s = io.open(f, encoding='utf-8', newline='').read()
    nl = '\r\n' if '\r\n' in s else '\n'
    io.open(f, 'w', encoding='utf-8', newline='').write(
        s + nl + '```bash' + nl + body.replace('\n', nl) + nl + '```' + nl)
    return True

# (label, layer, tag, mutation, expect)  expect: 'catch' or 'quiet'
MUTS = [
 # --- Codex F3: the eight demonstrated false passes ---
 ('Y1  quoted # hides a live $1 from comment-stripping', l1, 'F09',
  lambda: append_block('plugins/deepgrade/commands/quick-cleanup.md', 'printf "#"; echo "$1"'), 'catch'),
 ('Y2  indented FOLDER="$0" evades the column-zero anchor', l1, 'F09',
  lambda: append_block('plugins/deepgrade/commands/quick-cleanup.md', '  FOLDER="$0"'), 'catch'),
 # Was an INVALID MUTANT: it replaced the key with `argument-hint:XX` then replaced that
 # straight back, so the file was never changed and the guard was right to stay green.
 # Strip the VALUE instead, which is the defect the guard is supposed to see.
 ('Y3  argument-hint: present but with no value', l1, 'F11',
  lambda: patch('plugins/deepgrade-readiness/commands/readiness-generate.md',
                'argument-hint: "[number|all-critical|all]"', 'argument-hint:'), 'catch'),
 ('Y4  guard says docs/plans but the loop hardcodes plans/*/', l1, 'F13',
  lambda: patch('plugins/deepgrade/commands/plan-status.md', 'for d in "$PLANS_DIR"/*/', 'for d in plans/*/'), 'catch'),
 ('Y5  a FOURTH disable-model-invocation command', l1, 'F14',
  lambda: patch('plugins/deepgrade/commands/help.md', '---\n', '---\ndisable-model-invocation: true\n')
          or patch('plugins/deepgrade/commands/help.md', '---\r\n', '---\r\ndisable-model-invocation: true\r\n'), 'catch'),
 ('Y6  bare `tree .` with no option flag', l1, 'F15',
  lambda: append_block('plugins/deepgrade-readiness/commands/readiness-generate.md', 'tree .'), 'catch'),
 ('Y7  only a COMMENT names powershell + Compress-Archive', l1, 'F15',
  lambda: patch('plugins/deepgrade/commands/plan-export.md',
                '  powershell.exe -NoProfile -Command "Compress-Archive',
                '  # powershell.exe -NoProfile -Command "Compress-Archive'), 'catch'),
 ('Y8  PowerShell instruction inverted to a prohibition', l1, 'F08',
  lambda: patch('plugins/deepgrade-audit/agents/gate-generator.md', 'PowerShell variant', 'do not emit a PowerShell variant'), 'catch'),
 ('Y9  skill wired by PROSE only, not a namespaced name', l1, 'F28',
  lambda: patch('plugins/deepgrade/skills/plan/stages/stage-1-plan.md', '`deepgrade:mcp-research` skill', 'mcp-research skill'), 'catch'),
 # --- Codex F4: clauses that previously had no falsifying assertion ---
 ('Y10 drop the ${CLAUDE_PROJECT_DIR} resolution', l1, 'F10',
  lambda: patch('plugins/deepgrade/commands/plan-export.md', '${CLAUDE_PROJECT_DIR:-$OLDPWD}', '$PWD', 2), 'catch'),
 ('Y11 strip a skill description to a stub', l1, 'F28',
  lambda: patch('plugins/deepgrade/skills/mcp-research/SKILL.md',
                'description:', 'description: MCP stuff\nx-old-description:'), 'catch'),
 ('Y12 documentation skill loses CLAUDE_SKILL_DIR dispatch', l1, 'F30',
  lambda: patch('plugins/deepgrade/skills/documentation/SKILL.md', 'CLAUDE_SKILL_DIR', 'NOPE_DIR', 99), 'catch'),
 # Y13 REMOVED (Codex round 4, N4): it renamed the '## Plan awareness' heading while every
 # line of plan-aware behaviour survived, so "caught" only ever meant "the heading changed".
 # The clause it was meant to protect is a model-behaviour claim, now recorded NOT MET by
 # class-G means rather than defended by a heading check.
 # --- Codex F1/F2: the row, now literal ---
 ('Y14 stale reference reappears on product surface', l1, 'F30',
  lambda: patch('README.md', '\n## ', '\n\nRun `/deepgrade:doc adr topic`.\n\n## '), 'catch'),
 ('Y15 stale reference under a FAKE release heading (old bypass)', l1, 'F30',
  lambda: patch('CHANGELOG.md', '# Changelog',
                '# Changelog\n\n## 9.9.9 (2099-01-01)\n\n- `/deepgrade:doc` lives\n'), 'catch'),
 ('Y16 stale reference back in the shipped spec (old bypass)', l1, 'F30',
  lambda: patch('docs/specs/mcp-research-integration.md',
                'invoke the documentation skill', 'run `/deepgrade:doc adr t`'), 'catch'),
 # --- Codex F5/F6: the behavioral tests ---
 # Was an INVALID MUTANT: `false` inserted at the TOP of the block only sets $? and the
 # script keeps going -- there is no `set -e`, so the exit status is whatever the last
 # command returns. Codex appended it. Put it at the END, after the loop, where it really
 # is the script's exit status.
 ('Y17 overview block exits nonzero', l4, 'B6',
  lambda: patch('plugins/deepgrade/commands/plan-status.md',
                'echo "$NAME | phase: $PHASE | brainstorm: $BRAINSTORM | research: $RESEARCH files '
                '| approach: $APPROACH | plan: $PLAN | audit: $AUDIT | test: $TEST"\ndone',
                'echo "$NAME | phase: $PHASE | brainstorm: $BRAINSTORM | research: $RESEARCH files '
                '| approach: $APPROACH | plan: $PLAN | audit: $AUDIT | test: $TEST"\ndone\nfalse'), 'catch'),
 ('Y18 no-plans path exits 7 instead of 0', l4, 'B6',
  lambda: patch('plugins/deepgrade/commands/plan-status.md',
                'echo "No plans found. Start one with /deepgrade:plan <name>."\n  exit 0',
                'echo "No plans found. Start one with /deepgrade:plan <name>."\n  exit 7'), 'catch'),
 ('Y19 sentinel inert AND downstream message reworded (X3 + reword)', l4, 'B7',
  lambda: patch('plugins/deepgrade/commands/quick-cleanup.md',
                'echo "No source folder given. Usage: /deepgrade:quick-cleanup <folder>"\n  exit 0',
                'echo "No source folder given. Usage: /deepgrade:quick-cleanup <folder>"\n  :')
          and patch('plugins/deepgrade/commands/quick-cleanup.md', 'Not a directory:', 'Invalid folder:'), 'catch'),
 # --- Round 2 (Codex N1-N7): every one a false pass DEMONSTRATED against the guards
 #     that replaced the round-1 versions. Frontmatter decoys, command-position gaps,
 #     negated references, and ordinal block selection.
 ('W1  argument-hint deleted from frontmatter, decoy in BODY', l1, 'F11',
  lambda: patch('plugins/deepgrade-readiness/commands/readiness-generate.md', 'argument-hint: "[number|all-critical|all]"', '')
          and append_block('plugins/deepgrade-readiness/commands/readiness-generate.md', 'x') is None or True, 'catch'),
 # The anchor needed the surrounding lines: `disable-model-invocation: true\n` alone is a
 # prefix of the frontmatter line AND could match nothing once the trailing context
 # differs. Anchored on the adjacent allowed-tools line, which is stable.
 ('W2  disable-model-invocation moved from frontmatter to BODY', l1, 'F14',
  lambda: patch('plugins/deepgrade/commands/plan-export.md',
                'allowed-tools: Read, Write, Grep, Glob, Bash, Task\ndisable-model-invocation: true\n---',
                'allowed-tools: Read, Write, Grep, Glob, Bash, Task\n---\n\ndisable-model-invocation: true'), 'catch'),
 ('W3  CLAUDE_PROJECT_DIR only inside an HTML comment', l1, 'F10',
  lambda: patch('plugins/deepgrade/commands/plan-export.md', '${CLAUDE_PROJECT_DIR:-$OLDPWD}', '$OLDPWD', 9), 'catch'),
 ('W4  `tree` after an `if` keyword', l1, 'F15',
  lambda: append_block('plugins/deepgrade-readiness/commands/readiness-generate.md', 'if tree .; then :; fi'), 'catch'),
 ('W5  skill referenced only to FORBID it', l1, 'F28',
  lambda: patch('plugins/deepgrade/skills/plan/stages/stage-1-plan.md', 'see the `deepgrade:mcp-research` skill',
                'never invoke `deepgrade:mcp-research`; it is deprecated'), 'catch'),
 ('W6  description states it should NOT load', l1, 'F28',
  lambda: patch('plugins/deepgrade/skills/mcp-research/SKILL.md', 'description: ',
                'description: Do not use when writing any code; this skill has no supported trigger. '), 'catch'),
 # NOT a legitimate-edit control (Codex round 4, N4): inserting a bogus executable block into a
 # runtime command is adversarial. Kept as an adversarial negative — B6 must ignore it — but it
 # must not be counted among the controls that prove specificity against real maintenance.
 ('W7  adversarial: decoy block precedes the real overview (B6 must ignore)', l4, 'B6',
  lambda: patch('plugins/deepgrade/commands/plan-status.md', '```bash',
                '```bash\nPLANS_DIR="docs/plans"\necho decoy\n```\n\n```bash'), 'quiet'),
 ('W8  B7: sentinel inert AND downstream guard emits only a blank line', l4, 'B7',
  lambda: patch('plugins/deepgrade/commands/quick-cleanup.md',
                'echo "No source folder given. Usage: /deepgrade:quick-cleanup <folder>"\n  exit 0',
                'echo "No source folder given. Usage: /deepgrade:quick-cleanup <folder>"\n  :')
          and patch('plugins/deepgrade/commands/quick-cleanup.md', 'echo "Not a directory: $FOLDER"', 'echo ""'), 'catch'),
 # --- Controls: must stay SILENT ---
 # Was a BAD CONTROL: replacing '## ' produced an EMPTY heading and demoted the original
 # heading text to prose (Codex round 3). A control has to be an edit a maintainer would
 # actually make, or "the guard stayed quiet" says nothing about legitimate work.
 ('Z1  control: prose about a "directory tree" (not a command)', l1, 'F15',
  lambda: append_prose('plugins/deepgrade-readiness/commands/readiness-generate.md',
                       'The directory tree is deep, so prefer a bounded find.'), 'quiet'),
 ('Z2  control: reword an unrelated CI merge line', l1, 'F08',
  lambda: patch('plugins/deepgrade-audit/agents/gate-generator.md', 'Merge into existing files.', 'Combine with existing files.'), 'quiet'),
 # Over-strictness controls. A guard that fires on a LEGITIMATE edit gets weakened by
 # whoever hits it, so the weakened version is what survives (Codex Q3).
 ('Z3  control: ${PLANS_DIR} braced form in the loop', l1, 'F13',
  lambda: patch('plugins/deepgrade/commands/plan-status.md', 'for d in "$PLANS_DIR"/*/', 'for d in "${PLANS_DIR}"/*/'), 'quiet'),
 ('Z4  control: "Do not omit Windows support; emit a PowerShell variant"', l1, 'F08',
  lambda: patch('plugins/deepgrade-audit/agents/gate-generator.md', 'Emit a PowerShell variant',
                'Do not omit Windows support.\nEmit a PowerShell variant'), 'quiet'),
 ('Z5  control: harmless reword of the usage sentence', l4, 'B7',
  lambda: patch('plugins/deepgrade/commands/quick-cleanup.md',
                'No source folder given. Usage: /deepgrade:quick-cleanup <folder>',
                'No source folder supplied. Usage: /deepgrade:quick-cleanup <folder>'), 'quiet'),
 ('Z6  control: legitimate rewrite "For every generated hook, also emit..."', l1, 'F08',
  lambda: patch('plugins/deepgrade-audit/agents/gate-generator.md',
                'Emit a PowerShell variant of every generated hook command alongside the POSIX one.',
                'For every generated hook, also emit a PowerShell variant alongside the POSIX one.'), 'quiet'),
 # --- Round 3 (Codex): the live product defect, the behavioural archive test, and the
 #     canary/marker fixes. Each is a variant Codex demonstrated, not a re-run.
 ('V1  the PARENT COMMAND names the inert plugin-side hooks path', l1, 'F08',
  lambda: patch('plugins/deepgrade-audit/commands/codebase-gates.md',
                'the `hooks` key of .claude/settings.json',
                '.claude/hooks/hooks.json'), 'catch'),
 ('V2  archive fallback only NAMES the cmdlet (Write-Output decoy)', l4, 'B8',
  lambda: patch('plugins/deepgrade/commands/plan-export.md', '"Compress-Archive -Path',
                '"Write-Output Compress-Archive -Path'), 'catch'),
 # Relabelled: removes the TEST MARKER, not a product behaviour. It legitimately proves B6
 # fails closed when its subject cannot be identified — worth testing — but it is not evidence
 # about plan-status itself. Naming it accurately stops it padding a defect count.
 ('V3  B6 fails closed when its selection marker is absent (not a product defect)', l4, 'B6',
  lambda: patch('plugins/deepgrade/commands/plan-status.md', '# dg-test-marker: plan-status-overview', '# overview'), 'catch'),
 # Relabelled for the same reason as V3: a duplicated guard is not a defect, it is an
 # AMBIGUITY. B7 must refuse to certify reachability when it cannot tell which guard runs.
 ('V4  B7 fails closed on an ambiguous duplicated guard (not a product defect)', l4, 'B7',
  lambda: patch('plugins/deepgrade/commands/quick-cleanup.md',
                'if [ ! -d "$FOLDER" ]; then',
                'if [ ! -d "$FOLDER" ]; then\n  :\nfi\nif [ ! -d "$FOLDER" ]; then'), 'catch'),
]

(base1, c1), (base4, c4) = l1(), l4()
if base1 or base4 or c1 or c4:
    print('BASELINE NOT GREEN:')
    [print('  ' + b) for b in base1 + base4]
    if c1 or c4:
        print('  a suite did not run to completion (crash/abort)')
    restore(); sys.exit(1)
print('baseline green (layer1 + layer4)\n')

bad = 0
for label, layer, tag, apply, expect in MUTS:
    if not apply():
        print('  NO-OP    %s  <-- anchor drifted' % label); bad = 1; restore(); continue
    try:
        r, crashed = layer()
    finally:
        restore()
    hit = any(tag in l for l in r)
    if crashed:
        # A suite that aborted proves nothing either way. Previously this surfaced as an
        # empty failure list — i.e. 'caught' for a catch case and 'quiet' for a control.
        print('  CRASHED  %s  <-- suite did not complete; result is not evidence' % label)
        bad = 1
    elif expect == 'catch':
        if hit:
            print('  CAUGHT   %s' % label)
        else:
            print('  ESCAPED  %s   (%d other failures)' % (label, len(r))); bad = 1
    else:
        # A control must produce NO failures at all, not merely none carrying its own tag.
        # Tag-only checking let a legitimate edit break something else and still read quiet.
        if r:
            print('  BAD      %s  <-- legitimate change caused %d failure(s): %s'
                  % (label, len(r), r[0][:70])); bad = 1
        else:
            print('  OK-QUIET %s' % label)

restore()
(a1, _), (a4, _) = l1(), l4()
if a1 or a4:
    # A red FINAL baseline means the tree was left dirty. This was printed and ignored.
    print('RESTORE FAILED: the tree is not clean after the run')
    bad = 1
print('\nrestored: %d + %d failures' % (len(a1), len(a4)))
print('SOME ESCAPED' if bad else 'ALL WAVE 5c MUTATIONS CAUGHT, CONTROLS QUIET')
sys.exit(bad)

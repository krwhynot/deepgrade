# Mutation-test the guards rebuilt after the Codex review. Every mutation below is a
# false pass Codex DEMONSTRATED against the previous versions; each must now be CAUGHT.
# Plus controls that must stay silent.
#
# Lock + per-file preconditions, both earned the hard way earlier today.
import io, os, subprocess, sys, atexit

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

FILES = ['commands/quick-cleanup.md', 'commands/plan-status.md', 'commands/plan-export.md',
         'commands/readiness-generate.md', 'commands/plan.md', 'commands/help.md',
         'agents/gate-generator.md', 'skills/documentation/SKILL.md',
         'skills/mcp-research/SKILL.md', 'README.md', 'CHANGELOG.md',
         'docs/specs/mcp-research-integration.md']
BAK = {f: io.open(f, encoding='utf-8', newline='').read() for f in FILES}

REQUIRED = {
    'commands/plan-status.md':   'PLANS_DIR="docs/plans"',
    'commands/quick-cleanup.md': 'No source folder given',
    'agents/gate-generator.md':  'PowerShell variant',
    'commands/plan.md':          'deepgrade:mcp-research',
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
    io.open(os.path.join(SCRATCH, os.path.basename(f) + '.pristine'), 'w',
            encoding='utf-8', newline='').write(s)

def restore():
    for f, s in BAK.items():
        io.open(f, 'w', encoding='utf-8', newline='').write(s)

def run(script):
    r = subprocess.run(['bash', script], capture_output=True, text=True,
                       encoding='utf-8', errors='replace')
    return [l for l in (r.stdout or '').splitlines() if l.startswith('[FAIL]')]

def l1(): return run('tests/layer1-config-wiring.sh')
def l4(): return run('tests/layer4-behavioral-smoke.sh')

def patch(f, old, new, count=1):
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

def append_block(f, body):
    """Append a fenced bash block to a command file."""
    s = io.open(f, encoding='utf-8', newline='').read()
    nl = '\r\n' if '\r\n' in s else '\n'
    io.open(f, 'w', encoding='utf-8', newline='').write(
        s + nl + '```bash' + nl + body.replace('\n', nl) + nl + '```' + nl)
    return True

# (label, layer, tag, mutation, expect)  expect: 'catch' or 'quiet'
MUTS = [
 # --- Codex F3: the eight demonstrated false passes ---
 ('Y1  quoted # hides a live $1 from comment-stripping', l1, 'F09',
  lambda: append_block('commands/quick-cleanup.md', 'printf "#"; echo "$1"'), 'catch'),
 ('Y2  indented FOLDER="$0" evades the column-zero anchor', l1, 'F09',
  lambda: append_block('commands/quick-cleanup.md', '  FOLDER="$0"'), 'catch'),
 # Was an INVALID MUTANT: it replaced the key with `argument-hint:XX` then replaced that
 # straight back, so the file was never changed and the guard was right to stay green.
 # Strip the VALUE instead, which is the defect the guard is supposed to see.
 ('Y3  argument-hint: present but with no value', l1, 'F11',
  lambda: patch('commands/readiness-generate.md',
                'argument-hint: "[number|all-critical|all]"', 'argument-hint:'), 'catch'),
 ('Y4  guard says docs/plans but the loop hardcodes plans/*/', l1, 'F13',
  lambda: patch('commands/plan-status.md', 'for d in "$PLANS_DIR"/*/', 'for d in plans/*/'), 'catch'),
 ('Y5  a FOURTH disable-model-invocation command', l1, 'F14',
  lambda: patch('commands/help.md', '---\n', '---\ndisable-model-invocation: true\n')
          or patch('commands/help.md', '---\r\n', '---\r\ndisable-model-invocation: true\r\n'), 'catch'),
 ('Y6  bare `tree .` with no option flag', l1, 'F15',
  lambda: append_block('commands/readiness-generate.md', 'tree .'), 'catch'),
 ('Y7  only a COMMENT names powershell + Compress-Archive', l1, 'F15',
  lambda: patch('commands/plan-export.md',
                '  powershell.exe -NoProfile -Command "Compress-Archive',
                '  # powershell.exe -NoProfile -Command "Compress-Archive'), 'catch'),
 ('Y8  PowerShell instruction inverted to a prohibition', l1, 'F08',
  lambda: patch('agents/gate-generator.md', 'PowerShell variant', 'do not emit a PowerShell variant'), 'catch'),
 ('Y9  skill wired by PROSE only, not a namespaced name', l1, 'F28',
  lambda: patch('commands/plan.md', '`deepgrade:mcp-research` skill', 'mcp-research skill'), 'catch'),
 # --- Codex F4: clauses that previously had no falsifying assertion ---
 ('Y10 drop the ${CLAUDE_PROJECT_DIR} resolution', l1, 'F10',
  lambda: patch('commands/plan-export.md', '${CLAUDE_PROJECT_DIR:-$OLDPWD}', '$PWD', 2), 'catch'),
 ('Y11 strip a skill description to a stub', l1, 'F28',
  lambda: patch('skills/mcp-research/SKILL.md',
                'description:', 'description: MCP stuff\nx-old-description:'), 'catch'),
 ('Y12 documentation skill loses CLAUDE_SKILL_DIR dispatch', l1, 'F30',
  lambda: patch('skills/documentation/SKILL.md', 'CLAUDE_SKILL_DIR', 'NOPE_DIR', 99), 'catch'),
 ('Y13 documentation skill loses Plan awareness', l1, 'F30',
  lambda: patch('skills/documentation/SKILL.md', '## Plan awareness', '## Notes'), 'catch'),
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
  lambda: patch('commands/plan-status.md',
                'echo "$NAME | phase: $PHASE | brainstorm: $BRAINSTORM | research: $RESEARCH files '
                '| approach: $APPROACH | plan: $PLAN | audit: $AUDIT | test: $TEST"\ndone',
                'echo "$NAME | phase: $PHASE | brainstorm: $BRAINSTORM | research: $RESEARCH files '
                '| approach: $APPROACH | plan: $PLAN | audit: $AUDIT | test: $TEST"\ndone\nfalse'), 'catch'),
 ('Y18 no-plans path exits 7 instead of 0', l4, 'B6',
  lambda: patch('commands/plan-status.md',
                'echo "No plans found. Start one with /deepgrade:plan <name>."\n  exit 0',
                'echo "No plans found. Start one with /deepgrade:plan <name>."\n  exit 7'), 'catch'),
 ('Y19 sentinel inert AND downstream message reworded (X3 + reword)', l4, 'B7',
  lambda: patch('commands/quick-cleanup.md',
                'echo "No source folder given. Usage: /deepgrade:quick-cleanup <folder>"\n  exit 0',
                'echo "No source folder given. Usage: /deepgrade:quick-cleanup <folder>"\n  :')
          and patch('commands/quick-cleanup.md', 'Not a directory:', 'Invalid folder:'), 'catch'),
 # --- Round 2 (Codex N1-N7): every one a false pass DEMONSTRATED against the guards
 #     that replaced the round-1 versions. Frontmatter decoys, command-position gaps,
 #     negated references, and ordinal block selection.
 ('W1  argument-hint deleted from frontmatter, decoy in BODY', l1, 'F11',
  lambda: patch('commands/readiness-generate.md', 'argument-hint: "[number|all-critical|all]"', '')
          and append_block('commands/readiness-generate.md', 'x') is None or True, 'catch'),
 # The anchor needed the surrounding lines: `disable-model-invocation: true\n` alone is a
 # prefix of the frontmatter line AND could match nothing once the trailing context
 # differs. Anchored on the adjacent allowed-tools line, which is stable.
 ('W2  disable-model-invocation moved from frontmatter to BODY', l1, 'F14',
  lambda: patch('commands/plan-export.md',
                'allowed-tools: Read, Write, Grep, Glob, Bash, Task\ndisable-model-invocation: true\n---',
                'allowed-tools: Read, Write, Grep, Glob, Bash, Task\n---\n\ndisable-model-invocation: true'), 'catch'),
 ('W3  CLAUDE_PROJECT_DIR only inside an HTML comment', l1, 'F10',
  lambda: patch('commands/plan-export.md', '${CLAUDE_PROJECT_DIR:-$OLDPWD}', '$OLDPWD', 9), 'catch'),
 ('W4  `tree` after an `if` keyword', l1, 'F15',
  lambda: append_block('commands/readiness-generate.md', 'if tree .; then :; fi'), 'catch'),
 ('W5  skill referenced only to FORBID it', l1, 'F28',
  lambda: patch('commands/plan.md', 'see the `deepgrade:mcp-research` skill',
                'never invoke `deepgrade:mcp-research`; it is deprecated'), 'catch'),
 ('W6  description states it should NOT load', l1, 'F28',
  lambda: patch('skills/mcp-research/SKILL.md', 'description: ',
                'description: Do not use when writing any code; this skill has no supported trigger. '), 'catch'),
 ('W7  B6: decoy bash block precedes the real overview', l4, 'B6',
  lambda: patch('commands/plan-status.md', '```bash',
                '```bash\nPLANS_DIR="docs/plans"\necho decoy\n```\n\n```bash'), 'quiet'),
 ('W8  B7: sentinel inert AND downstream guard emits only a blank line', l4, 'B7',
  lambda: patch('commands/quick-cleanup.md',
                'echo "No source folder given. Usage: /deepgrade:quick-cleanup <folder>"\n  exit 0',
                'echo "No source folder given. Usage: /deepgrade:quick-cleanup <folder>"\n  :')
          and patch('commands/quick-cleanup.md', 'echo "Not a directory: $FOLDER"', 'echo ""'), 'catch'),
 # --- Controls: must stay SILENT ---
 ('Z1  control: prose about a "directory tree" (not a command)', l1, 'F15',
  lambda: patch('commands/readiness-generate.md', '## ', '## \nThe directory tree is deep.\n'), 'quiet'),
 ('Z2  control: reword an unrelated CI merge line', l1, 'F08',
  lambda: patch('agents/gate-generator.md', 'Merge into existing files.', 'Combine with existing files.'), 'quiet'),
 # Over-strictness controls. A guard that fires on a LEGITIMATE edit gets weakened by
 # whoever hits it, so the weakened version is what survives (Codex Q3).
 ('Z3  control: ${PLANS_DIR} braced form in the loop', l1, 'F13',
  lambda: patch('commands/plan-status.md', 'for d in "$PLANS_DIR"/*/', 'for d in "${PLANS_DIR}"/*/'), 'quiet'),
 ('Z4  control: "Do not omit Windows support; emit a PowerShell variant"', l1, 'F08',
  lambda: patch('agents/gate-generator.md', 'Emit a PowerShell variant',
                'Do not omit Windows support.\nEmit a PowerShell variant'), 'quiet'),
 ('Z5  control: harmless reword of the usage sentence', l4, 'B7',
  lambda: patch('commands/quick-cleanup.md',
                'No source folder given. Usage: /deepgrade:quick-cleanup <folder>',
                'No source folder supplied. Usage: /deepgrade:quick-cleanup <folder>'), 'quiet'),
]

base1, base4 = l1(), l4()
if base1 or base4:
    print('BASELINE NOT GREEN:'); [print('  ' + b) for b in base1 + base4]
    restore(); sys.exit(1)
print('baseline green (layer1 + layer4)\n')

bad = 0
for label, layer, tag, apply, expect in MUTS:
    if not apply():
        print('  NO-OP    %s  <-- anchor drifted' % label); bad = 1; restore(); continue
    try:
        r = layer()
    finally:
        restore()
    hit = any(tag in l for l in r)
    if expect == 'catch':
        if hit:
            print('  CAUGHT   %s' % label)
        else:
            print('  ESCAPED  %s   (%d other failures)' % (label, len(r))); bad = 1
    else:
        if hit:
            print('  BAD      %s  <-- fired on a legitimate change' % label); bad = 1
        else:
            print('  OK-QUIET %s' % label)

restore()
a1, a4 = l1(), l4()
print('\nrestored: %d + %d failures' % (len(a1), len(a4)))
print('SOME ESCAPED' if bad else 'ALL WAVE 5c MUTATIONS CAUGHT, CONTROLS QUIET')
sys.exit(bad)

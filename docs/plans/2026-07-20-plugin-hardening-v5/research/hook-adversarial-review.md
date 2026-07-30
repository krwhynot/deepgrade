# Adversarial review of lane N's hook guards — 2026-07-29

Reviewer: independent parallel agent, mandate "find inputs that defeat these guards", no
knowledge of my own probe set beyond being told not to re-report the quoting class fixed in
`bcf691c`. 130+ probes. Every finding below was then **reproduced by me independently** before
being recorded; the reproduction commands are in the session scratchpad.

Target: `scripts/dg-*.js` at `9043b6d`. **These are defects in code already committed and
activated (4b), so they are live in the repo, not hypothetical.**

## Confirmed — reproduced independently

| ID | Defect | Reproduction |
|----|--------|--------------|
| **H1** | Global git options defeat the word-adjacency check. `hasSeq(words,['git','push'])` requires the two words adjacent; git accepts options between them. | `git -c core.pager=cat push --force` → exit 0. Also `--no-pager`, `-C .`, `supabase --workdir . db push`, `dotnet ef --project X database update`, and `git -C . reset --hard` (no prompt). **One defect breaks all four rules plus the DG_STRICT_GIT gate.** |
| **H6** | `\n` never ends a segment. `if (/\s/.test(c))` at `dg-git-guard.js:88` matches `\n` first, so the `c === '\n'` test on line 89 is **unreachable**. | `segments("a\nb")` → `[["a","b"]]` vs `segments("a;b")` → `[["a"],["b"]]`. **Bidirectional:** `supabase db push` ⏎ `echo --dry-run` → allowed (exemption laundered from another command); `git push origin main` ⏎ `grep -f patterns.txt build.log` → **falsely BLOCKED** as a force push. |
| **H5** | `+refspec` force push is not modelled at all. | `git push origin +main` → exit 0. There is no `--force` token to find, so no tokenizer change reaches this. |
| **M1** | Short-flag regex `/^-[A-Za-z]*f[A-Za-z]*$/` assumes all-alpha bundles. | `git push -4f origin main` → exit 0. (`-4` is git's IPv4 flag; the reviewer verified real git parses `-4f` as options.) |
| **M8** | `dg-track-test.js` forges markers two ways: bare-word patterns match commands that merely *name* a tool, and `words().join(' ')` **flattens segments** — the isolation the git guard was fixed to keep. | `grep -rn tsc src/` → build marker. `echo npm && test -f dist/index.js` → test marker. `cat make.log` → build marker. A forged build marker also satisfies the `DG_STRICT_GIT` build gate. |
| **M10** | **F26 reintroduced by me.** `execFileSync` at `dg-git-guard.js:215` uses default stdio, which inherits stderr. | `DG_STRICT_GIT=1`, `git commit` payload, cwd not a repo, fresh build marker → **exit 0 with 7322 bytes on stderr**. The file's own header says "never stderr on exit 0". Fix: `stdio: ['ignore','pipe','ignore']`. |
| **M9** | `session_id` is interpolated into a filename unvalidated (`dg-track-change.js:35`, `dg-track-test.js:100`, `dg-session-stop.js:29`, `dg-git-guard.js:218`, `:225`) → **write outside TMPDIR**. | Confirmed at traversal depth 6: a file outside TMPDIR was overwritten with tracker JSON. Note `path.join` consumes the first `..` against the `dg-baseline-..` component, so a naive single-depth probe looks safe — I initially failed to reproduce this for exactly that reason and had to sweep the depth. Fix: reject `session_id` not matching `/^[A-Za-z0-9._-]{1,64}$/`, or hash it. |

## Confirmed, but not closable by tokenizer hardening — DESIGN DECISION PENDING

**H2/H3/H4.** All exit 0 silent, all proved by the reviewer with an argv-logging shim ahead of
`git` on PATH, so "the shell really would have invoked it" is measured rather than argued:

- shell expansion: `git push $'--force'`, `git${IFS}push${IFS}--force`, `F=--force; git push $F`,
  `git push ${NOPE:---force}`, `` echo `git push --force` `` (note `$(...)` **is** caught, because
  `(` is a segment separator and a backtick is not)
- nested shell strings as one word: `bash -c "git push --force"`, `sh -c '...'`, `eval "..."`,
  a shell function wrapper, `bash -c "supabase db push"`
- line continuation: `git push \` ⏎ `--force` — the `\` branch swallows the newline and prepends
  `\n` to the next word, so neither the flag nor the sequence matches

No tokenizer closes these: the shell expands things a static matcher cannot. The reviewer's
recommendation, which I think is correct, is to stop pretending: when a segment contains an
unexpanded `$`, a backtick, or a nested-shell invocation (`bash -c`, `sh -c`, `eval`, `xargs`),
return **`ask`** rather than `allow`. That converts a silent bypass into a prompt.

**Cost, stated honestly:** commands containing `$VAR` are common, so this adds prompts to
legitimate work. That is a product decision about noise versus a known hole, so it is recorded
here awaiting the owner rather than decided by me.

## Also confirmed, lower severity

- **M2** command word must be literally `git`/`supabase`: `/usr/bin/git push --force`,
  `git.exe push --force`, `npx supabase@latest db push` → allowed.
- **M3** argv-splitting: `echo --force | xargs git push`; `git config alias.fp 'push --force'`
  then `git fp origin main`.
- **M4** **Windows case-folding.** `MIGRATION_DIRS` is matched case-sensitively but NTFS is not:
  `db/MIGRATIONS/20240101_init.sql` → allowed while `db/migrations/...` → denied, with the
  guard's own `existsSync` confirming both resolve to the same applied migration. A
  one-character case change edits an applied migration.
- **M5** the guard misses naming conventions of directories it explicitly lists: alembic hex
  revision ids (`1a2b3c4d5e6f_add_users.py`), Liquibase `.xml` changesets with <4-digit
  prefixes, and `/DbMigrations/` (does not contain `/Migrations/`).
- **M6** false positives: any dated markdown in `/changelog/` or `/migrate/` becomes
  unmodifiable with a misleading "Editing an existing migration" message. Writing to an
  existing *directory* path also denies, since `existsSync` does not distinguish.
- **M7** the migration control covers only the Write/Edit route. `sed -i`, `>>`, `truncate` on a
  migration path via Bash are all unguarded.
- **L1** non-string `tool_input.command` (array, number, object) fails **open** — the contract
  fails closed on unparseable JSON but is silent on a structurally valid payload of the wrong type.
- **L2** ~0.45 s per MB of command text against a 5 s hook timeout; above ~11 MB no verdict.
- **L3** `dg-subagent-stop.js` log injection — a newline in `reason` appends a forged timestamped
  entry verbatim.
- **L6** coverage gaps where no rule exists at all: `git push origin :main`, `--delete`,
  `--mirror`, `filter-branch`, `clean -fdx`; and absent from `DB_DEPLOY`: **`rake db:migrate`**
  (the classic Rails form — only `rails db:migrate` is listed), `python manage.py migrate`,
  `alembic upgrade head`, `liquibase update`, `knex migrate:latest`, `wrangler d1 migrations
  apply --remote`, `psql $PROD_URL -f migration.sql`.

## What correctly held — recorded so coverage is distinguishable from silence

**The quoting class fixed in `bcf691c` is genuinely closed.** The reviewer could not find a new
variant: `git push "--force"`, `'--force'`, `--fo''rce`, `git "push" --force`,
`'git' 'push' '--force'`, `\git push --force`, `git push --for\ce`, `supabase db "push"` — all
denied. `echo $(git push --force)` denied. Prefixes keeping the words adjacent (`sudo`,
`command`, `timeout 60`, `nohup`, `GIT_SSH_COMMAND=...`) denied. Whitespace tricks (tabs,
trailing `\r`, U+2028, NBSP) denied. `--force-with-lease` allowed; `--force=true` and em-dash
`—force` allowed **correctly**, since git rejects both.

**The migration guard never blocks creating a new migration** — the reviewer tried and could not
make it. The M6 false positives are on non-migration files.

**All six informational hooks: 156/156 hostile combinations clean** — exit 0, JSON-or-nothing on
stdout, nothing on stderr, no hang, no crash. Covered malformed JSON, closed stdin, `null`/`42`/
`[]` payloads, 200k-deep nesting, 20 MB payloads, nonexistent TMPDIR, TMPDIR pointing at a file,
`status.json` as a scalar, `current_phase` = `__proto__`, plan directory names containing `$(...)`.
The fail-open discipline holds; M9 and L3 are input-validation issues, not availability ones.

## Lesson for the plan

My own adversarial pass at `bcf691c` found the quoting class, fixed it, and measured **0
bypasses**. That zero meant my probe set was exhausted, not the attack surface — I had tested
quoting because quoting was the bug I had just fixed, and never tried `git -c`, a newline, or a
`+refspec`, all of which a normal user types. An independent reviewer with no memory of the
previous fix broke that frame for the cost of one parallel agent.

**Rule:** after fixing a defect class, the class stops being evidence about the rest of the
surface. Re-probe from a mandate, not from the last fix.

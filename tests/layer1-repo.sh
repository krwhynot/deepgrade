#!/usr/bin/env bash
# =============================================================================
# Layer 1 (repo): repo-wide sweeps that no single plugin directory can own.
#
#   - line-ending policy (§14, A1/CR-2/CR-3) — derived from the tracked tree
#   - F30 stale-reference sweep (§18) — every tracked .md
#   - the PH5 sentinels (PH5-001..PH5-060) — the verifier-gate invariants; their
#     subject files live in the deepgrade plugin but the restatement/count sweeps
#     cover every tracked doc across all plugin dirs
#   - the root-doc claim sweep (§16) — root-level docs sit outside every plugin,
#     so the per-plugin core pass cannot see them
#
# Extracted verbatim from the monolithic layer1-config-wiring.sh (split step 4).
# Runs from the repo root; the dispatcher owns the anchored Results line.
# =============================================================================

set -u

cd "$(dirname "$0")/.." || exit 1

PASS=0
FAIL=0
WARN=0

pass() {
  echo "[PASS] $1"
  PASS=$((PASS + 1))
}

fail() {
  echo "[FAIL] $1"
  FAIL=$((FAIL + 1))
}

warn() {
  echo "[WARN] $1"
  WARN=$((WARN + 1))
}

echo "=== Layer 1 repo-wide sweeps ==="
echo ""
# ===========================================================================
# 14. Line-ending policy covers every executable script (A1 + CR-2 + CR-3)
#
# `git ls-files --eol` is NOT usable here: it reports w/lf with no .gitattributes
# present at all, so it can never fail (that is what CR-2 corrected). Assert the
# ATTRIBUTE instead, via git check-attr, which reads the policy rather than the
# current checkout. The falsifying acceptance test remains the fresh-clone
# `file` check recorded in CR-2/CR-3.
#
# Subjects are DERIVED from the tracked tree, so a newly added script is covered
# the moment it is committed — the failure mode CR-3 exists to close was a new
# file class silently falling outside the policy.
# ===========================================================================
echo ""
echo "--- Line-ending policy (A1/CR-2/CR-3) ---"

# DERIVED BY CLASS, not by a hardcoded extension list.
#
# The comment above claimed "a newly added script is covered the moment it is committed",
# and the code below enumerated '*.sh' '*.js' 'tests/fixtures/*'. Those are not the same
# claim: it derived FILES WITHIN KNOWN EXTENSIONS, so a new script CLASS still fell
# outside silently — precisely the failure CR-3 was ratified to close. Demonstrated by
# committing tests/mutation/wave5-guards.py, the first tracked .py: it landed with
# `eol: unspecified` and this section stayed green.
#
# Now: known extensions UNION anything carrying a shebang, whatever it is called. A new
# interpreter cannot be introduced without becoming a subject here.
eol_subjects=0
eol_bad=0
eol_known=$(git ls-files '*.sh' '*.js' '*.py' '*.ps1' 'tests/fixtures/*' 2>/dev/null)
# FIRST LINE ONLY, in one batched pass.
#   - `head -c2` per file spawned a subprocess per tracked path and blew a two-minute budget.
#   - `grep -lIm1 '^#!'` was fast but WRONG: it matches a `#!` line anywhere in the file, so
#     agents/gate-generator.md — which contains a shebang inside a fenced example — was
#     classified as an executable script. A shebang is only a shebang on line 1.
# `nextfile` stops after the first record of each file, so this reads one line per path.
eol_shebang=$(git ls-files -z 2>/dev/null \
  | xargs -0 awk 'FNR==1 && /^#!/ { print FILENAME } { nextfile }' 2>/dev/null)
eol_list=$(printf '%s\n%s\n' "$eol_known" "$eol_shebang" | grep -v '^$' | sort -u)
for f in $eol_list; do
  eol_subjects=$((eol_subjects + 1))
  attr=$(git check-attr eol -- "$f" 2>/dev/null | sed 's/.*: //')
  if [ "$attr" != "lf" ]; then
    fail "A1/CR-3: $f is an executable script or fixture but its eol attribute is '$attr', not 'lf'"
    eol_bad=1
  fi
done
if [ "$eol_subjects" -lt 15 ]; then
  fail "A1/CR-3: derived only $eol_subjects policy subjects (expected >= 15) — the derivation is broken, not the policy"
elif [ "$eol_bad" -eq 0 ]; then
  pass "A1/CR-3: all $eol_subjects shell scripts, node scripts and fixtures carry eol=lf"
fi

# The rationale at the top of .gitattributes must name both extensions. It said
# "the hook guards and the test suite are shell scripts" while lane N shipped the
# guards as .js — a policy file asserting something no longer true of the tree,
# which is exactly the drift class the consistency sweep guards elsewhere.
if [ ! -f .gitattributes ]; then
  fail "A1: .gitattributes is missing entirely"
else
  head_txt=$(sed -n '1,20p' .gitattributes | tr -d '\r')
  rationale_ok=1
  # Every covered class must be NAMED in the rationale. CR-3 asserted the sentence could not
  # drift again, then CR-5 found it naming .sh and .js while the policy had to cover .py.
  # Derived from the policy file itself, so adding a class without naming it fails here.
  for _cls in $(grep -oE '^\*\.[a-z0-9]+ text eol=lf' .gitattributes | sed 's/^\*\.//; s/ .*//'); do
    echo "$head_txt" | grep -q "\.$_cls" || {
      fail "A1/CR-5: .gitattributes covers *.$_cls but its rationale never names it — the sentence has drifted from the policy again"
      rationale_ok=0
    }
  done
  if [ "$rationale_ok" -eq 1 ]; then
    pass "A1/CR-3: the .gitattributes rationale names both .sh and .js"
  else
    fail "A1/CR-3: the .gitattributes rationale does not name both .sh and .js — it will drift from the tree again"
  fi
fi
# ===========================================================================
# 18. F30 stale-reference sweep — enforced LITERALLY, no exemptions.
#
# The acceptance row is class G and absolute: "no `/deepgrade:doc` or `commands/doc.md`
# string survives anywhere". No guard existed; I had closed F30 on having deleted the
# file, and three references survived.
#
# The first version of this guard exempted two historical documents (a CHANGELOG release
# entry, a shipped-feature spec) on the reasoning that rewriting them would falsify a
# record, and paired that with an unratified change record. Codex review (gpt-5.6-sol
# @ xhigh, 2026-07-30) found a concrete bypass in every one of those exemptions AND the
# better option I had missed: reword the two documents TRUTHFULLY. "The documentation
# command and skill" is accurate for 4.31.0, git history preserves the exact former
# spelling, and the row is then satisfiable with no exemption at all.
#
# So there is nothing to bypass here now. Every exemption mechanism is deleted, CR-4 is
# withdrawn, and the rule is the row.
# ===========================================================================
echo ""
echo "--- F30 stale-reference sweep ---"

f30_bad=0
# The deleted file must stay deleted wherever a commands/ dir lives now.
for f30_cmds in commands plugins/*/commands; do
  [ -e "$f30_cmds/doc.md" ] && { fail "F30: $f30_cmds/doc.md still exists"; f30_bad=1; }
done

# Subject set: every tracked .md except an EXPLICIT two-path allowlist.
#
# The previous version skipped all of `docs/plans/*`, which I described in the pass
# message and the commit as "enforced literally, no exemptions". It was not: three stale
# references were living in an UNRELATED plan (2026-04-03-mcp-research-integration) and
# the sweep reported clean (Codex N1). I had replaced two narrow disclosed exemptions
# with one broad undisclosed one. Those three are now reworded, so the allowlist is:
#
#   1. THIS plan's directory      — its records ARE the evidence of the deletion
#   2. THIS plan's spec           — it states the row, so it must quote the strings
#
# Nothing else, including other plans. Anything added to this list is a scope change and
# belongs in a change record.
f30_count=0
f30_skipped=0
# NUL-delimited: `for f in $subjects` word-splits, so a tracked path containing a space
# would be counted toward the floor and then silently skipped during inspection
# (Codex F2). -z/IFS= is immune to that.
while IFS= read -r -d '' f; do
  case "$f" in
    docs/plans/2026-07-20-plugin-hardening-v5/*|docs/specs/plugin-hardening-v5.md)
      f30_skipped=$((f30_skipped + 1)); continue ;;
  esac
  [ -f "$f" ] || continue
  f30_count=$((f30_count + 1))
  if grep -qE '/deepgrade:doc\b|commands/doc\.md' "$f" 2>/dev/null; then
    fail "F30: $f references a deleted command — $(grep -nE '/deepgrade:doc\b|commands/doc\.md' "$f" | head -1 | cut -c1-70)"
    f30_bad=1
  fi
done < <(git ls-files -z '*.md' 2>/dev/null)

# Detect N1's ACTUAL failure mode rather than counting skips. N1 was not "too many files
# skipped" — this plan legitimately has ~46 — it was OTHER plans falling inside the
# exclusion. So: assert that files under docs/plans/ belonging to other plans are being
# INSPECTED. A count threshold cannot see that and my first attempt at one just fired on
# the legitimate size of this plan.
f30_other_plans=$(git ls-files 'docs/plans/*.md' 2>/dev/null \
  | grep -v '^docs/plans/2026-07-20-plugin-hardening-v5/' | grep -c . || true)
f30_other_dirs=$(git ls-files 'docs/plans/*' 2>/dev/null \
  | grep -v '^docs/plans/2026-07-20-plugin-hardening-v5/' \
  | sed 's|^docs/plans/\([^/]*\)/.*|\1|' | sort -u | grep -c . || true)
if [ "$f30_other_dirs" -gt 0 ] && [ "$f30_other_plans" -eq 0 ]; then
  fail "F30: $f30_other_dirs other plan director(ies) exist but contributed no inspected .md files — the exclusion is broader than this plan, which is how three stale references survived"
  f30_bad=1
fi

# Floor, per the recurring vacuous-pass lesson: a derivation that collapses to nothing
# would otherwise sweep clean and prove nothing.
if [ "$f30_count" -lt 10 ]; then
  fail "F30: subject set is only $f30_count files — the derivation collapsed, so a pass here would be vacuous"
  f30_bad=1
fi

[ "$f30_bad" -eq 0 ] && pass "F30: neither stale string survives in any of $f30_count tracked files ($f30_skipped skipped: this plan's own records and spec)"
# ===========================================================================
# PH5-001 / acceptance row A1: lint-registry.md is the ONLY file that states
# LINT rule text.
#
# The registry declares itself the single source of truth and nothing enforced it.
# Every one of the 18 rules had drifted into a second wording, and LINT-17/18 had
# drifted into a second MEANING. Harmless while a prose score carried the Phase 5
# gate; load-bearing once LINT verdicts ARE the gate
# (docs/specs/phase5-verifier-gate.md).
#
# Formulated as ABSENCE, deliberately. An earlier version of this guard compared
# each restatement against the registry's wording, which required deciding whether
# a given sentence was "a definition" — an intent question, and the species this
# repo has been bitten by repeatedly. Asking instead "does any prose follow a LINT
# id outside the registry?" is a question text matching answers soundly, and it
# makes collisions impossible by construction rather than merely detected.
#
# Bare references are unaffected: "LINT-08 blocks Build" and "all of LINT-01..10
# apply" carry no ':' or '|' delimiter and are not collected. Governing files may
# reference any id freely; they may not restate what it means.
# ===========================================================================
lint_hits=$(mktemp)
lint_bad=0
LINT_REGISTRY="docs/planning-techniques/lint-registry.md"

# Subject set: tracked .md that GOVERNS behaviour, minus the registry itself.
# Files under docs/plans/ are records of audits that already ran; they restate the
# rule text in force at the time, and rewriting them to satisfy a guard would
# falsify a record rather than fix a defect. The split is structural (governing
# document vs. historical record), never per-file, and the floors below prove the
# set did not quietly collapse.
#
# One awk process over the set. An earlier shell-loop version spawned ~5 processes
# per matched line and blew the suite's time budget on Windows; the extraction is
# identical, the cost is not.
lint_extract() {
  xargs -0 awk '
    {
      line = $0
      pos  = 1
      while (1) {
        rest = substr(line, pos)
        if (! match(rest, /LINT-[0-9]+[ \t]*[:|]/)) break
        id = substr(rest, RSTART, RLENGTH)
        sub(/[ \t]*[:|]$/, "", id)

        after = substr(rest, RSTART + RLENGTH)
        p     = index(after, "|")
        desc  = (p > 0) ? substr(after, 1, p - 1) : after

        # Verdict placeholders are not prose.
        gsub(/\[[Pp][Aa][Ss][Ss][^]]*\]/, "", desc)
        gsub(/^[ \t]+/, "", desc); gsub(/[ \t]+$/, "", desc)

        norm = tolower(desc)
        gsub(/[^a-z0-9]+/, " ", norm)
        gsub(/^ +/, "", norm); gsub(/ +$/, "", norm)

        # Three words separates real rule text from a bare "LINT-01 |" table cell.
        if (split(norm, w, " ") >= 3) print FILENAME "\t" id "\t" desc "\t" norm

        pos += RSTART + RLENGTH - 1
      }
    }
  ' 2>/dev/null
}

lint_reg=$(mktemp)
printf '%s\0' "$LINT_REGISTRY" | lint_extract | sort -u > "$lint_reg"

# Floor 1: the extractor must find the registry's own definitions. If the pattern
# stops matching, every other file goes silent too and the guard passes vacuously —
# the recurring "answer does not depend on the truth" species.
registry_defs=$(cut -f2 "$lint_reg" | sort -u | grep -c . || true)
if [ "${registry_defs:-0}" -lt 15 ]; then
  fail "PH5-001: extractor found only ${registry_defs:-0} rule ids in $LINT_REGISTRY — the pattern collapsed, so a clean sweep elsewhere would be vacuous"
  lint_bad=1
fi

# --- A1a: machine-read files carry ids, never rule text -------------------
# commands/ and agents/ are loaded into agent context. Text that drifts here is
# text a judge actually applies, so nothing may follow a LINT id but the id.
git ls-files -z 'commands/*.md' 'agents/*.md' 2>/dev/null | lint_extract | sort -u > "$lint_hits"

for must in commands/plan.md agents/plan-auditor.md; do
  git ls-files -z 'commands/*.md' 'agents/*.md' 2>/dev/null | tr '\0' '\n' | grep -qxF "$must" \
    || { fail "PH5-001a: $must is not in the machine-read set — the derivation is wrong, not the repo clean"; lint_bad=1; }
done

mr_count=$(grep -c . "$lint_hits" || true)
if [ "${mr_count:-0}" -gt 0 ]; then
  lint_bad=1
  fail "PH5-001a: $mr_count restatement(s) of LINT rule text in machine-read files (commands/, agents/) — these must carry bare ids only:"
  awk -F'\t' '{ printf "           %s  %s: %s\n", $1, $2, substr($3, 1, 60) }' "$lint_hits" | head -25
  [ "$mr_count" -gt 25 ] && echo "           ... $(( mr_count - 25 )) more"
fi

# --- A1b: human-facing docs may restate, but only verbatim ----------------
# METHODOLOGY.md and the technique docs explain the rules to a reader, so bare ids
# would make them useless. They may restate — the restatement must be one the
# registry actually contains. This is equality, not intent: no judgement about
# whether a sentence "expresses" a rule, only whether it matches one.
lint_hf=$(mktemp)
git ls-files -z '*.md' 2>/dev/null \
  | grep -zv '^docs/plans/' \
  | grep -zv '^commands/' \
  | grep -zv '^agents/' \
  | grep -zv "^${LINT_REGISTRY}\$" \
  | lint_extract | sort -u > "$lint_hf"

git ls-files -z '*.md' 2>/dev/null | grep -zv '^docs/plans/' | grep -zv '^commands/' \
  | grep -zv '^agents/' | grep -zv "^${LINT_REGISTRY}\$" | tr '\0' '\n' | grep -qxF 'METHODOLOGY.md' \
  || { fail "PH5-001b: METHODOLOGY.md fell outside the human-facing set — the exclusions grew past their intent"; lint_bad=1; }

lint_drift=$(mktemp)
awk -F'\t' '
  NR == FNR { reg[$2 "\t" $4] = 1; next }
  ! (($2 "\t" $4) in reg) { print $1 "\t" $2 "\t" $3 }
' "$lint_reg" "$lint_hf" > "$lint_drift"

hf_count=$(grep -c . "$lint_drift" || true)
if [ "${hf_count:-0}" -gt 0 ]; then
  lint_bad=1
  fail "PH5-001b: $hf_count restatement(s) in human-facing docs do not match any wording in $LINT_REGISTRY:"
  awk -F'\t' '{ printf "           %s  %s: %s\n", $1, $2, substr($3, 1, 60) }' "$lint_drift" | head -25
  [ "$hf_count" -gt 25 ] && echo "           ... $(( hf_count - 25 )) more"
fi

[ "$lint_bad" -eq 0 ] && pass "PH5-001: $registry_defs rules defined in $LINT_REGISTRY; 0 rule text in machine-read files, $(grep -c . "$lint_hf" || true) doc restatement(s) all verbatim"
rm -f "$lint_hits" "$lint_reg" "$lint_hf" "$lint_drift"

# ===========================================================================
# PH5-002 / acceptance row A1: rule COUNTS live only in the registry.
#
# Rule text was not the only thing that drifted. Four different Phase 5 counts were
# in print at once — 14 in commands/plan.md, 14 and 15 in agents/plan-auditor.md,
# 16 in the registry, 15 in METHODOLOGY.md — plus a fifth ("13 in Lite mode") in the
# same METHODOLOGY sentence. A count is a claim about the rule SET, so it belongs
# where the set is defined.
#
# Decidable by absence, like PH5-001: a count is an integer bound to the word
# "rule(s)", or the denominator of an "N/M passed" tally. LINT-NN tokens are stripped
# first so the ids' own digits cannot be read as counts. No question is asked about
# what any sentence means.
# ===========================================================================
lint_counts=$(mktemp)
count_bad=0

# One scanner, used for both the sweep and its floor. Two copies of this pattern is
# exactly the drift the guard exists to prevent, and the first draft had already
# diverged: the floor stripped only LINT ids while the sweep stripped five token
# classes, so the two disagreed about whether "Phase 5 lint rules" was a count.
count_scan() {   # NUL-separated paths on stdin -> "file:line<TAB>text"
  xargs -0 awk '
    function strip(s) {
      # An identifier that merely contains a digit is not a count. "Phase 5 lint
      # rules" names a phase; "14 lint rules" claims a set size. Removing the
      # identifier tokens first keeps that distinction mechanical, not interpretive.
      gsub(/LINT-[0-9]+/, "", s)
      gsub(/PH5-[0-9]+/, "", s)
      gsub(/[Pp]hase[ \t]+[0-9]+/, "", s)
      gsub(/[Ll]ayer[ \t]+[0-9]+/, "", s)
      gsub(/[Ww]ave[ \t]+[0-9]+/, "", s)
      return s
    }
    {
      probe = strip($0)
      if (probe ~ /[0-9]+[ \t]*(lint[ \t]*)?rules?[^a-z]/ ||
          probe ~ /\/[0-9]+[ \t]+passed/) {
        printf "%s:%d\t%s\n", FILENAME, FNR, substr($0, 1, 88)
      }
    }
  ' 2>/dev/null
}

git ls-files -z '*.md' 2>/dev/null \
  | grep -zv '^docs/plans/' \
  | grep -zv "^${LINT_REGISTRY}\$" \
  | count_scan | sort -u > "$lint_counts"

# Floor, inverted: assert the pattern STILL FIRES on the one file allowed to state
# counts. A sweep for a forbidden pattern everywhere-but-here cannot otherwise tell
# "nothing to find" from "my pattern broke" — the two produce identical output.
count_probe=$(printf '%s\0' "$LINT_REGISTRY" | count_scan | grep -c . || true)
if [ "${count_probe:-0}" -lt 1 ]; then
  fail "PH5-002: the count pattern no longer fires on $LINT_REGISTRY, which states counts by design — the probe is broken, so a clean sweep elsewhere is vacuous"
  count_bad=1
fi

cnt=$(grep -c . "$lint_counts" || true)
if [ "${cnt:-0}" -gt 0 ]; then
  count_bad=1
  fail "PH5-002: $cnt lint rule count(s) stated outside $LINT_REGISTRY:"
  awk -F'\t' '{ printf "           %s  %s\n", $1, $2 }' "$lint_counts" | head -20
fi

[ "$count_bad" -eq 0 ] && pass "PH5-002: no lint rule count outside $LINT_REGISTRY (probe fires on $count_probe registry line(s))"
rm -f "$lint_counts"

# ===========================================================================
# PH5-013 / acceptance row A3: the judge is never told what passing costs.
#
# agents/plan-auditor.md used to carry the band table verbatim — "Interpret: 32-40
# = Green, 24-31 = Yellow" — so the evaluator knew the exact total the plan needed.
# Naming the desired outcome to a grader is the sycophancy channel: an instruction-
# following model produces a justification for the wanted verdict rather than a
# disinterested measurement, and ambiguity resolves toward passing.
#
# The judge keeps the 1-5 dimension anchors (it still has to score) and may know the
# scale runs to 40. What it may not know is where the cut is. So this forbids band
# WORDS and explicit pass marks, not scoring vocabulary generally.
#
# Non-vacuity is established by self-test rather than by a floor over the repo: the
# pattern is run against a literal known-positive and a literal known-negative every
# time, so "no hits" cannot be produced by a broken regex.
# ===========================================================================
band_bad=0
band_re='[0-9]+[ \t]*-[ \t]*[0-9]+[ \t]*=?[ \t]*(GREEN|YELLOW|ORANGE|RED|Green|Yellow|Orange|Red)|[0-9]+/40|>=[ \t]*3[0-9]'

if ! printf '%s\n' 'Interpret: 32-40 = Green, 24-31 = Yellow, 16-23 = Orange' | grep -qE "$band_re"; then
  fail "PH5-013: band pattern fails its own known-positive — a clean sweep would be vacuous"
  band_bad=1
fi
if printf '%s\n' 'Rate each dimension 1-5 and give reasoning before the score.' | grep -qE "$band_re"; then
  fail "PH5-013: band pattern matches its known-negative — it would flag ordinary scoring vocabulary"
  band_bad=1
fi

# Judge-visible set. Anything the evaluator reads as instructions belongs here.
JUDGE_FILES="agents/plan-auditor.md"
for jf in $JUDGE_FILES; do
  if [ ! -f "$jf" ]; then
    fail "PH5-013: judge file $jf not found — the subject set is wrong, not the repo clean"
    band_bad=1
    continue
  fi
  hits=$(grep -nE "$band_re" "$jf" || true)
  if [ -n "$hits" ]; then
    band_bad=1
    fail "PH5-013: $jf discloses the pass threshold to the evaluator:"
    printf '%s\n' "$hits" | sed 's/^/           /' | head -10
  fi
done

[ "$band_bad" -eq 0 ] && pass "PH5-013: no pass threshold or score band disclosed in the judge-visible set ($JUDGE_FILES)"

# ===========================================================================
# PH5-010 / acceptance row A3: audit criteria are not in the generator's reach.
#
# commands/plan.md is what the Phase 4 generator reads. It carried a full copy of
# the scoring rubric and the gap matrices — the 1-5 anchors, the Scenario Matrix with
# its eight scenarios named, the Cross-Cutting Sweep with its concerns named. A
# generator holding that list writes sections matching the list, which is compliance
# with a checklist rather than thought about the plan in front of it.
#
# The copy was also DIVERGENT, the same species PH5-001 fixed for lint rules: plan.md
# scored 3 as "Adequate, notable gaps (section exists but incomplete)" while
# plan-auditor.md scored it "Section exists but has notable gaps. Stated without
# evidence." Two rubrics, one dimension.
#
# Checked in both directions. Absence alone would be satisfied by deleting the
# criteria outright, so the judge-side presence floor is what makes this a MOVE.
# ===========================================================================
crit_bad=0
anchor_re='^[[:space:]]*[1-5][[:space:]]*=[[:space:]]*[A-Z]'
scen_re='\| *Scenario *\| *Planned\?'
conc_re='\| *Concern *\| *Addressed\?'

# Self-tests: the anchor pattern must fire on a real anchor and stay quiet on prose
# that merely contains a digit and an equals sign.
if ! printf '%s\n' '  5 = Thorough, no gaps (evidence: direct quotes)' | grep -qE "$anchor_re"; then
  fail "PH5-010: anchor pattern fails its known-positive — a clean sweep would be vacuous"
  crit_bad=1
fi
if printf '%s\n' 'Set iterations = 2 when the loop re-runs.' | grep -qE "$anchor_re"; then
  fail "PH5-010: anchor pattern matches its known-negative — it would flag ordinary prose"
  crit_bad=1
fi

# --- generator side: the criteria must be absent -------------------------
GENERATOR_FILES="commands/plan.md commands/quick-plan.md agents/plan-scaffolder.md"
for gf in $GENERATOR_FILES; do
  [ -f "$gf" ] || { fail "PH5-010: generator file $gf not found — the subject set is wrong, not the repo clean"; crit_bad=1; continue; }
  for probe in "$anchor_re:scoring anchor" "$scen_re:Scenario Matrix criteria" "$conc_re:Cross-Cutting criteria"; do
    re="${probe%:*}"; what="${probe##*:}"
    n=$(grep -cE "$re" "$gf" || true)
    if [ "${n:-0}" -gt 0 ]; then
      crit_bad=1
      fail "PH5-010: $gf exposes $what to the generator ($n occurrence(s)) — belongs in the judge-visible set only"
    fi
  done
done

# --- judge side: the criteria must still exist ---------------------------
# Without this the guard would go green on a repo that had simply lost its rubric.
ja=$(grep -cE '^[[:space:]]*[1-5]/5:' agents/plan-auditor.md || true)
if [ "${ja:-0}" -lt 5 ]; then
  crit_bad=1
  fail "PH5-010: agents/plan-auditor.md holds only ${ja:-0} per-level scoring anchors — the criteria were deleted, not moved"
fi
for probe in "$scen_re:Scenario Matrix" "$conc_re:Cross-Cutting Sweep"; do
  re="${probe%:*}"; what="${probe##*:}"
  if ! grep -qE "$re" agents/plan-auditor.md; then
    crit_bad=1
    fail "PH5-010: agents/plan-auditor.md no longer defines the $what — the criteria were deleted, not moved"
  fi
done

[ "$crit_bad" -eq 0 ] && pass "PH5-010: audit criteria absent from the generator set, present in the judge set ($ja anchors + both matrices)"

# ===========================================================================
# PH5-011 / acceptance row A4: the judge's forbidden inputs are enumerated.
#
# Isolation that lives only in the calling command is isolation nobody can audit.
# The evaluator's own file has to state what it must not read, so the constraint
# travels with the agent and a reviewer can check it in one place.
#
# This is a PRESENCE check, which is the class this repo has been burned by:
# "the file instructs X" is an intent question, and a keyword probe for it stays
# green after the instruction is deleted because the surrounding prose still
# mentions the keyword. Two things make it decidable here:
#
#   1. The block is delimited (<forbidden_inputs>...</forbidden_inputs>), so its
#      presence is structural, not inferred from vocabulary.
#   2. Each entry is anchored on a SENTENCE-INITIAL imperative, "NEVER read:".
#      That is negation-proof by construction — you cannot weaken the rule to
#      "do not never read" without destroying the anchor the count depends on.
#
# The count floor is what stops an empty block from passing.
# ===========================================================================
fi_bad=0
FI_FILE="agents/plan-auditor.md"
fi_open=$(grep -c '^<forbidden_inputs>$' "$FI_FILE" || true)
fi_close=$(grep -c '^</forbidden_inputs>$' "$FI_FILE" || true)
fi_rules=$(grep -cE '^NEVER read: ' "$FI_FILE" || true)

# Self-test: the anchor must fire on the real form and stay quiet on a negated or
# indented variant, so a weakened rule cannot be counted as a rule.
if ! printf '%s\n' 'NEVER read: the generation transcript' | grep -qE '^NEVER read: '; then
  fail "PH5-011: forbidden-input anchor fails its known-positive — a pass would be vacuous"
  fi_bad=1
fi
if printf '%s\n' '  You should never read the transcript, generally' | grep -qE '^NEVER read: '; then
  fail "PH5-011: forbidden-input anchor matches hedged prose — it would count a non-rule"
  fi_bad=1
fi

if [ "${fi_open:-0}" -ne 1 ] || [ "${fi_close:-0}" -ne 1 ]; then
  fail "PH5-011: $FI_FILE has no delimited <forbidden_inputs> block (open=$fi_open close=$fi_close)"
  fi_bad=1
elif [ "${fi_rules:-0}" -lt 5 ]; then
  fail "PH5-011: $FI_FILE enumerates only ${fi_rules:-0} forbidden inputs — the five isolation-critical ones are transcript, rationale, prior scores, threshold, author identity"
  fi_bad=1
fi

[ "$fi_bad" -eq 0 ] && pass "PH5-011: $FI_FILE enumerates $fi_rules forbidden inputs in a delimited block"

# ===========================================================================
# PH5-012 / acceptance row A4: every audit iteration gets an unused judge.
#
# The revision loop said only "Re-run the audit on the revised spec". Re-running it
# in the same session hands iteration 2 an evaluator that already published a number
# for iteration 1 — it is now checking its own prior judgement, and the cheapest
# consistent story is that the revision fixed what it said was broken. Anchoring on
# a stale score is the whole reason the loop caps at 2 and still drifts.
#
# Stated on both sides so neither alone is load-bearing: the command must spawn a
# new instance, and the agent must refuse prior scores (PH5-011 rule 3). Anchored on
# a sentence-initial imperative for the same negation-proofing reason as PH5-011.
# ===========================================================================
iso_bad=0
ISO_FILE="commands/plan.md"
iso_re='^SPAWN A NEW plan-auditor INSTANCE'

if ! printf '%s\n' 'SPAWN A NEW plan-auditor INSTANCE for every audit iteration.' | grep -qE "$iso_re"; then
  fail "PH5-012: respawn anchor fails its known-positive — a pass would be vacuous"
  iso_bad=1
fi
if printf '%s\n' 'Consider whether to spawn a new plan-auditor instance if context is stale.' | grep -qE "$iso_re"; then
  fail "PH5-012: respawn anchor matches hedged prose — it would count a suggestion as a rule"
  iso_bad=1
fi

iso_n=$(grep -cE "$iso_re" "$ISO_FILE" || true)
if [ "${iso_n:-0}" -lt 1 ]; then
  fail "PH5-012: $ISO_FILE does not require a new plan-auditor instance per iteration — re-auditing in session lets iteration 2 anchor on iteration 1's score"
  iso_bad=1
fi

# Cross-side floor: the command's respawn is worth little if the agent will happily
# read the prior audit anyway. That rule is PH5-011's third entry; assert it is still
# there, so removing it cannot leave this guard green.
if ! grep -qE '^NEVER read: scores, verdicts or audit\.md files from a previous iteration' agents/plan-auditor.md; then
  fail "PH5-012: agents/plan-auditor.md no longer refuses prior-iteration scores — the respawn alone does not isolate the judge"
  iso_bad=1
fi

[ "$iso_bad" -eq 0 ] && pass "PH5-012: each audit iteration spawns a fresh judge, and the agent refuses prior-iteration scores"

# ===========================================================================
# PH5-014 / acceptance row A5: the verdict schema carries no total, and puts
# evidence before the verdict.
#
# Two separate properties, both structural.
#
# NO TOTAL: if the judge can emit a total it can aim at one. Verdicts are per
# criterion; the caller adds them up. A schema field is the thing that makes this
# enforceable rather than aspirational — there is nowhere to put the number.
#
# FIELD ORDER: a schema that serialises verdict first gets a verdict conditioned on
# nothing, and the evidence that follows is assembled to support it. Emitting
# evidence, then reasoning, then verdict locks the finding before the judgement.
# Order within a JSON example is decidable by line position, so this is checkable
# rather than merely requested.
# ===========================================================================
vs_bad=0
VS_FILE="agents/plan-auditor.md"
vs_block=$(sed -n '/^<verdict_schema>$/,/^<\/verdict_schema>$/p' "$VS_FILE" 2>/dev/null)
forbidden_key='"(total|total_score|points|points_awarded|pass_threshold|overall)"[[:space:]]*:'

if ! printf '%s\n' '  "total_score": 34,' | grep -qE "$forbidden_key"; then
  fail "PH5-014: forbidden-key pattern fails its known-positive — a pass would be vacuous"
  vs_bad=1
fi
if printf '%s\n' '  "criterion_id": "LINT-03",' | grep -qE "$forbidden_key"; then
  fail "PH5-014: forbidden-key pattern matches an ordinary field — it would reject a valid schema"
  vs_bad=1
fi

if [ -z "$vs_block" ]; then
  fail "PH5-014: $VS_FILE has no delimited <verdict_schema> block"
  vs_bad=1
else
  for k in '"verdict"' '"evidence"' 'MET' 'UNMET' 'N_A'; do
    printf '%s\n' "$vs_block" | grep -qF "$k" \
      || { fail "PH5-014: <verdict_schema> does not mention $k"; vs_bad=1; }
  done

  offending=$(printf '%s\n' "$vs_block" | grep -nE "$forbidden_key" || true)
  if [ -n "$offending" ]; then
    vs_bad=1
    fail "PH5-014: <verdict_schema> gives the judge somewhere to put a total:"
    printf '%s\n' "$offending" | sed 's/^/           /'
  fi

  # Field order: evidence < reasoning < verdict, by first occurrence in the block.
  ln_ev=$(printf '%s\n' "$vs_block" | grep -nF '"evidence"'  | head -1 | cut -d: -f1)
  ln_rs=$(printf '%s\n' "$vs_block" | grep -nF '"reasoning"' | head -1 | cut -d: -f1)
  ln_vd=$(printf '%s\n' "$vs_block" | grep -nF '"verdict"'   | head -1 | cut -d: -f1)
  if [ -z "$ln_ev" ] || [ -z "$ln_rs" ] || [ -z "$ln_vd" ]; then
    fail "PH5-014: <verdict_schema> is missing one of evidence/reasoning/verdict, so order cannot be checked"
    vs_bad=1
  elif [ "$ln_ev" -ge "$ln_rs" ] || [ "$ln_rs" -ge "$ln_vd" ]; then
    fail "PH5-014: <verdict_schema> orders evidence=$ln_ev reasoning=$ln_rs verdict=$ln_vd — must be evidence, then reasoning, then verdict, or the verdict is rationalised rather than derived"
    vs_bad=1
  fi
fi

[ "$vs_bad" -eq 0 ] && pass "PH5-014: verdict schema has no total field and locks evidence before verdict"

# ===========================================================================
# PH5-021 / PH5-022 / acceptance row A22: the records are emitted and kept.
#
# The validator is worthless if its input never exists. PH5-014 defines the record
# shape; these two require the auditor to WRITE the records and the caller to COMMIT
# them, so an audit leaves behind something a later reader can re-check.
#
# Matched as EXACT FULL LINES with grep -qxF, not as regexes. That is a deliberate
# correction: the F06 invocation guard used a regex whose known-positive was invented
# alongside the pattern, so the self-test passed while every real invocation went
# unmatched. A known-positive authored by the same author at the same moment shares
# the blind spot it exists to catch. Literal equality removes the gap entirely —
# the pattern IS the artifact text, so the two cannot diverge and no self-test is
# needed to prove they agree.
#
# Both lines open with a sentence-initial imperative, so they stay negation-proof:
# the rule cannot be softened without destroying the string the check matches.
# ===========================================================================
emit_bad=0
PH5_021_LINE='WRITE one evidence record per criterion to evidence/{criterion_id}.json before reporting anything.'
PH5_022_LINE='COMMIT the evidence directory together with audit.md. An audit whose evidence is not committed did not happen.'

if ! grep -qxF "$PH5_021_LINE" agents/plan-auditor.md; then
  fail "PH5-021: agents/plan-auditor.md does not require emitting evidence records — the validator has no input, so the gate cannot open"
  emit_bad=1
fi
if ! grep -qxF "$PH5_022_LINE" commands/plan.md; then
  fail "PH5-022: commands/plan.md does not require committing the evidence directory — evidence that is not committed cannot be re-checked later"
  emit_bad=1
fi

[ "$emit_bad" -eq 0 ] && pass "PH5-021/022: evidence records are emitted by the auditor and committed by the caller"

# ===========================================================================
# PH5-041 / acceptance row A13: the gate expression contains no score term.
#
# This is the point of the whole change. Phase 5 used to read
# "IF score >= 32 AND gap-checked = YES -> ready to build", authorising passage on
# a number the audited model assigned to itself. The gate now keys on things that
# can be re-derived: the canary was found, evidence survived re-checking, every
# applicable criterion is MET or N_A, and infra gaps are zero.
#
# Scoped to a delimited block rather than banned outright, because the score is
# still legitimately used elsewhere — it gates the WAIVER (PH5-060), and reporting
# it is fine. The asymmetry is deliberate: a gameable signal is safe in the
# direction that ADDS friction (blocking a review waiver) and unsafe in the one
# that removes it (authorising a build). Only the gate expression is policed here.
# ===========================================================================
gate_bad=0
GATE_LINE='PASS = CANARY_OK AND EVIDENCE_OK AND VERIFIED AND INFRA_OK'
gate_block=$(sed -n '/^<gate_expression>$/,/^<\/gate_expression>$/p' commands/plan.md 2>/dev/null)

if [ -z "$gate_block" ]; then
  fail "PH5-041: commands/plan.md has no delimited <gate_expression> block"
  gate_bad=1
else
  printf '%s\n' "$gate_block" | grep -qxF "$GATE_LINE" \
    || { fail "PH5-041: <gate_expression> does not state the verifier-first PASS expression verbatim"; gate_bad=1; }

  # No score term inside the gate. Checked case-insensitively and including the
  # numeric forms, so "score", "34/40" and ">= 32" are all refused.
  offend=$(printf '%s\n' "$gate_block" | grep -nEi 'score|[0-9]+/40|>=[[:space:]]*[0-9]{2}' || true)
  if [ -n "$offend" ]; then
    gate_bad=1
    fail "PH5-041: <gate_expression> still keys on a score:"
    printf '%s\n' "$offend" | sed 's/^/           /' | head -6
  fi
fi

# The superseded form must be gone, not merely superseded by a newer block below it.
if grep -qE '^IF score (>=|<) [0-9]+' commands/plan.md; then
  gate_bad=1
  fail "PH5-041: the score-based gate branch is still present in commands/plan.md"
  grep -nE '^IF score (>=|<) [0-9]+' commands/plan.md | sed 's/^/           /' | head -4
fi

[ "$gate_bad" -eq 0 ] && pass "PH5-041: the gate keys on canary, evidence, verdicts and infra — not on a score"

# ===========================================================================
# PH5-040 / acceptance row A12: revision feedback names defects, not dimensions.
#
# The loop used to feed back "specific findings with dimension references", which
# hands the generator the scoring structure Wave 1 removed from its view. Telling it
# "Dimension 4 scored 2" invites text shaped like dimension 4; telling it "LINT-03
# UNMET: Phase 2 migration has no rollback step" names a defect it can actually fix.
# ===========================================================================
fb_bad=0
fb_block=$(sed -n '/^<revision_feedback>$/,/^<\/revision_feedback>$/p' commands/plan.md 2>/dev/null)
fb_forbidden='dimension|score|/40|points|threshold|GREEN|YELLOW|ORANGE'

if ! printf '%s\n' 'Dimension 4 scored 2 — improve rollback coverage.' | grep -qEi "$fb_forbidden"; then
  fail "PH5-040: forbidden-vocabulary pattern fails its known-positive"
  fb_bad=1
fi
if printf '%s\n' 'LINT-03 UNMET: Phase 2 migration has no rollback step. Location: spec.md:142.' | grep -qEi "$fb_forbidden"; then
  fail "PH5-040: forbidden-vocabulary pattern matches a well-formed defect message"
  fb_bad=1
fi

if [ -z "$fb_block" ]; then
  fail "PH5-040: commands/plan.md has no delimited <revision_feedback> block defining what goes back to the generator"
  fb_bad=1
else
  offend=$(printf '%s\n' "$fb_block" | grep -nEi "$fb_forbidden" || true)
  if [ -n "$offend" ]; then
    fb_bad=1
    fail "PH5-040: <revision_feedback> leaks scoring vocabulary back to the generator:"
    printf '%s\n' "$offend" | sed 's/^/           /' | head -6
  fi
fi

[ "$fb_bad" -eq 0 ] && pass "PH5-040: revision feedback carries defects and locations, no scoring vocabulary"

# ===========================================================================
# PH5-060 / row A14: the waiver is conditional, and DOES use the score.
#
# The mirror image of PH5-041, and the reason that guard is scoped to a block
# rather than banning the word outright. The score cannot let a plan pass, but a
# borderline score can remove the owner's ability to skip human review. Same
# number, opposite trust: safe in the direction that adds friction, unsafe in the
# one that removes it. A guard that banned "score" file-wide would have forced an
# exemption here within one wave.
#
# The guard body checks the block STATES all three conditions, not that it merely
# mentions the word "waiver" — a mention survives the rule being deleted.
# ===========================================================================
wv_bad=0
wv_block=$(sed -n '/^<waiver_condition>$/,/^<\/waiver_condition>$/p' commands/plan.md 2>/dev/null)
if [ -z "$wv_block" ]; then
  fail "PH5-060: commands/plan.md has no delimited <waiver_condition> block"
  wv_bad=1
else
  for term in 'infra_gaps == 0' 'score >= 35' 'canary_found == true'; do
    printf '%s\n' "$wv_block" | grep -qF "$term" \
      || { fail "PH5-060: <waiver_condition> does not require: $term"; wv_bad=1; }
  done
fi
[ "$wv_bad" -eq 0 ] && pass "PH5-060: review waiver is blocked by infra gaps, a borderline score, or a missed canary"

# ===========================================================================
# PH5-050 / row A15: something looks for what the criteria do not cover.
#
# Every other mechanism makes the judge honest ABOUT the rubric. None of them can
# notice that the rubric is incomplete — a plan can satisfy every criterion and
# still fail for a reason no criterion names. This is the only check on that, and
# it deliberately never gates: its output is a proposed new rule, not a verdict.
# ===========================================================================
hol_bad=0
HOL_LINE='RUN one additional judge with no rubric, no criterion list, and no dimension names.'
grep -qxF "$HOL_LINE" commands/plan.md \
  || { fail "PH5-050: commands/plan.md does not run a rubric-free pass — nothing checks the criteria for completeness"; hol_bad=1; }
[ -f docs/planning-techniques/lint-candidates.md ] \
  || { fail "PH5-050: docs/planning-techniques/lint-candidates.md missing — unmapped findings have nowhere to land"; hol_bad=1; }
[ "$hol_bad" -eq 0 ] && pass "PH5-050: a rubric-free pass runs and its unmapped findings land in lint-candidates.md"

# ===========================================================================
# PH5-051 / row A15: score distribution is retained.
#
# The score no longer gates, but it is still the cheapest detector of a gate being
# gamed: a cluster of totals sitting just above any historical threshold is the
# signature of threshold-aiming. Keeping the series costs nothing and is the only
# way to see that pattern at all.
# ===========================================================================
grep -qF 'score_history' commands/plan.md \
  && pass "PH5-051: audit scores are retained as a series for distribution monitoring" \
  || fail "PH5-051: commands/plan.md does not record score_history — threshold-aiming would be invisible"

# ===========================================================================
# 16R. Root-doc conformance (§9.2, class G) — the root-level docs.
#
# The per-plugin core pass sweeps each plugin's README and GUIDE; the files at
# the repo root (README, METHODOLOGY, CONTRIBUTING) belong to no plugin, so the
# same claims are policed here. The subject set is DERIVED — every tracked
# root-level .md except the CHANGELOG, which describes old versions truthfully
# in the past tense — with a floor so the derivation cannot collapse silently.
# ===========================================================================
echo ""
echo "--- Root-doc conformance (§9.2) ---"

DOC_FILES=$(git ls-files '*.md' 2>/dev/null | grep -v '/' | grep -v '^CHANGELOG\.md$' | tr '\n' ' ')
doc_count=$(echo $DOC_FILES | wc -w | tr -d ' ')
if [ "$doc_count" -lt 2 ]; then
  fail "§9.2: derived only $doc_count root-level doc(s) — the derivation is broken, not the docs clean"
fi

# claim_absent <label> <extended-regex> — the claim must appear NOWHERE, except on a
# line that explicitly marks it as removed, historical, or a defect.
claim_absent() {
  local label=$1 re=$2 hits
  hits=$(grep -rniE "$re" $DOC_FILES 2>/dev/null \
         | grep -viE 'no longer|removed in|was removed|reversed in|until 5\.0\.0|earlier revision|previously|used to|old design|defect|not used at all|deleted in')
  if [ -n "$hits" ]; then
    fail "§9.2: $label — still asserted as current: $(echo "$hits" | head -1 | cut -c1-110)"
    return 1
  fi
  pass "§9.2: $label"
}

conf_bad=0
claim_absent "root docs: no zero/no required dependencies claim" \
  '(zero|no) required dependenc|zero-dependency (plugin|design is)|dependencies: *none|\*\*required:\*\* *none' || conf_bad=1
claim_absent "root docs: no jq/grep+sed fallback ladder as current" \
  'falls? back to (grep|`grep`)|jq with grep|grep\+sed fallback|tries `?jq`? first|jq is optional' || conf_bad=1
claim_absent "root docs: no hooks-inline-in-plugin.json claim" \
  'hooks are (defined |declared )?inline|inline hook definitions|inline in .?plugin\.json' || conf_bad=1
claim_absent "root docs: no reference to a deleted .sh handler" \
  'scripts/dg-[a-z-]+\.sh' || conf_bad=1
claim_absent "root docs: no untrue force-with-lease claim" \
  'does not block .?--force-with-lease.? \(untrue\)' || conf_bad=1

# F04's two root-level halves, mirrored from core §9: the root docs are read by
# the same users and can reintroduce the same false claims.
root_auto=$(grep -ln "picks up changes automatically" $DOC_FILES 2>/dev/null | head -1)
if [ -n "$root_auto" ]; then
  fail "F04: false auto-update claim present in root doc $root_auto"
else
  pass "F04: no 'picks up changes automatically' claim in root docs"
fi
root_bare=$(grep -nE "/plugin install (deepgrade|deepgrade-readiness|deepgrade-audit|deepgrade-guard)([[:space:]]|\$)" $DOC_FILES 2>/dev/null | head -1)
if [ -n "$root_bare" ]; then
  fail "F04: unqualified install command in a root doc (missing @deepgrade-marketplace): $root_bare"
else
  pass "F04: all install commands in root docs are marketplace-qualified"
fi

# ===========================================================================
# RESULTS (part subtotal — the dispatcher owns the anchored Results line)
# ===========================================================================
echo "==========================================="
echo "Subtotal (repo): $PASS passed, $FAIL failed, $WARN warnings"
echo "==========================================="

if [ -n "${DG_COUNTS_FILE:-}" ]; then
  printf 'repo %s %s\n' "$PASS" "$FAIL" >> "$DG_COUNTS_FILE"
fi

if [ "$FAIL" -gt 0 ]; then
  exit 1
else
  exit 0
fi

#!/usr/bin/env bash
# Layer 4: Behavioral Smoke Tests
# These tests require Claude Code agent invocation and are run periodically.
# Run from plugin root: bash tests/layer4-behavioral-smoke.sh
#
# USAGE:
#   bash tests/layer4-behavioral-smoke.sh [--dry-run]
#   --dry-run: Just list tests without running them (for CI documentation)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PASS=0; FAIL=0; SKIP=0

pass() { echo "[PASS] $1"; PASS=$((PASS + 1)); }
fail() { echo "[FAIL] $1"; FAIL=$((FAIL + 1)); }
skip() { echo "[SKIP] $1"; SKIP=$((SKIP + 1)); }

echo "=== DeepGrade Plugin: Layer 4 - Behavioral Smoke Tests ==="
echo ""

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

# -----------------------------------------------
# Test B1: help.md produces expected command sections
# -----------------------------------------------
echo "--- B1: Help Command Structure ---"
HELP_FILE="$PLUGIN_ROOT/commands/help.md"
if [[ -f "$HELP_FILE" ]]; then
    # Check required sections exist in help.md
    SECTIONS=("Planning" "Quick Shortcuts" "Readiness Scan" "Codebase Audit" "Codebase Monitoring" "Documentation" "Utility")
    ALL_FOUND=true
    for section in "${SECTIONS[@]}"; do
        if ! grep -qi "$section" "$HELP_FILE"; then
            fail "B1: help.md missing section: $section"
            ALL_FOUND=false
        fi
    done
    $ALL_FOUND && pass "B1: help.md has all required sections (${#SECTIONS[@]})"

    # Count commands listed vs command files that exist
    CMD_FILES=$(find "$PLUGIN_ROOT/commands" -name "*.md" ! -name "help.md" | wc -l | tr -d ' ')
    CMD_LISTED=$(grep -c "/deepgrade:" "$HELP_FILE" | head -1 || echo 0)
    # Commands in help should reference actual command files
    MISSING_REFS=0
    while IFS= read -r CMD_NAME; do
        [[ -z "$CMD_NAME" ]] && continue
        # Resolve against BOTH user-addressable surfaces. F30 replaced
        # commands/doc.md with the documentation skill, and a skill is addressed the
        # same way (`/plugin:name`), so a command-only check would reject a working
        # reference. Widened, not relaxed — an unresolvable name still fails.
        if [[ ! -f "$PLUGIN_ROOT/commands/$CMD_NAME.md" ]] \
           && [[ ! -f "$PLUGIN_ROOT/skills/$CMD_NAME/SKILL.md" ]]; then
            fail "B1: help.md references /deepgrade:$CMD_NAME but it resolves to neither a command nor a skill"
            MISSING_REFS=$((MISSING_REFS + 1))
        fi
    done < <(grep -o '/deepgrade:[a-z-]*' "$HELP_FILE" | sed 's|/deepgrade:||' | sort -u)
    [[ $MISSING_REFS -eq 0 ]] && pass "B1: every /deepgrade: reference in help.md resolves to a command or a skill"
else
    fail "B1: help.md does not exist"
fi

echo ""

# -----------------------------------------------
# Test B2: Command files have valid frontmatter
# -----------------------------------------------
echo "--- B2: Command Frontmatter Validation ---"
INVALID_FM=0
while IFS= read -r cmd_file; do
    BASENAME=$(basename "$cmd_file")
    # Check starts with ---
    FIRST_LINE=$(head -1 "$cmd_file")
    if [[ "$FIRST_LINE" != "---" ]]; then
        fail "B2: $BASENAME missing frontmatter (no opening ---)"
        INVALID_FM=$((INVALID_FM + 1))
        continue
    fi
    # Check has description field
    # Read up to second --- (frontmatter block)
    FM_BLOCK=$(sed -n '1,/^---$/p' "$cmd_file" | tail -n +2)
    if ! echo "$FM_BLOCK" | grep -qi "description"; then
        fail "B2: $BASENAME frontmatter missing 'description' field"
        INVALID_FM=$((INVALID_FM + 1))
    fi
done < <(find "$PLUGIN_ROOT/commands" -name "*.md")
[[ $INVALID_FM -eq 0 ]] && pass "B2: All command files have valid frontmatter with description"

echo ""

# -----------------------------------------------
# Test B3: Agent files have valid frontmatter
# -----------------------------------------------
echo "--- B3: Agent Frontmatter Validation ---"
INVALID_AG=0
while IFS= read -r agent_file; do
    BASENAME=$(basename "$agent_file")
    FIRST_LINE=$(head -1 "$agent_file")
    if [[ "$FIRST_LINE" != "---" ]]; then
        fail "B3: $BASENAME missing frontmatter (no opening ---)"
        INVALID_AG=$((INVALID_AG + 1))
        continue
    fi
    FM_BLOCK=$(awk '/^---$/{c++;next}c==1' "$agent_file")
    if ! echo "$FM_BLOCK" | grep -qi "name:"; then
        fail "B3: $BASENAME frontmatter missing 'name' field"
        INVALID_AG=$((INVALID_AG + 1))
    fi
    if ! echo "$FM_BLOCK" | grep -qi "description"; then
        fail "B3: $BASENAME frontmatter missing 'description' field"
        INVALID_AG=$((INVALID_AG + 1))
    fi
done < <(find "$PLUGIN_ROOT/agents" -name "*.md")
[[ $INVALID_AG -eq 0 ]] && pass "B3: All agent files have valid frontmatter with name and description"

echo ""

# -----------------------------------------------
# Test B4: Cross-references between commands and agents
# -----------------------------------------------
echo "--- B4: Command-Agent Cross References ---"
# Commands that reference agents should point to existing agent files
BROKEN_REFS=0
while IFS= read -r cmd_file; do
    BASENAME=$(basename "$cmd_file")
    # Look for agent references like "plan-scaffolder", "plan-auditor", etc.
    AGENT_REFS=$(grep -oE '[a-z]+-[a-z]+(-[a-z]+)*' "$cmd_file" | sort -u | while read -r ref; do
        if [[ -f "$PLUGIN_ROOT/agents/$ref.md" ]]; then
            echo "found:$ref"
        fi
    done)
    # Now check for references to agents that DON'T exist
    # This is heuristic — look for patterns like "deploy.*agent" or "spawn.*scanner"
    AGENT_NAMES=$(ls "$PLUGIN_ROOT/agents/" 2>/dev/null | sed 's/.md$//')
done < <(find "$PLUGIN_ROOT/commands" -name "*.md")
# For now, verify key known cross-references
for ref_pair in "quick-plan.md:plan-scaffolder" "quick-audit.md:plan-auditor"; do
    CMD=$(echo "$ref_pair" | cut -d: -f1)
    AGENT=$(echo "$ref_pair" | cut -d: -f2)
    if [[ -f "$PLUGIN_ROOT/commands/$CMD" ]]; then
        if grep -q "$AGENT" "$PLUGIN_ROOT/commands/$CMD"; then
            if [[ -f "$PLUGIN_ROOT/agents/$AGENT.md" ]]; then
                pass "B4: commands/$CMD references agents/$AGENT.md (exists)"
            else
                fail "B4: commands/$CMD references $AGENT but agents/$AGENT.md missing"
                BROKEN_REFS=$((BROKEN_REFS + 1))
            fi
        fi
    fi
done

echo ""

# -----------------------------------------------
# Test B5: Skill directories have entry files
# -----------------------------------------------
echo "--- B5: Skill Directory Validation ---"
MISSING_ENTRY=0
if [[ -d "$PLUGIN_ROOT/skills" ]]; then
    while IFS= read -r skill_dir; do
        DIRNAME=$(basename "$skill_dir")
        # Each skill directory should have at least one .md file
        MD_COUNT=$(find "$skill_dir" -name "*.md" -maxdepth 2 | wc -l | tr -d ' ')
        if [[ $MD_COUNT -eq 0 ]]; then
            fail "B5: skills/$DIRNAME has no .md files"
            MISSING_ENTRY=$((MISSING_ENTRY + 1))
        fi
    done < <(find "$PLUGIN_ROOT/skills" -mindepth 1 -maxdepth 1 -type d)
    [[ $MISSING_ENTRY -eq 0 ]] && pass "B5: All skill directories have entry files"
else
    fail "B5: skills/ directory does not exist"
fi

echo ""

# -----------------------------------------------
# Test B6: plan-status no-argument overview actually runs (F13)
#
# The F13 acceptance clause is "no-arg behavioral smoke against this plan folder",
# and no such test existed — F13 was closed on a grep that the guard and the loop
# name the same directory. A grep cannot see that the overview PRODUCES anything.
# The original defect was exactly this shape: the guard tested `plans` while the
# loop iterated `docs/plans/*/`, so on a normal layout the command printed
# "No plans found." and exited 0. Silent, and green under any static check.
#
# The block is EXTRACTED and EXECUTED here, in a temp tree, against a real
# status.json — the only way to observe the output.
# -----------------------------------------------
echo "--- B6: plan-status no-arg overview (F13, executed) ---"
PS_MD="$PLUGIN_ROOT/commands/plan-status.md"
if [[ ! -f "$PS_MD" ]]; then
    fail "B6: commands/plan-status.md is missing"
else
    B6_TMP="${TMPDIR:-${TEMP:-/tmp}}/dg-b6-$$"
    mkdir -p "$B6_TMP/docs/plans/2026-01-01-smoke/research"
    cat > "$B6_TMP/docs/plans/2026-01-01-smoke/status.json" <<'B6JSON'
{ "plan_name": "smoke", "current_phase": "build" }
B6JSON
    touch "$B6_TMP/docs/plans/2026-01-01-smoke/brainstorm.md"
    # First fenced bash block = the no-argument overview.
    awk '/^```bash/{n++; if(n==1){inb=1; next}} inb && /^```/{inb=0} inb' "$PS_MD" \
        > "$B6_TMP/overview.sh"
    if [[ ! -s "$B6_TMP/overview.sh" ]]; then
        fail "B6: could not extract the overview block from plan-status.md"
    else
        B6_OUT=$(cd "$B6_TMP" && bash overview.sh 2>&1) && B6_RC=0 || B6_RC=$?
        if grep -q 'No plans found' <<<"$B6_OUT"; then
            fail "B6: no-arg overview printed 'No plans found.' with docs/plans/ present — the F13 defect, live"
        elif ! grep -q '2026-01-01-smoke' <<<"$B6_OUT"; then
            fail "B6: no-arg overview did not name the plan it found (rc=$B6_RC): $(head -c 120 <<<"$B6_OUT")"
        elif ! grep -q 'build' <<<"$B6_OUT"; then
            fail "B6: no-arg overview found the plan but not its current_phase — the status.json read is broken"
        else
            pass "B6: no-arg overview lists the plan and reads its phase (executed, not grepped)"
        fi
        # Negative direction: with NO plans dir at all, the guard must fire. This is
        # what makes the check falsifying rather than merely satisfied.
        B6_EMPTY="${TMPDIR:-${TEMP:-/tmp}}/dg-b6e-$$"
        mkdir -p "$B6_EMPTY"
        cp "$B6_TMP/overview.sh" "$B6_EMPTY/"
        B6_OUT2=$(cd "$B6_EMPTY" && bash overview.sh 2>&1) || true
        if grep -q 'No plans found' <<<"$B6_OUT2"; then
            pass "B6 negative: with no plans directory the overview says so and exits cleanly"
        else
            fail "B6 negative: with no plans directory the overview should print 'No plans found.', got: $(head -c 120 <<<"$B6_OUT2")"
        fi
        rm -rf "$B6_EMPTY"
    fi
    rm -rf "$B6_TMP"
fi

echo ""

# -----------------------------------------------
# Test B7: quick-cleanup zero-argument degradation (F09)
#
# The F09 acceptance clause says "zero-arg case degrades safely — negative test
# required". What existed was a grep asserting the sentinel guard is present in the
# file. That is not the same claim: it cannot tell you the guard WORKS, and F09's
# whole point is that `$1` is never set in a command body, so the unsubstituted
# sentinel is the live path, not an edge case.
# -----------------------------------------------
echo "--- B7: quick-cleanup zero-arg degradation (F09, executed) ---"
QC_MD="$PLUGIN_ROOT/commands/quick-cleanup.md"
if [[ ! -f "$QC_MD" ]]; then
    fail "B7: commands/quick-cleanup.md is missing"
else
    B7_TMP="${TMPDIR:-${TEMP:-/tmp}}/dg-b7-$$"
    mkdir -p "$B7_TMP"
    # The inventory block: the one that opens with the FOLDER assignment.
    awk '/^```bash/{inb=1; buf=""; next}
         inb && /^```/{ if (buf ~ /FOLDER="<source-folder>"/) { printf "%s", buf; exit } inb=0; next }
         inb { buf = buf $0 "\n" }' "$QC_MD" > "$B7_TMP/inventory.sh"
    if [[ ! -s "$B7_TMP/inventory.sh" ]]; then
        fail "B7: could not extract the inventory block from quick-cleanup.md"
    else
        # A canary the block must never reach: if the sentinel guard fails to exit,
        # execution continues into the inventory and `find` runs on "<source-folder>".
        B7_OUT=$(cd "$B7_TMP" && bash inventory.sh 2>&1) && B7_RC=0 || B7_RC=$?
        if [[ $B7_RC -ne 0 ]]; then
            fail "B7: zero-arg path exited $B7_RC — it must degrade cleanly, not error"
        elif ! grep -qi 'no source folder given' <<<"$B7_OUT"; then
            fail "B7: zero-arg path did not print the usage message: $(head -c 120 <<<"$B7_OUT")"
        elif grep -q 'Source Inventory' <<<"$B7_OUT"; then
            fail "B7: zero-arg path fell THROUGH the sentinel guard into the inventory — the guard is present but inert"
        elif grep -qi 'not a directory' <<<"$B7_OUT"; then
            # Pins the MECHANISM, not just the outcome. Mutation X3 replaced the
            # sentinel guard's `exit 0` with a no-op and this test still passed: the
            # NEXT guard (`[ ! -d "$FOLDER" ]`) caught the fall-through, so the
            # inventory never ran and safe degradation survived. The outcome was
            # identical while the guard under test had stopped working — an assertion
            # on the outcome alone cannot distinguish those. Reaching the directory
            # check at all means the sentinel did not short-circuit, and it also emits
            # a confusing second message ("Not a directory: <source-folder>").
            fail "B7: zero-arg path reached the directory check — the sentinel guard did not short-circuit, and the user sees two messages"
        else
            pass "B7: zero-arg path prints usage only, exits 0, and short-circuits at the sentinel"
        fi
    fi
    rm -rf "$B7_TMP"
fi

echo ""

# -----------------------------------------------
# Summary
# -----------------------------------------------
echo "==========================================="
echo "Results: $PASS passed, $FAIL failed, $SKIP skipped"
echo "==========================================="

[[ $FAIL -gt 0 ]] && exit 1
exit 0

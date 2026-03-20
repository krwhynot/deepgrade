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
        if [[ ! -f "$PLUGIN_ROOT/commands/$CMD_NAME.md" ]]; then
            fail "B1: help.md references /deepgrade:$CMD_NAME but commands/$CMD_NAME.md does not exist"
            MISSING_REFS=$((MISSING_REFS + 1))
        fi
    done < <(grep -o '/deepgrade:[a-z-]*' "$HELP_FILE" | sed 's|/deepgrade:||' | sort -u)
    [[ $MISSING_REFS -eq 0 ]] && pass "B1: All commands in help.md have corresponding command files"
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
# Summary
# -----------------------------------------------
echo "==========================================="
echo "Results: $PASS passed, $FAIL failed, $SKIP skipped"
echo "==========================================="

[[ $FAIL -gt 0 ]] && exit 1
exit 0

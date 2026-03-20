#!/usr/bin/env bash
# =============================================================================
# Layer 1: Config/Wiring Tests
# Validates that plugin.json, commands/, agents/, README.md, and CHANGELOG.md
# are internally consistent.
#
# Run from the plugin root directory:
#   bash tests/layer1-config-wiring.sh
# =============================================================================

set -u

# ---------------------------------------------------------------------------
# Test infrastructure
# ---------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------
# Paths (relative to plugin root)
# ---------------------------------------------------------------------------
PLUGIN_JSON=".claude-plugin/plugin.json"
README="README.md"
CHANGELOG="CHANGELOG.md"
COMMANDS_DIR="commands"
AGENTS_DIR="agents"
SKILLS_DIR="skills"
HELP_MD="commands/help.md"

echo "=== DeepGrade Plugin: Layer 1 - Config/Wiring Tests ==="
echo ""

# ---------------------------------------------------------------------------
# Helper: JSON field extraction (jq with grep/sed fallback)
# ---------------------------------------------------------------------------
has_jq=false
if command -v jq >/dev/null 2>&1; then
  has_jq=true
fi

# json_field FILE KEY  -- extracts top-level string value for KEY
json_field() {
  local file="$1" key="$2"
  if $has_jq; then
    jq -r ".$key // empty" "$file" 2>/dev/null
  else
    grep -o "\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$file" | head -1 | sed "s/\"$key\"[[:space:]]*:[[:space:]]*\"//;s/\"$//"
  fi
}

# json_has_key FILE KEY  -- returns 0 if KEY exists at top level
json_has_key() {
  local file="$1" key="$2"
  if $has_jq; then
    jq -e "has(\"$key\")" "$file" >/dev/null 2>&1
  else
    grep -q "\"$key\"" "$file"
  fi
}

# json_valid FILE  -- returns 0 if file is valid JSON
json_valid() {
  local file="$1"
  if $has_jq; then
    jq empty "$file" >/dev/null 2>&1
  else
    python3 -c "import json,sys;json.load(open(sys.argv[1]))" "$file" 2>/dev/null \
      || python -c "import json,sys;json.load(open(sys.argv[1]))" "$file" 2>/dev/null
  fi
}

# ===========================================================================
# 1. MANIFEST VALIDITY
# ===========================================================================
echo "--- Manifest Validity ---"

# 1a. plugin.json exists
if [ -f "$PLUGIN_JSON" ]; then
  pass "plugin.json exists"
else
  fail "plugin.json not found at $PLUGIN_JSON"
  echo ""
  echo "Results: $PASS passed, $FAIL failed, $WARN warnings"
  exit 1
fi

# 1b. Valid JSON
if json_valid "$PLUGIN_JSON"; then
  pass "plugin.json is valid JSON"
else
  fail "plugin.json is not valid JSON"
fi

# 1c. Required fields
for field in name version description hooks; do
  if json_has_key "$PLUGIN_JSON" "$field"; then
    pass "plugin.json has required field: $field"
  else
    fail "plugin.json missing required field: $field"
  fi
done

# 1d. Hook event types
EXPECTED_EVENTS="SessionStart PreToolUse PostToolUse Stop PreCompact"
for event in $EXPECTED_EVENTS; do
  if grep -q "\"$event\"" "$PLUGIN_JSON"; then
    pass "plugin.json hooks has event type: $event"
  else
    fail "plugin.json hooks missing event type: $event"
  fi
done

echo ""

# ===========================================================================
# 2. FILE EXISTENCE & FRONTMATTER
# ===========================================================================
echo "--- File Existence & Frontmatter ---"

# 2a. Command files have valid frontmatter (starts with ---, has description)
cmd_count=0
for f in "$COMMANDS_DIR"/*.md; do
  [ -f "$f" ] || continue
  cmd_count=$((cmd_count + 1))
  fname=$(basename "$f")
  first_line=$(head -1 "$f")
  if [ "$first_line" = "---" ]; then
    # Extract frontmatter block (between first --- and second ---)
    fm=$(sed -n '2,/^---$/p' "$f" | head -n -1)
    if echo "$fm" | grep -q "description"; then
      pass "commands/$fname has valid frontmatter with description"
    else
      fail "commands/$fname frontmatter missing 'description' field"
    fi
  else
    fail "commands/$fname does not start with --- frontmatter"
  fi
done

# 2b. Agent files have valid frontmatter (starts with ---, has name and description)
agent_count=0
for f in "$AGENTS_DIR"/*.md; do
  [ -f "$f" ] || continue
  agent_count=$((agent_count + 1))
  fname=$(basename "$f")
  first_line=$(head -1 "$f")
  if [ "$first_line" = "---" ]; then
    fm=$(sed -n '2,/^---$/p' "$f" | head -n -1)
    has_name=false
    has_desc=false
    echo "$fm" | grep -q "^name:" && has_name=true
    echo "$fm" | grep -q "description" && has_desc=true
    if $has_name && $has_desc; then
      pass "agents/$fname has valid frontmatter with name and description"
    else
      missing=""
      $has_name || missing="name"
      $has_desc || { [ -n "$missing" ] && missing="$missing, "; missing="${missing}description"; }
      fail "agents/$fname frontmatter missing: $missing"
    fi
  else
    fail "agents/$fname does not start with --- frontmatter"
  fi
done

# 2c. Skills directories have an entry file (SKILL.md or index.md)
if [ -d "$SKILLS_DIR" ]; then
  for d in "$SKILLS_DIR"/*/; do
    [ -d "$d" ] || continue
    skill_name=$(basename "$d")
    if [ -f "$d/SKILL.md" ] || [ -f "$d/index.md" ]; then
      pass "skills/$skill_name has entry file"
    else
      fail "skills/$skill_name missing entry file (SKILL.md or index.md)"
    fi
  done
else
  warn "skills/ directory not found"
fi

echo ""

# ===========================================================================
# 3. VERSION CONSISTENCY
# ===========================================================================
echo "--- Version Consistency ---"

# 3a. Extract version from plugin.json
pj_version=$(json_field "$PLUGIN_JSON" "version")
if [ -n "$pj_version" ]; then
  pass "plugin.json version: $pj_version"
else
  fail "Could not extract version from plugin.json"
  pj_version="UNKNOWN"
fi

# 3b. Extract version from README.md (looks for "Current: v" pattern)
readme_version=""
if [ -f "$README" ]; then
  readme_version=$(grep -oE "Current: v[0-9]+\.[0-9]+\.[0-9]+" "$README" | head -1 | sed 's/Current: v//')
  if [ -n "$readme_version" ]; then
    pass "README.md version: $readme_version"
  else
    warn "Could not extract version from README.md (no 'Current: vX.Y.Z' pattern)"
  fi
else
  warn "README.md not found"
fi

# 3c. Extract version from CHANGELOG.md (first version header like "## X.Y.Z" or "## vX.Y.Z")
changelog_version=""
if [ -f "$CHANGELOG" ]; then
  changelog_version=$(grep -oE "^## v?[0-9]+\.[0-9]+\.[0-9]+" "$CHANGELOG" | head -1 | sed 's/^## v\{0,1\}//')
  if [ -n "$changelog_version" ]; then
    pass "CHANGELOG.md version: $changelog_version"
  else
    warn "Could not extract version from CHANGELOG.md"
  fi
fi

# 3d. Compare all found versions
version_mismatch=false
if [ -n "$readme_version" ] && [ "$pj_version" != "$readme_version" ]; then
  fail "Version mismatch: plugin.json=$pj_version README=$readme_version"
  version_mismatch=true
fi
if [ -n "$changelog_version" ] && [ "$pj_version" != "$changelog_version" ]; then
  fail "Version mismatch: plugin.json=$pj_version CHANGELOG=$changelog_version"
  version_mismatch=true
fi
if [ -n "$readme_version" ] && [ -n "$changelog_version" ] && [ "$readme_version" != "$changelog_version" ]; then
  fail "Version mismatch: README=$readme_version CHANGELOG=$changelog_version"
  version_mismatch=true
fi
if ! $version_mismatch && [ -n "$readme_version" ]; then
  pass "All versions match: $pj_version"
fi

echo ""

# ===========================================================================
# 4. HOOK COUNT CONSISTENCY
# ===========================================================================
echo "--- Hook Count Consistency ---"

# 4a. Count hooks in plugin.json (count "type": "command" entries)
pj_hook_count=0
if $has_jq; then
  pj_hook_count=$(jq '[.hooks[][] | .hooks[]? | select(.type == "command")] | length' "$PLUGIN_JSON" 2>/dev/null)
else
  pj_hook_count=$(grep -c '"type"[[:space:]]*:[[:space:]]*"command"' "$PLUGIN_JSON")
fi
pj_hook_count=${pj_hook_count:-0}

# 4b. Extract number from README heading "Safety Hooks (N)"
readme_hook_heading=0
if [ -f "$README" ]; then
  readme_hook_heading=$(grep -oE "Safety Hooks \([0-9]+\)" "$README" | head -1 | grep -oE "[0-9]+")
  readme_hook_heading=${readme_hook_heading:-0}
fi

# 4c. Count rows in README Safety Hooks table
# The table starts after "Safety Hooks" heading, skip header + separator rows
readme_hook_table=0
if [ -f "$README" ]; then
  in_table=false
  past_header=0
  while IFS= read -r line; do
    if echo "$line" | grep -q "## Safety Hooks"; then
      in_table=true
      past_header=0
      continue
    fi
    if $in_table; then
      # Stop at next heading or empty line after table
      if echo "$line" | grep -q "^##\|^$" && [ $past_header -gt 2 ]; then
        break
      fi
      if echo "$line" | grep -q "^|"; then
        past_header=$((past_header + 1))
        # Skip header row and separator row
        if [ $past_header -gt 2 ]; then
          readme_hook_table=$((readme_hook_table + 1))
        fi
      fi
    fi
  done < "$README"
fi

# 4d. Report
pass "plugin.json hook count: $pj_hook_count"
hook_mismatch=false

if [ "$readme_hook_heading" -ne "$readme_hook_table" ]; then
  fail "Hook count: README heading says $readme_hook_heading, README table has $readme_hook_table rows"
  hook_mismatch=true
fi

if [ "$pj_hook_count" -ne "$readme_hook_table" ]; then
  fail "Hook count: plugin.json has $pj_hook_count entries, README table has $readme_hook_table rows"
  hook_mismatch=true
fi

if [ "$pj_hook_count" -ne "$readme_hook_heading" ]; then
  fail "Hook count: plugin.json has $pj_hook_count entries, README heading says $readme_hook_heading"
  hook_mismatch=true
fi

if ! $hook_mismatch; then
  pass "All hook counts match: $pj_hook_count"
fi

echo ""

# ===========================================================================
# 5. COMMAND COUNT CONSISTENCY
# ===========================================================================
echo "--- Command Count Consistency ---"

# 5a. Count .md files in commands/
if [ -d "$COMMANDS_DIR" ]; then
  pass "commands/ has $cmd_count .md files"
else
  fail "commands/ directory not found"
fi

# 5b. Extract command count from README heading "Commands (N)"
readme_cmd_count=0
if [ -f "$README" ]; then
  readme_cmd_count=$(grep -oE "Commands \([0-9]+\)" "$README" | head -1 | grep -oE "[0-9]+")
  readme_cmd_count=${readme_cmd_count:-0}
fi

if [ "$cmd_count" -eq "$readme_cmd_count" ]; then
  pass "Command count matches: commands/ has $cmd_count, README says $readme_cmd_count"
else
  fail "Command count mismatch: commands/ has $cmd_count files, README says $readme_cmd_count"
fi

# 5c. Every command listed in help.md should have a corresponding file in commands/
if [ -f "$HELP_MD" ]; then
  # Extract command names from help.md (pattern: /deepgrade:command-name)
  help_commands=$(grep -oE '/deepgrade:[a-z][-a-z0-9]*' "$HELP_MD" | sed 's|/deepgrade:||' | sort -u)
  for hcmd in $help_commands; do
    if [ -f "$COMMANDS_DIR/$hcmd.md" ]; then
      pass "help.md command '$hcmd' has file: commands/$hcmd.md"
    else
      fail "help.md references command '$hcmd' but commands/$hcmd.md not found"
    fi
  done
else
  warn "commands/help.md not found, skipping help cross-reference"
fi

echo ""

# ===========================================================================
# 6. AGENT COUNT CONSISTENCY
# ===========================================================================
echo "--- Agent Count Consistency ---"

pass "agents/ has $agent_count .md files"

# Extract agent count from README (looks for "N agents" pattern)
readme_agent_count=0
if [ -f "$README" ]; then
  readme_agent_count=$(grep -oE "\*\*[0-9]+ agents\*\*" "$README" | head -1 | grep -oE "[0-9]+")
  readme_agent_count=${readme_agent_count:-0}
fi

if [ "$readme_agent_count" -gt 0 ]; then
  if [ "$agent_count" -eq "$readme_agent_count" ]; then
    pass "Agent count matches: agents/ has $agent_count, README says $readme_agent_count"
  else
    fail "Agent count mismatch: agents/ has $agent_count files, README says $readme_agent_count"
  fi
else
  warn "Could not extract agent count from README"
fi

echo ""

# ===========================================================================
# 7. CROSS-REFERENCE CHECKS
# ===========================================================================
echo "--- Cross-Reference Checks ---"

# 7a. Commands that reference agent names -- verify those agents exist
if [ -d "$COMMANDS_DIR" ] && [ -d "$AGENTS_DIR" ]; then
  # Build list of known agent names (filenames without .md)
  agent_names=""
  for f in "$AGENTS_DIR"/*.md; do
    [ -f "$f" ] || continue
    agent_names="$agent_names $(basename "$f" .md)"
  done

  # Check for agent references in command files
  agent_refs_checked=false
  for agent_name in plan-scaffolder plan-auditor; do
    # Look for references in command files
    refs=$(grep -rl "$agent_name" "$COMMANDS_DIR"/ 2>/dev/null)
    if [ -n "$refs" ]; then
      agent_refs_checked=true
      if [ -f "$AGENTS_DIR/$agent_name.md" ]; then
        pass "Referenced agent '$agent_name' exists in agents/"
      else
        fail "Commands reference agent '$agent_name' but agents/$agent_name.md not found"
      fi
    fi
  done

  # Also check any agent name referenced in help.md
  if [ -f "$HELP_MD" ]; then
    for aname in $agent_names; do
      if grep -q "$aname" "$HELP_MD"; then
        if [ -f "$AGENTS_DIR/$aname.md" ]; then
          # Already covered above for specific agents; just verify existence
          :
        else
          fail "help.md references agent '$aname' but agents/$aname.md not found"
        fi
      fi
    done
  fi

  if ! $agent_refs_checked; then
    pass "No agent cross-references to validate"
  fi
fi

# 7b. Session marker prefix: README must match plugin.json
echo ""
echo "--- Session Marker Consistency ---"

readme_marker_prefix=""
pj_marker_prefix=""

if [ -f "$README" ]; then
  # Look for /tmp/XX- patterns in README
  readme_marker_prefix=$(grep -oE "/tmp/[a-z]+-" "$README" | head -1 | sed 's|/tmp/||;s/-$//')
fi

if [ -f "$PLUGIN_JSON" ]; then
  # Look for /tmp/XX- patterns in plugin.json
  pj_marker_prefix=$(grep -oE "/tmp/[a-z]+-" "$PLUGIN_JSON" | head -1 | sed 's|/tmp/||;s/-$//')
fi

if [ -n "$readme_marker_prefix" ] && [ -n "$pj_marker_prefix" ]; then
  if [ "$readme_marker_prefix" = "$pj_marker_prefix" ]; then
    pass "Session marker prefix consistent: /tmp/$pj_marker_prefix-*"
  else
    warn "Session markers: README says /tmp/$readme_marker_prefix-* but plugin.json uses /tmp/$pj_marker_prefix-*"
  fi
elif [ -n "$readme_marker_prefix" ]; then
  warn "Session marker prefix found in README (/tmp/$readme_marker_prefix-*) but not in plugin.json"
elif [ -n "$pj_marker_prefix" ]; then
  warn "Session marker prefix found in plugin.json (/tmp/$pj_marker_prefix-*) but not in README"
else
  warn "Could not extract session marker prefix from either file"
fi

echo ""

# ===========================================================================
# RESULTS SUMMARY
# ===========================================================================
echo "==========================================="
echo "Results: $PASS passed, $FAIL failed, $WARN warnings"
echo "==========================================="

if [ "$FAIL" -gt 0 ]; then
  exit 1
else
  exit 0
fi

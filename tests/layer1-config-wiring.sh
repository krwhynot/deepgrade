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

# 1c. Required fields. `hooks` is deliberately NOT in this list any more — PHV5-043
#     moved the hooks to hooks/hooks.json and its presence here is now a DEFECT,
#     asserted negatively in 1e.
for field in name version description; do
  if json_has_key "$PLUGIN_JSON" "$field"; then
    pass "plugin.json has required field: $field"
  else
    fail "plugin.json missing required field: $field"
  fi
done

# 1d. Hook event types, now sourced from the hooks folder.
HOOKS_JSON="hooks/hooks.json"
EXPECTED_EVENTS="SessionStart PreToolUse PostToolUse Stop SubagentStop PreCompact"
if [ ! -f "$HOOKS_JSON" ]; then
  fail "$HOOKS_JSON is missing — lane N declares every handler there"
else
  for event in $EXPECTED_EVENTS; do
    if grep -q "\"$event\"" "$HOOKS_JSON"; then
      pass "hooks.json has event type: $event"
    else
      fail "hooks.json missing event type: $event"
    fi
  done
fi

# 1e. ATOMICITY (PHV5-043). With BOTH a hooks/ folder and a manifest `hooks` key
#     present, Claude Code v2.1.140+ silently ignores the FOLDER. So an inline key
#     surviving alongside hooks/hooks.json does not merely duplicate config — it
#     disables everything in the folder while looking correct. This is why 4b had
#     to be one commit, and why the check is a negative rather than a comparison.
if json_has_key "$PLUGIN_JSON" "hooks"; then
  fail "plugin.json still has an inline 'hooks' key — with hooks/ also present the FOLDER is silently ignored and none of the shipped handlers run"
else
  pass "plugin.json has no inline 'hooks' key (hooks/ is the single source)"
fi

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
    # A present README whose version marker cannot be read is DRIFT, not "nothing to
    # check" — spelling the version differently made this assertion vanish silently.
    fail "Could not extract version from README.md (expected a 'Current: vX.Y.Z' pattern) — the version cross-check cannot run"
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
    fail "Could not extract a version from CHANGELOG.md (expected a '## X.Y.Z' heading) — the version cross-check cannot run"
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

# 4a. Count handlers in hooks/hooks.json. Counted from the FOLDER, not the manifest
#     — PHV5-043 moved them, and counting the manifest would now always yield 0 and
#     pass vacuously against a README that also said 0.
pj_hook_count=0
if [ -f "hooks/hooks.json" ]; then
  if $has_jq; then
    pj_hook_count=$(jq '[.hooks[][] | .hooks[]? | select(.type == "command")] | length' "hooks/hooks.json" 2>/dev/null)
  else
    pj_hook_count=$(grep -c '"type"[[:space:]]*:[[:space:]]*"command"' "hooks/hooks.json")
  fi
fi
pj_hook_count=${pj_hook_count:-0}
# Floor: the count must be non-zero, or every downstream comparison is trivially
# satisfied by three matching zeros.
if [ "$pj_hook_count" -eq 0 ]; then
  fail "hook count derived as 0 from hooks/hooks.json — the derivation is broken, not the config"
fi

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

# 5c. Every `/deepgrade:X` in help.md must RESOLVE — to a command file OR to a skill.
#     A skill is a user-addressable surface too (`plugin:skill`), so requiring
#     commands/X.md would have been wrong once F30 replaced commands/doc.md with the
#     documentation skill. The assertion is widened to both surfaces, NOT relaxed:
#     a name resolving to neither still fails, which is what the mutation below proves.
if [ -f "$HELP_MD" ]; then
  help_commands=$(grep -oE '/deepgrade:[a-z][-a-z0-9]*' "$HELP_MD" | sed 's|/deepgrade:||' | sort -u)
  for hcmd in $help_commands; do
    if [ -f "$COMMANDS_DIR/$hcmd.md" ]; then
      pass "help.md '$hcmd' resolves to commands/$hcmd.md"
    elif [ -f "$SKILLS_DIR/$hcmd/SKILL.md" ]; then
      pass "help.md '$hcmd' resolves to the $hcmd skill"
    else
      fail "help.md references /deepgrade:$hcmd but neither commands/$hcmd.md nor $SKILLS_DIR/$hcmd/SKILL.md exists"
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
  # Was a warn, so "**twenty-two agents**" silently removed this assertion.
  fail "Could not extract an agent count from README (expected '**N agents**') — the count cross-check cannot run"
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
  # Accepts either a $TMPDIR/dg-* or a legacy /tmp/dg-* spelling; only the prefix matters.
  readme_marker_prefix=$(grep -ohE '(\$TMPDIR|/tmp)/[a-z]+-' "$README" | head -1 | sed 's|.*/||;s/-$//')
fi

# The handlers are what write the markers, so compare against THEM. This used to read
# plugin.json, which stopped containing hooks at 4b — so the check silently degraded to
# a warn and verified nothing. The handlers build paths as
# `path.join(tmp, 'dg-<kind>-<session>')` where tmp resolves TMPDIR/TEMP/os.tmpdir(),
# so the literal string to look for is the `dg-` filename prefix, not a /tmp path.
pj_marker_prefix=$(grep -ohE "dg-(baseline|build|test)-" scripts/*.js 2>/dev/null \
                   | head -1 | sed 's/-[a-z]*-$//')

if [ -n "$readme_marker_prefix" ] && [ -n "$pj_marker_prefix" ]; then
  if [ "$readme_marker_prefix" = "$pj_marker_prefix" ]; then
    pass "Session marker prefix consistent between README and scripts/: ${pj_marker_prefix}-*"
  else
    fail "Session markers: README says ${readme_marker_prefix}-* but scripts/ write ${pj_marker_prefix}-*"
  fi
elif [ -n "$readme_marker_prefix" ]; then
  fail "Session marker prefix ${readme_marker_prefix}-* documented in README but no handler in scripts/ writes it"
elif [ -n "$pj_marker_prefix" ]; then
  fail "Handlers write ${pj_marker_prefix}-* markers but README documents no session-marker location"
else
  fail "Could not extract a session-marker prefix from README or scripts/ — the cross-check cannot run"
fi

echo ""

# ===========================================================================
# 8. GUIDE.md conformance (F20A) — added by PHV5-031
#
# GUIDE.md carried NO assertions before this, which is exactly how it drifted
# to v4.28.0 while plugin.json read 4.31.0. It is a user-facing snapshot of the
# plugin's shape, so every number in it is a claim that can go stale silently.
# ===========================================================================
echo ""
echo "--- GUIDE.md conformance (F20A) ---"

GUIDE="GUIDE.md"
if [ ! -f "$GUIDE" ]; then
  fail "F20A: $GUIDE does not exist"
else
  # 8a. Version in the H1 heading must equal plugin.json's
  guide_version=$(grep -oE "^# DeepGrade Knowledge Guide v[0-9]+\.[0-9]+\.[0-9]+" "$GUIDE" \
                  | head -1 | grep -oE "[0-9]+\.[0-9]+\.[0-9]+")
  if [ -z "$guide_version" ]; then
    fail "F20A: no 'DeepGrade Knowledge Guide vX.Y.Z' heading found in $GUIDE"
  elif [ "$guide_version" = "$pj_version" ]; then
    pass "F20A: GUIDE version matches plugin.json ($guide_version)"
  else
    fail "F20A: Version mismatch: plugin.json=$pj_version GUIDE=$guide_version"
  fi

  # 8b. Any version badge must agree with the heading (they drifted together before)
  badge_mismatch=$(grep -oE "v[0-9]+\.[0-9]+\.[0-9]+-stable|DeepGrade_v[0-9]+\.[0-9]+\.[0-9]+" "$GUIDE" \
                   | grep -oE "[0-9]+\.[0-9]+\.[0-9]+" | grep -vxF "$pj_version" | head -1)
  if [ -n "$badge_mismatch" ]; then
    fail "F20A: GUIDE badge shows $badge_mismatch but plugin.json is $pj_version"
  else
    pass "F20A: GUIDE version badges agree with plugin.json"
  fi

  # 8c. Command count in the subtitle must equal the real count
  guide_cmd_count=$(grep -oE '\*\*[0-9]+ Commands\*\*' "$GUIDE" | head -1 | grep -oE '[0-9]+')
  if [ -z "$guide_cmd_count" ]; then
    # Was a warn: "**Seventeen Commands**" made the check disappear rather than fail.
    fail "F20A: no '**N Commands**' subtitle in $GUIDE — write the count as a numeral so it can be cross-checked against commands/"
  elif [ "$guide_cmd_count" -eq "$cmd_count" ]; then
    pass "F20A: GUIDE command count matches commands/ ($cmd_count)"
  else
    fail "F20A: Command count mismatch: commands/ has $cmd_count, GUIDE says $guide_cmd_count"
  fi

  # 8d. Skill count in the subtitle must equal the real count
  real_skill_count=$(find skills -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
  guide_skill_count=$(grep -oE '\*\*[0-9]+ Skills\*\*' "$GUIDE" | head -1 | grep -oE '[0-9]+')
  if [ -z "$guide_skill_count" ]; then
    fail "F20A: no '**N Skills**' subtitle in $GUIDE — write the count as a numeral so it can be cross-checked against skills/"
  elif [ "$guide_skill_count" -eq "$real_skill_count" ]; then
    pass "F20A: GUIDE skill count matches skills/ ($real_skill_count)"
  else
    fail "F20A: Skill count mismatch: skills/ has $real_skill_count, GUIDE says $guide_skill_count"
  fi

  # 8e. The planning workflow has NINE phases. GUIDE said "8-phase" while listing
  #     all nine by name — a self-contradiction no assertion could catch.
  if grep -qE '[0-9]+-phase' "$GUIDE" && grep -qE '\b8-phase\b' "$GUIDE"; then
    fail "F20A: GUIDE still describes an '8-phase' workflow (it has 9 phases)"
  else
    pass "F20A: GUIDE contains no stale '8-phase' claim"
  fi
fi

# ===========================================================================
# 9. Update-flow documentation (F04) — added by PHV5-031
#
# An installed plugin lives in a versioned cache dir and third-party
# auto-update is OFF by default, so "picks up changes automatically" was
# actively false and would strand users on a stale version silently.
# ===========================================================================
echo ""
echo "--- Update-flow documentation (F04) ---"

# 9a. The false auto-update claim must not reappear in any shipped doc
autoupdate_claim=$(grep -rln "picks up changes automatically" \
                     --include='*.md' . 2>/dev/null | grep -v '^\./docs/plans/' | head -1)
if [ -n "$autoupdate_claim" ]; then
  fail "F04: false auto-update claim present in $autoupdate_claim"
else
  pass "F04: no 'picks up changes automatically' claim in shipped docs"
fi

# 9b. Every install command must be marketplace-qualified
bare_install=$(grep -rn '/plugin install deepgrade' --include='*.md' . 2>/dev/null \
               | grep -v '^\./docs/plans/' | grep -v 'deepgrade@' | head -1)
if [ -n "$bare_install" ]; then
  fail "F04: unqualified install command (missing @deepgrade-marketplace): $bare_install"
else
  pass "F04: all install commands are marketplace-qualified"
fi

# 9c. The documented update path must name the four-command sequence
if grep -q '/plugin marketplace update' "$GUIDE" && grep -q '/reload-plugins' "$GUIDE"; then
  pass "F04: GUIDE documents the marketplace update + reload sequence"
else
  fail "F04: GUIDE does not document '/plugin marketplace update' + '/reload-plugins'"
fi

# 9d. Live-edit must be tied to --plugin-dir, the only place it is true
if grep -q -- '--plugin-dir' "$GUIDE"; then
  pass "F04: GUIDE ties the live-edit flow to --plugin-dir"
else
  fail "F04: GUIDE describes no --plugin-dir live-edit flow"
fi

# ===========================================================================
# 10. Agent identity + reverse reference resolution (F17, F01, F29) — PHV5-010/011/012
#
# The 4.27.0 release renamed the agent FILES but never their frontmatter, so
# every user-facing name (deepgrade:context-scanner, etc.) failed to resolve at
# runtime while the orchestrating commands quietly kept working off the old
# names. Two agents also shared the name "report-generator", so one was
# permanently shadowed. These assertions make both classes impossible to
# reintroduce.
# ===========================================================================
echo ""
echo "--- Agent identity (F17/F01) ---"

# 10a. frontmatter name MUST equal filename, per file.
#      NOTE: `sed -n '2s/...' agents/*.md` numbers lines CUMULATIVELY across files
#      and silently reads only the first one — always iterate per file.
name_drift=0
for af in agents/*.md; do
  [ -f "$af" ] || continue
  abase=$(basename "$af" .md)
  aname=$(grep -m1 '^name:' "$af" | sed 's/^name:[[:space:]]*//;s/[[:space:]]*$//')
  if [ "$abase" != "$aname" ]; then
    fail "F17: agents/$abase.md declares name '$aname' (frontmatter must equal filename)"
    name_drift=$((name_drift + 1))
  fi
done
[ "$name_drift" -eq 0 ] && pass "F17: all agent frontmatter names match their filenames"

# 10b. names must be globally unique — a collision silently shadows one agent
dup_names=$(for af in agents/*.md; do grep -m1 '^name:' "$af" | sed 's/^name:[[:space:]]*//;s/[[:space:]]*$//'; done | sort | uniq -d)
if [ -n "$dup_names" ]; then
  fail "F01: duplicate agent name(s), one agent is unreachable: $(echo $dup_names | tr '\n' ' ')"
else
  pass "F01: all agent names are unique"
fi

# 10c. REVERSE SWEEP — every agent name referenced by a command, agent, or skill
#      must resolve to a real agent. This is the F17 landmine: renaming
#      frontmatter without moving the caller lines passes 10a and breaks runtime.
for af in agents/*.md; do grep -m1 '^name:' "$af" | sed 's/^name:[[:space:]]*//;s/[[:space:]]*$//'; done | sort -u > /tmp/dg_valid_agents.$$
unresolved=0
# Extract MAXIMAL hyphenated tokens, then keep those with an agent-shaped suffix.
# Do NOT anchor with \b around the suffix: grep treats '-' as a word boundary, so
# '\breport-generator\b' matches INSIDE 'deepgrade-report-generator' and reports a
# phantom unresolved name. Leftmost-longest matching on the whole token avoids this.
for ref in $(grep -rhoE '\b[a-z][a-z-]*[a-z]\b' commands/ agents/ skills/ 2>/dev/null \
             | grep -E -- '-(scanner|generator|auditor|mapper|assessor|scaffolder)$' | sort -u); do
  # "ai-readiness-scanner" is a tool-name string inside the readability-score.json
  # output schema, not an agent invocation. Excluded deliberately.
  [ "$ref" = "ai-readiness-scanner" ] && continue
  if ! grep -qxF "$ref" /tmp/dg_valid_agents.$$; then
    fail "F17/F29: '$ref' is referenced but no agent declares that name"
    unresolved=$((unresolved + 1))
  fi
done
rm -f /tmp/dg_valid_agents.$$
[ "$unresolved" -eq 0 ] && pass "F17/F29: every referenced agent name resolves to a real agent"

# ===========================================================================
# 11. Documentation templates (F29, F31) — PHV5-010
# ===========================================================================
echo ""
echo "--- Documentation templates (F29/F31) ---"

TPL_DIR="skills/documentation/resources"
if [ ! -d "$TPL_DIR" ]; then
  fail "F29: $TPL_DIR does not exist"
else
  # 11a. No "Deploy the **X** agent" instruction may name a non-existent agent.
  #      (10c already resolves every agent-shaped token; this catches the
  #      specific phantom-generator phrasing that shipped in the templates.)
  phantom=$(grep -rhoE 'Deploy the \*\*[a-z-]+\*\* agent' "$TPL_DIR" 2>/dev/null | head -1)
  if [ -n "$phantom" ]; then
    fail "F29: template still instructs '$phantom' — verify that agent exists"
  else
    pass "F29: no phantom 'Deploy the **X** agent' instructions in templates"
  fi

  # 11b. Only namespaced /deepgrade:* commands may appear, and each must resolve.
  #      Path fragments (docs/audit/...) are excluded by requiring the slash to
  #      follow whitespace, a quote, or a paren — never a path character.
  #
  #      BACKTICK included (Codex round 4, N7): the boundary class omitted it, so
  #      "Run `/audit` first." — the way a dead command is MOST likely to be written in
  #      Markdown, as inline code — passed the sweep with Layer 1 at 139/0. Reproduced.
  bad_cmd=0
  for tok in $(grep -rhoE '(^|[[:space:]"'"'"'(`])/[a-z][a-z-]*' "$TPL_DIR" 2>/dev/null \
               | tr -d ' "'"'"'(`' | sort -u); do
    if [ "$tok" != "/deepgrade" ]; then
      fail "F31: template references dead command '$tok' (only /deepgrade:* is valid)"
      bad_cmd=$((bad_cmd + 1))
    fi
  done
  # Resolve against commands AND skills — see 5c. F30 pointed these templates at the
  # documentation skill, which is addressable but has no commands/ file.
  for c in $(grep -rhoE '/deepgrade:[a-z-]+' "$TPL_DIR" 2>/dev/null | sed 's|/deepgrade:||' | sort -u); do
    if [ ! -f "commands/$c.md" ] && [ ! -f "$SKILLS_DIR/$c/SKILL.md" ]; then
      fail "F31: template references /deepgrade:$c but it resolves to neither a command nor a skill"
      bad_cmd=$((bad_cmd + 1))
    fi
  done
  [ "$bad_cmd" -eq 0 ] && pass "F31: every template reference is namespaced and resolves"
fi

# ===========================================================================
# 12. Agent tool allowlists (F02, F03, F07, F21, F27) — PHV5-020
#
# `claude plugin validate --strict` reads only plugin.json and marketplace.json.
# Verified 2026-07-29: it passes on an agent file with its `name:` field deleted.
# The entire agent-frontmatter defect class is therefore invisible to the
# official validator and has to be guarded here.
#
# Every check below DERIVES its subject set from file contents rather than
# hardcoding a roster, and asserts a floor on that set — a derivation that
# silently matches nothing would otherwise pass vacuously.
# ===========================================================================
echo ""
echo "--- Agent tool allowlists (F02/F03/F07/F21/F27) ---"

# body_of <file> — everything after the first frontmatter block.
# Do NOT use `sed -n '/^---$/,/^---$/!p'`: agent bodies contain `---` horizontal
# rules, which pair with the delimiters and silently delete body chunks. That
# hid 3 of 20 agents from the F07 sweep while it still reported a pass.
body_of() { awk 'BEGIN{n=0} /^---\r?$/{n++; next} n>=2' "$1"; }

# fm_get <file> <key> — the value of a key from BOUNDED YAML frontmatter only.
#
# WHY THIS EXISTS: every frontmatter assertion in §17 used a bare `grep '^key:'` over
# the WHOLE FILE, so a decoy in the body satisfied it. Codex demonstrated all of these
# passing after the real frontmatter key had been deleted:
#   - `argument-hint: "[decoy-in-body]"` written into the body
#   - `disable-model-invocation: true` written into the body
# A body is prose and examples; it is not configuration, and a check that cannot tell
# the two apart is not checking configuration.
#
# Reads only between the first `---` and the second. Handles CRLF, folded/continued
# scalars (a following more-indented line belongs to the same value), and returns
# empty for a key that is absent OR present with no value — the caller decides which
# of those matters, but neither can masquerade as a declaration.
fm_get() {
  awk -v want="$2" '
    BEGIN { n = 0; found = 0 }
    /^---\r?$/ { n++; if (n >= 2) exit; next }
    n != 1 { next }
    {
      line = $0; sub(/\r$/, "", line)
      if (found) {
        # continuation: more-indented, and not a new key at column zero
        if (line ~ /^[[:space:]]+[^[:space:]]/) { sub(/^[[:space:]]+/, "", line); printf " %s", line; next }
        exit
      }
      if (line ~ "^" want ":") {
        sub("^" want ":[[:space:]]*", "", line)
        printf "%s", line
        found = 1
      }
    }
  ' "$1" 2>/dev/null
}
# fm_has <file> <key> — key present in frontmatter WITH a non-empty value.
fm_has() { [ -n "$(fm_get "$1" "$2" | tr -d '[:space:]')" ]; }
# tools_of <file> — the COMPLETE tools: value, however it is spelled in YAML.
#
# `grep -m1 '^tools:'` read only the first PHYSICAL line, which a valid folded
# multi-line scalar defeats entirely:
#
#     tools: "Read, Grep, Glob, Bash, Write, Skill,
#       Edit, mcp__acme__scan"
#
# YAML folds that to one value granting Edit AND a hardcoded MCP identifier, while
# the Edit ban, the MCP ban and the flow-array ban all reported PASS. The bans
# tokenised correctly — they were just handed one line of a two-line value.
#
# Collect the tools: line plus every following more-indented continuation line,
# stopping at the next top-level key or the closing frontmatter delimiter.
tools_of() {
  awk '
    /^---\r?$/ { if (++d == 2) exit; next }
    /^tools:/  { collecting = 1; sub(/^tools:[[:space:]]*/, ""); printf "%s ", $0; next }
    collecting && /^[[:space:]]+[^[:space:]]/ { sub(/^[[:space:]]+/, ""); printf "%s ", $0; next }
    collecting { collecting = 0 }
  ' "$1" 2>/dev/null | tr -d '\r'
}
has_tool() { echo "$2" | grep -qE "(^|[,[:space:]\"])$1($|[,[:space:]\"])"; }

# --- 12a. F02: the two agents with shell-driven bodies and a contract output.
f02_bad=0
for a in doc-auditor integration-scanner; do
  t=$(tools_of "$AGENTS_DIR/$a.md")
  for need in Bash Write; do
    has_tool "$need" "$t" || { fail "F02: $a.md needs $need in tools (has: $t)"; f02_bad=1; }
  done
done
[ "$f02_bad" -eq 0 ] && pass "F02: doc-auditor and integration-scanner both allowlist Bash and Write"

# --- 12b. F03: nested delegation, granted to exactly the two planners.
f03_bad=0
for a in plan-scaffolder plan-auditor; do
  has_tool Agent "$(tools_of "$AGENTS_DIR/$a.md")" \
    || { fail "F03: $a.md deploys parallel subagents but omits Agent from tools"; f03_bad=1; }
done
for f in "$AGENTS_DIR"/*.md; do
  b=$(basename "$f" .md)
  case "$b" in plan-scaffolder|plan-auditor) continue ;; esac
  has_tool Agent "$(tools_of "$f")" \
    && { fail "F03: $b.md gained Agent as a side effect — only the two planners may nest"; f03_bad=1; }
done
[ "$f03_bad" -eq 0 ] && pass "F03: Agent granted to exactly plan-scaffolder and plan-auditor"

# --- 12c. F07: every agent whose body mandates a docs/audit/ output has Write.
f07_subjects=0
f07_bad=0
for f in "$AGENTS_DIR"/*.md; do
  body_of "$f" | grep -qiE '[Ww]rite[^.]*docs/audit/' || continue
  f07_subjects=$((f07_subjects + 1))
  has_tool Write "$(tools_of "$f")" \
    || { fail "F07: $(basename "$f") is told to write into docs/audit/ but omits Write"; f07_bad=1; }
done
if [ "$f07_subjects" -lt 20 ]; then
  fail "F07: sweep derived only $f07_subjects file-writing agents (expected >= 20) — the derivation is broken, not the code"
elif [ "$f07_bad" -eq 0 ]; then
  pass "F07: all $f07_subjects agents that write into docs/audit/ allowlist Write"
fi

# --- 12d. F07 negative: Edit is never granted. Scanners characterize, never patch.
#      Reads the FULL folded value via tools_of, not `grep '^tools:.*Edit'` — a
#      continuation line hid `Edit` from the line-based form completely.
edit_bad=0
for f in "$AGENTS_DIR"/*.md; do
  has_tool Edit "$(tools_of "$f")" \
    && { fail "F07: $(basename "$f") grants Edit — audit agents write reports, they do not modify code"; edit_bad=1; }
done
[ "$edit_bad" -eq 0 ] && pass "F07: no agent grants Edit"

# --- 12e. F21: no MCP identifier of any shape belongs in an allowlist.
#      Validate passes on bare names, so this is the only guard.
#
#      Tokenize the allowlist and test each entry, rather than regex-matching the
#      whole line. The line-based form this replaced had three bugs: it missed a
#      bare name inside a YAML flow array (preceded by `"`, so the leading
#      (^|[,[:space:]]) never matched — coverage survived only by accident,
#      because 12g separately bans flow arrays); it reported a correctly
#      qualified mcp__server__tool as a "bare name", which is the wrong
#      diagnosis; and its fail() calls ran inside a piped `while`, i.e. a
#      subshell, so every violation past the first was lost from the tally.
#      Reads the FULL folded value per file, so a continuation line cannot hide an
#      identifier the way it hid `Edit` from 12d.
allow_of() {
  awk '
    /^---\r?$/ { if (++d == 2) exit; next }
    /^(tools|allowed-tools):/ { collecting = 1; sub(/^[a-z-]+:[[:space:]]*/, ""); printf "%s ", $0; next }
    collecting && /^[[:space:]]+[^[:space:]]/ { sub(/^[[:space:]]+/, ""); printf "%s ", $0; next }
    collecting { collecting = 0 }
  ' "$1" 2>/dev/null | tr -d '\r'
}
mcp_bad=0
mcp_subjects=0
for f in "$AGENTS_DIR"/*.md "$COMMANDS_DIR"/*.md; do
  [ -e "$f" ] || continue
  val=$(allow_of "$f")
  [ -z "$val" ] && continue
  mcp_subjects=$((mcp_subjects + 1))
  for tok in $(echo "$val" | tr ',[]"'"'" ' \n' | tr -s ' '); do
    case "$tok" in
      mcp__*)
        fail "F21: $(basename "$f") hardcodes the MCP identifier '$tok' — the <server> segment is chosen by the installing user, so this resolves only on the author's machine"
        mcp_bad=$((mcp_bad + 1)) ;;
      ref_*|*_exa|perplexity_*)
        fail "F21: $(basename "$f") lists the bare MCP name '$tok' — bare names never resolve to a tool"
        mcp_bad=$((mcp_bad + 1)) ;;
    esac
  done
done
if [ "$mcp_subjects" -lt 30 ]; then
  fail "F21: derived only $mcp_subjects allowlists (expected >= 30) — the derivation is broken, not the config"
elif [ "$mcp_bad" -eq 0 ]; then
  pass "F21: no MCP identifier, bare or qualified, in any of $mcp_subjects tools:/allowed-tools: lists"
fi

# --- 12f. F27: an agent told to reference a knowledge skill must be able to load
#      it AND must name it in a form that resolves. Checking only the first is a
#      capability check standing in for a resolution check: commit 103574e passed
#      it while all 7 agents still named the skill unqualified, which is F21's
#      defect in a different field. Both clauses of the F27 fix are asserted here.
f27_subjects=0
f27_bad=0
for f in "$AGENTS_DIR"/*.md; do
  refs=$(grep -ohE '\b(deepgrade:)?[a-z][a-z-]*(knowledge|scoring|research) skill\b' "$f" 2>/dev/null \
         | sed 's/ skill$//' | sort -u)
  [ -z "$refs" ] && continue
  f27_subjects=$((f27_subjects + 1))
  b=$(basename "$f")

  # (a) access: the Skill tool, or the `skills:` preload key. Either satisfies it.
  if ! has_tool Skill "$(tools_of "$f")" && ! grep -q '^skills:' "$f"; then
    fail "F27: $b references a knowledge skill but can neither invoke nor preload one"
    f27_bad=1
  fi

  # (b) resolution: every referenced name must be namespaced AND exist on disk.
  for ref in $refs; do
    case "$ref" in
      deepgrade:*) ;;
      *) fail "F27: $b names the skill '$ref' unqualified — plugin skills address as plugin:skill (deepgrade:$ref)"
         f27_bad=1; continue ;;
    esac
    bare=${ref#deepgrade:}
    if [ ! -f "$SKILLS_DIR/$bare/SKILL.md" ]; then
      fail "F27: $b references skill '$ref' but $SKILLS_DIR/$bare/SKILL.md does not exist"
      f27_bad=1
    fi
  done

  # (c) a `skills:` entry must itself resolve — an unverifiable mechanism
  #     pointing at a nonexistent skill is worse than no mechanism.
  for pre in $(grep -m1 '^skills:' "$f" 2>/dev/null | tr -d '\r' | sed 's/^skills://' \
               | tr ',[]"'"'" ' \n' | tr -s ' '); do
    case "$pre" in
      deepgrade:*) [ -f "$SKILLS_DIR/${pre#deepgrade:}/SKILL.md" ] \
                     || { fail "F27: $b preloads '$pre' but that skill does not exist"; f27_bad=1; } ;;
      ?*) fail "F27: $b preloads '$pre' unqualified — use deepgrade:$pre"; f27_bad=1 ;;
    esac
  done
done
if [ "$f27_subjects" -lt 7 ]; then
  fail "F27: sweep derived only $f27_subjects skill-referencing agents (expected >= 7) — the derivation is broken"
elif [ "$f27_bad" -eq 0 ]; then
  pass "F27: all $f27_subjects agents referencing a knowledge skill can load it and name it resolvably"
fi

# --- 12g. Ride-along: tools: uses one shape (comma-separated), not YAML flow arrays.
flow=$(grep -l '^tools:[[:space:]]*\[' "$AGENTS_DIR"/*.md 2>/dev/null | head -1)
if [ -n "$flow" ]; then
  fail "tools: flow-array form still present in $flow — use the comma-separated form"
else
  pass "tools: uses the comma-separated form in every agent"
fi

# ===========================================================================
# 13. MCP naming convention is stated identically in both homes (F32) — PHV5-021
# ===========================================================================
echo ""
echo "--- MCP naming convention (F32) ---"

MCP_SKILL="skills/mcp-research/SKILL.md"
extract_convention() {
  awk '/<!-- CANONICAL-MCP-CONVENTION -->/{f=1; next} /<!-- \/CANONICAL-MCP-CONVENTION -->/{f=0} f' "$1" \
    | tr -d '\r' | sed 's/[[:space:]]*$//'
}
conv_skill=$(extract_convention "$MCP_SKILL")
conv_contrib=$(extract_convention "CONTRIBUTING.md")

if [ -z "$conv_skill" ]; then
  fail "F32: no CANONICAL-MCP-CONVENTION block in $MCP_SKILL"
elif [ -z "$conv_contrib" ]; then
  fail "F32: no CANONICAL-MCP-CONVENTION block in CONTRIBUTING.md"
elif [ "$conv_skill" != "$conv_contrib" ]; then
  fail "F32: the MCP convention differs between $MCP_SKILL and CONTRIBUTING.md — one of them will go stale"
else
  pass "F32: the MCP naming convention is byte-identical in the skill and CONTRIBUTING.md"
fi

# The convention has to actually say the two things that make it correct;
# an empty or reworded block that no longer mentions suffix matching would
# otherwise pass 13a purely by being identical in both files.
conv_ok=1
echo "$conv_skill" | grep -q 'mcp__<server>__<tool>' || { fail "F32: convention omits the qualified mcp__<server>__<tool> form"; conv_ok=0; }
echo "$conv_skill" | grep -qi 'suffix' || { fail "F32: convention omits the suffix-match availability rule"; conv_ok=0; }
[ "$conv_ok" -eq 1 ] && pass "F32: convention states both the qualified form and the suffix-match rule"

# The bare-name-equality rule the skill used to teach must be gone.
if grep -q "If a tool name" "$MCP_SKILL" && grep -q "doesn't match, the tool is simply unavailable" "$MCP_SKILL"; then
  fail "F32: $MCP_SKILL still teaches bare-name equality — it triggers its own degradation path"
else
  pass "F32: the bare-name-equality rule is gone from $MCP_SKILL"
fi

# Tool names the skill advertises must not include the three that do not exist
# on any Exa server, outside the note that documents their removal.
phantom_exa=$(grep -nE '^\s*[-|].*\b(get_code_context_exa|crawling_exa|web_search_advanced_exa)\b' \
              "$MCP_SKILL" "$COMMANDS_DIR"/*.md "$AGENTS_DIR"/*.md 2>/dev/null | head -1)
if [ -n "$phantom_exa" ]; then
  fail "F32: non-existent Exa tool recommended at $phantom_exa"
else
  pass "F32: no non-existent Exa tool names are recommended anywhere"
fi

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
# 15. Hook wiring under lane N (F06, PHV5-043)
#
# F06's acceptance is bidirectional: every file in scripts/ must be referenced by
# the hook config, AND every reference must resolve. One direction alone permits
# either dead code shipping to installers or a hook pointing at nothing.
# ===========================================================================
echo ""
echo "--- Hook wiring, lane N (F06) ---"

if [ ! -f "hooks/hooks.json" ]; then
  fail "F06: hooks/hooks.json missing — cannot verify wiring"
else
  # Referenced basenames, extracted from the exec-form args.
  refs=$(grep -oE '\$\{CLAUDE_PLUGIN_ROOT\}/scripts/[A-Za-z0-9._-]+' hooks/hooks.json \
         | sed 's|.*/||' | sort -u)
  ref_count=$(echo "$refs" | grep -c . || true)

  if [ "$ref_count" -lt 8 ]; then
    fail "F06: only $ref_count script references found in hooks.json (expected >= 8) — the extraction is broken"
  else
    pass "F06: hooks.json references $ref_count handler scripts"
  fi

  # Forward: every reference resolves to a real file.
  missing=0
  for r in $refs; do
    [ -f "scripts/$r" ] || { fail "F06: hooks.json references scripts/$r which does not exist"; missing=1; }
  done
  [ "$missing" -eq 0 ] && pass "F06: every referenced handler script exists"

  # The plugin invokes scripts by two mechanisms, and F06 originally knew only one.
  # Hook handlers are named in hooks.json; audit tooling is invoked from a command or
  # agent as an explicit `node .../scripts/NAME` line. The invariant F06 defends is
  # "no unwired code ships", not "everything in scripts/ is a hook", so the reverse
  # sweep accepts either mechanism (PH5-020).
  #
  # A bare mention does NOT count. Deciding whether prose "refers to" a script is an
  # intent question; requiring the reference to appear in executable form — `node`
  # followed by the path — keeps this structural. A script named only in a sentence
  # is still an orphan, which is the correct answer.
  inv_re='node[^`]*scripts/[A-Za-z0-9._-]+\.js'
  inv=$(grep -ohE "$inv_re" commands/*.md agents/*.md 2>/dev/null | sed 's|.*/||' | sort -u)
  inv_count=$(echo "$inv" | grep -c . || true)

  # Self-tests. The known-positive is the QUOTED form, copied from how the plugin
  # actually invokes a script — an earlier draft used an invented unquoted form and
  # excluded '"' from the pattern, so the self-test passed while every real
  # invocation went unrecognised. A known-positive that is not drawn from the real
  # artifact tests the pattern against the author's imagination.
  if ! printf '%s\n' 'node "${CLAUDE_PLUGIN_ROOT}/scripts/dg-example.js" \' | grep -qE "$inv_re"; then
    fail "F06: invocation pattern fails its known-positive — command-wired scripts cannot be recognised"
  fi
  if ! printf '%s\n' 'Run `node ${CLAUDE_PLUGIN_ROOT}/scripts/dg-example.js` on the records.' | grep -qE "$inv_re"; then
    fail "F06: invocation pattern misses the unquoted form"
  fi
  if printf '%s\n' 'See scripts/dg-example.js for the validation rules.' | grep -qE "$inv_re"; then
    fail "F06: invocation pattern matches a bare prose mention — a script named in a sentence would count as wired"
  fi

  # Reverse: nothing in scripts/ is unreferenced. This is the direction that stops
  # dead code shipping — the .sh set was orphaned in exactly this way before 4b.
  orphan=0
  for f in scripts/*; do
    [ -e "$f" ] || continue
    b=$(basename "$f")
    if echo "$refs" | grep -qxF "$b"; then
      continue
    elif echo "$inv" | grep -qxF "$b"; then
      continue
    else
      fail "F06: scripts/$b is referenced by neither hooks.json nor a node invocation in commands/ or agents/ — unwired code must not ship"
      orphan=1
    fi
  done
  [ "$orphan" -eq 0 ] && pass "F06: no orphaned files in scripts/ ($ref_count hook-wired, $inv_count command-wired)"

  # Ledger row 4 / F06: the SubagentStop handler existed but was wired to nothing.
  if grep -q '"SubagentStop"' hooks/hooks.json; then
    pass "F06: SubagentStop is wired (ledger row 4)"
  else
    fail "F06: SubagentStop entry missing — the handler ships but never fires"
  fi

  # Lane N is the node EXEC form: separate command + args. A shell-string form
  # would reintroduce the quoting fragility the inline hooks had, and the
  # vendor-documented portability argument rests on `node` being a real binary.
  if $has_jq; then
    nonexec=$(jq -r '[.hooks[][] | .hooks[]? | select(.command != "node" or (.args | type) != "array")] | length' hooks/hooks.json 2>/dev/null)
    if [ "${nonexec:-1}" -eq 0 ]; then
      pass "F23/lane N: every handler uses the node exec form (command + args array)"
    else
      fail "F23/lane N: $nonexec handler(s) are not the node exec form — shell strings reintroduce the quoting fragility 4a removed"
    fi
  else
    if grep -q '"command"[[:space:]]*:[[:space:]]*"node"' hooks/hooks.json \
       && ! grep -qE '"command"[[:space:]]*:[[:space:]]*"(bash|sh|cmd|powershell|pwsh)' hooks/hooks.json; then
      pass "F23/lane N: node exec form in use (grep check — jq unavailable)"
    else
      fail "F23/lane N: hooks.json does not consistently use the node exec form"
    fi
  fi
fi

# ===========================================================================
# 16. Documentation conformance (approach.md §9.2, class G)
#
# The §9.2 acceptance row is class G — "each row's claim is true of the shipped lane
# at release (grep per row)" — and NO SUCH GUARD EXISTED. I marked the row applied
# after editing the specific line numbers the table cited, and every other instance
# of the same claims survived: README asserted "Requires Node.js 18 or later" on one
# line and "Required: None. All hooks use jq with grep+sed fallback" 28 lines later,
# in a file I had edited in that same commit.
#
# So these assert the CLAIM, not a line number. A citation in an audit is a sample.
# ===========================================================================
echo ""
echo "--- Documentation conformance (§9.2) ---"

# Files a user reads. Plan documents and the CHANGELOG are excluded: the CHANGELOG
# describes 4.x truthfully in the past tense, and plan docs are a historical record.
DOC_FILES="README.md GUIDE.md METHODOLOGY.md CONTRIBUTING.md"

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
claim_absent "no doc claims zero/no required dependencies" \
  '(zero|no) required dependenc|zero-dependency (plugin|design is)|dependencies: *none|\*\*required:\*\* *none' || conf_bad=1
claim_absent "no doc presents a jq/grep+sed fallback ladder as current" \
  'falls? back to (grep|`grep`)|jq with grep|grep\+sed fallback|tries `?jq`? first|jq is optional' || conf_bad=1
claim_absent "no doc says hooks are inline in plugin.json" \
  'hooks are (defined |declared )?inline|inline hook definitions|inline in .?plugin\.json' || conf_bad=1
claim_absent "no doc references a deleted .sh handler" \
  'scripts/dg-[a-z-]+\.sh' || conf_bad=1
claim_absent "no doc claims the force-push guard permits --force-with-lease is untrue" \
  'does not block .?--force-with-lease.? \(untrue\)' || conf_bad=1

# The positive half: the Node requirement must be stated where a user will see it.
node_stated=0
for f in README.md GUIDE.md; do
  grep -qiE 'node(\.js)? ?(18|>= ?18)' "$f" && node_stated=$((node_stated + 1))
done
if [ "$node_stated" -ge 2 ]; then
  pass "§9.2: the Node.js 18+ requirement is stated in both README and GUIDE"
else
  fail "§9.2: the Node.js 18+ requirement is missing from $((2 - node_stated)) of README/GUIDE — a hard runtime requirement must be discoverable"
fi

# ===========================================================================
# 17. Wave 5 — command hygiene (F08, F09, F10, F11, F13, F14, F15, F28)
#
# WHY THIS EXISTS: Wave 5 shipped with ZERO assertions. Every one of its acceptance
# rows is class U or G — a unit test or a grep guard — and I verified all nine
# findings by running greps at the terminal and then marked them closed. That is
# closing against my own summary rather than against the rows, which is precisely the
# failure this plan has spent two waves correcting. A manual grep protects the commit
# it was run in and nothing after it.
# ===========================================================================
echo ""
echo "--- Wave 5 command hygiene (F08-F28) ---"

# --- F09: `$1` is never set in a command body (it is not a shell script), and `$0`
#     in bash is the SHELL NAME, so an unsubstituted `$0` degrades to operating on
#     "bash" rather than failing.
f09_bad=0
for f in "$COMMANDS_DIR"/*.md; do
  # Only inside fenced bash blocks; prose may legitimately discuss $1.
  # Comments are stripped before matching. On its first run this guard flagged its own
  # explanatory comments — the lines that say "do NOT write $1" — in both files it
  # checks. A false positive, and a reminder that a guard needs a control run too.
  # Drop FULL-LINE comments only. `sed 's/#.*$//'` also truncated at a QUOTED '#', so
  # `printf "#"; echo "$1"` became `printf "` and the live $1 vanished (Codex F3). Every
  # legitimate mention of $1/$0 in these files is a whole-line comment — verified across
  # commands/ — so dropping only those keeps the false positive fixed without the hole.
  if awk '/^```bash/{inb=1; next} /^```/{inb=0} inb' "$f" \
       | grep -v '^[[:space:]]*#' | grep -qE '(^|[^\\$])\$1\b'; then
    fail "F09: $(basename "$f") uses \$1 inside a bash block — a command body is not a shell script, so \$1 is never set"
    f09_bad=1
  fi
  # Leading whitespace allowed: the column-zero anchor missed an indented assignment.
  if awk '/^```bash/{inb=1; next} /^```/{inb=0} inb' "$f" \
       | grep -v '^[[:space:]]*#' | grep -qE '^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*="\$0"'; then
    fail "F09: $(basename "$f") assigns \$0 — in bash that is the shell name, so an unsubstituted value silently becomes 'bash'"
    f09_bad=1
  fi
done
[ "$f09_bad" -eq 0 ] && pass "F09: no command body relies on \$1 or \$0 inside a bash block"

# --- F09 positive: the zero-argument case must degrade safely, which means a
#     sentinel plus a guard rather than an unchecked substitution.
if grep -q '<source-folder>' "$COMMANDS_DIR/quick-cleanup.md" \
   && grep -qE 'if \[ "\$FOLDER" = "<source-folder>" \]' "$COMMANDS_DIR/quick-cleanup.md"; then
  pass "F09: quick-cleanup guards the unsubstituted sentinel (zero-arg degrades safely)"
else
  fail "F09: quick-cleanup has no sentinel guard — the zero-argument case must not fall through"
fi

# --- F10: ${PROJECT_ROOT} is not a Claude Code variable.
if grep -rn '\${PROJECT_ROOT}' "$COMMANDS_DIR"/*.md >/dev/null 2>&1; then
  fail "F10: \${PROJECT_ROOT} is not a Claude Code variable — use \${CLAUDE_PROJECT_DIR}"
else
  pass "F10: no command uses the non-existent \${PROJECT_ROOT}"
fi

# --- F11: the /ai-readiness-* commands do not exist under the plugin namespace.
#     Scoped to commands/ AND agents/: the acceptance row named only
#     readiness-generate.md, but the readiness REPORT AGENT emits these strings to
#     users, so fixing the row's file alone leaves the defect shipping.
f11_hits=$(grep -rn '/ai-readiness-' "$COMMANDS_DIR"/*.md "$AGENTS_DIR"/*.md 2>/dev/null)
if [ -n "$f11_hits" ]; then
  echo "$f11_hits" | while IFS= read -r l; do
    echo "[FAIL] F11: dead command name — $(echo "$l" | cut -c1-100)"
  done
  fail "F11: /ai-readiness-* references survive (see above); the real commands are /deepgrade:readiness-*"
else
  pass "F11: no /ai-readiness-* references in commands/ or agents/"
fi
# A DECLARATION needs a value AND must be in frontmatter. The whole-file grep was
# satisfied by `argument-hint: "[decoy-in-body]"` written into the body with the real
# frontmatter key deleted (Codex N2).
if fm_has "$COMMANDS_DIR/readiness-generate.md" 'argument-hint'; then
  pass "F11: readiness-generate declares a non-empty argument-hint in frontmatter"
else
  fail "F11: readiness-generate has no argument-hint value in its frontmatter — an empty key, or one in the body, declares nothing"
fi

# --- F13: the guard must test the directory the loop actually reads. It tested
#     `plans` while iterating `docs/plans/*/`, so on a normal layout the no-argument
#     overview printed "No plans found." and exited.
#
# Bound to the LOOP, not to two strings coexisting. The previous form passed a file that
# assigned and guarded `docs/plans` but iterated a hardcoded `plans/*/` (Codex F3) — the
# original defect, undetected. The loop must iterate the guarded VARIABLE.
f13_bad=0
grep -qE '^[[:space:]]*if \[ ! -d "\$PLANS_DIR" \]' "$COMMANDS_DIR/plan-status.md" \
  || { fail "F13: plan-status has no existence guard on \$PLANS_DIR"; f13_bad=1; }
grep -qE 'PLANS_DIR="docs/plans"' "$COMMANDS_DIR/plan-status.md" \
  || { fail "F13: plan-status must default PLANS_DIR to docs/plans"; f13_bad=1; }
# Accept either spelling of the expansion. The first version demanded "$PLANS_DIR" and
# rejected the equivalent "${PLANS_DIR}" (Codex Q3) — an over-strict guard a maintainer
# would hit on a harmless refactor and then weaken, which is how guards die.
grep -qE '^[[:space:]]*for [A-Za-z_][A-Za-z0-9_]* in "\$\{?PLANS_DIR\}?"/\*/' "$COMMANDS_DIR/plan-status.md" \
  || { fail "F13: plan-status's loop must iterate \"\$PLANS_DIR\"/*/ — a hardcoded path can diverge from the guard, which is the original defect"; f13_bad=1; }
[ "$f13_bad" -eq 0 ] && pass "F13: plan-status guards \$PLANS_DIR and its loop iterates that same variable"

# --- F14: model-invocability. EXACT SET, both directions.
f14_bad=0
f14_expected="codebase-gates plan-export readiness-generate"
# Derive the actual set rather than only checking the three named. The previous form
# passed a FOURTH command silently adding the flag (Codex F3), so it could not enforce
# "exactly" — which is what the row says.
# Frontmatter-bounded: the whole-file grep counted `disable-model-invocation: true`
# written into a command's BODY as if it were configuration (Codex N2).
f14_actual=$(for p in "$COMMANDS_DIR"/*.md; do
    v=$(fm_get "$p" 'disable-model-invocation' | tr -d '[:space:]')
    [ "$v" = "true" ] && basename "$p" .md
  done | sort | tr '\n' ' ' | sed 's/[[:space:]]*$//')
f14_want=$(printf '%s\n' $f14_expected | sort | tr '\n' ' ' | sed 's/[[:space:]]*$//')
if [ "$f14_actual" != "$f14_want" ]; then
  fail "F14: disable-model-invocation set is [$f14_actual], expected exactly [$f14_want]"
  f14_bad=1
fi
# Negative, per the §3.8 discovery-path decision: `plan` must stay model-invocable.
[ -n "$(fm_get "$COMMANDS_DIR/plan.md" 'disable-model-invocation')" ] \
  && { fail "F14: plan.md must NOT disable model invocation (§3.8 discovery path)"; f14_bad=1; }
[ "$f14_bad" -eq 0 ] && pass "F14: disable-model-invocation on exactly [$f14_want], not on plan"

# --- F15: host-tool portability.
f15_bad=0
# `tree` in COMMAND POSITION inside a bash block, with or without options: the previous
# regex required a following `-`, so a bare `tree .` walked straight through (Codex F3).
# Scoped to fenced bash blocks and to the start of a command so prose about a "directory
# tree" and words like `subtree` do not trip it.
for f in "$COMMANDS_DIR"/*.md; do
  # Command position, now including the shell keywords a command can follow. The
  # previous set covered only | ; & ( && ||, so `if tree .; then` walked through
  # (Codex N3). Keywords and wrappers are listed explicitly rather than inferred.
  if awk '/^```bash/{inb=1; next} /^```/{inb=0} inb' "$f" \
       | grep -v '^[[:space:]]*#' \
       | grep -qE '(^|[|;&(!]|&&|\|\||\b(if|then|else|elif|do|while|until|command|env|time|exec|xargs)\b)[[:space:]]*tree([[:space:]]|$)'; then
    fail "F15: $(basename "$f") invokes \`tree\`, which is not present in stock Git Bash"; f15_bad=1
  fi
done
if grep -rn 'python3 -c' "$COMMANDS_DIR"/*.md >/dev/null 2>&1; then
  fail "F15: a bare \`python3 -c\` has no fallback — python3 is absent on many Windows hosts, python on many Linux ones"; f15_bad=1
fi
if grep -rnE '^\s*(EXPORT_DIR|STAGING)="?/tmp/' "$COMMANDS_DIR"/*.md >/dev/null 2>&1; then
  fail "F15: bare /tmp staging — use \${TMPDIR:-\${TEMP:-/tmp}} so Windows hosts and concurrent runs work"; f15_bad=1
fi
if grep -q 'zip -' "$COMMANDS_DIR/plan-export.md"; then
  # Requires a real invocation on a NON-COMMENT line. Three iterations to get here:
  #   1. `grep -q 'Compress-Archive'` — satisfied by the explanatory comment alone.
  #   2. `powershell[^|]*Compress-Archive` — still satisfied by a single COMMENT line
  #      containing both words (Codex F3). Tightened to command position, comments dropped.
  # Mutation history, because my first reading was wrong: W11 "escaped" twice, but not
  # from that weakness. The mutation replaced only the FIRST occurrence of the cmdlet
  # name, which is the comment — so it deleted a comment, left the invocation intact,
  # and a green guard was correct. An invalid mutant, not a surviving defect. Re-anchored
  # on the invocation three ways (delete the line, swap the cmdlet, replace the branch
  # with `false`): caught on all three.
  if ! awk '/^```bash/{inb=1; next} /^```/{inb=0} inb' "$COMMANDS_DIR/plan-export.md" \
        | grep -v '^[[:space:]]*#' \
        | grep -qE '(^|[|;&(]|&&|\|\|)[[:space:]]*powershell[^|]*Compress-Archive'; then
    fail "F15: plan-export uses \`zip\` with no PowerShell Compress-Archive invocation — stock Windows has no zip"; f15_bad=1
  fi
fi
[ "$f15_bad" -eq 0 ] && pass "F15: no tree, no unguarded python3, no bare /tmp staging, zip has a real PowerShell fallback"

# --- F08: gate-generator writes hooks for a PROJECT, so the target is the `hooks`
#     key of .claude/settings.json. hooks/hooks.json is the PLUGIN-side location and
#     is not read from a project directory, so hooks written there never fire.
f08_bad=0
# EVERY component participating in gate generation, not just the agent. The guard searched
# only agents/gate-generator.md, so the PARENT COMMAND kept promising the inert path at
# commands/codebase-gates.md:37 and :49 while F08 stayed green (Codex round 3, N5). The
# command is what the user reads: it deployed the corrected agent and then presented the
# old path as the result. A finding about a wrong path is not closed while any component
# still names it.
#
# Derived: any command or agent that references the gate generator. A new participant is
# swept automatically instead of needing to be remembered here.
f08_components=$(grep -rlE 'gate-generator|codebase-gates' "$AGENTS_DIR" "$COMMANDS_DIR" 2>/dev/null | sort -u)
f08_comp_count=$(printf '%s\n' "$f08_components" | grep -c . || true)
if [ "$f08_comp_count" -lt 2 ]; then
  fail "F08: derived only $f08_comp_count gate-generation component(s) — the derivation collapsed, so a clean sweep would be vacuous"
  f08_bad=1
fi
for f in $f08_components; do
  if grep -q '\.claude/hooks/hooks\.json' "$f"; then
    fail "F08: $f names .claude/hooks/hooks.json — that is the PLUGIN-side path, never read from a project dir, so hooks written there are inert"
    f08_bad=1
  fi
done
grep -q '\.claude/settings\.json' "$AGENTS_DIR/gate-generator.md" \
  || { fail "F08: gate-generator must target the hooks key of .claude/settings.json"; f08_bad=1; }
# A bare `grep -qi merge` was satisfied by the CI-workflow line "Merge into existing
# files" — unrelated prose kept the settings.json requirement's own guard green. Both
# load-bearing clauses are required instead: never-overwrite, and keep the siblings.
grep -qiE 'MERGE, never overwrite' "$AGENTS_DIR/gate-generator.md" \
  || { fail "F08: gate-generator must instruct MERGE, never overwrite — settings.json also holds permissions and MCP config"; f08_bad=1; }
grep -qiE 'not drop sibling keys' "$AGENTS_DIR/gate-generator.md" \
  || { fail "F08: gate-generator must instruct preserving sibling keys — a hooks-only write destroys permissions and MCP config"; f08_bad=1; }
# Requires the INSTRUCTION, not the word. Mutation W13 deleted "PowerShell variant of
# every generated hook" and a bare `grep -qi powershell` stayed green, because the
# sentence explaining *why* still mentioned PowerShell.
#
# Matching the phrase alone was NEGATION-BLIND ("Do not emit a PowerShell variant"
# satisfied it), and counting affirmative-minus-negated occurrences was blind in BOTH
# directions: Codex passed "A PowerShell variant is unnecessary; emit only the POSIX
# hook command" and FAILED the perfectly good "Do not omit Windows support; emit a
# PowerShell variant…" (N4, Q3).
#
# Anchored on a sentence-initial IMPERATIVE instead. A prohibition cannot take that
# form — it has to begin "Do not"/"Never" — so the anchor is negation-proof by
# construction rather than by trying to parse sentiment out of a fragment.
#
# NECESSARY, NOT SUFFICIENT. This proves the instruction is present and affirmative. It
# cannot prove the agent OBEYS it, because gate-generator's output is produced by a
# model. That clause is recorded NOT MET by class-G means; PHV5-044's runtime proof is
# what would settle it.
# PER-LINE, not sentence-initial-only. The strict anchor rejected the legitimate rewrite
# "For every generated hook, also emit a PowerShell variant." (Codex round 3). A line
# carrying the instruction counts; a line carrying a negation does not — which keeps
# "Do not omit Windows support." on its own line harmless while rejecting
# "Do not emit a PowerShell variant". Comments and fenced examples are excluded so a
# sample block cannot stand in for an instruction.
f08_ps=$(awk '/^```/ { inf = !inf; next } inf { next }
              /^[[:space:]]*(#|>|\|)/ { next }
              tolower($0) ~ /emit a powershell variant/ &&
              tolower($0) !~ /(do not|don.t|never|avoid|no need|omit the)[^.]{0,30}emit/ { n++ }
              END { print n+0 }' "$AGENTS_DIR/gate-generator.md")
if [ "${f08_ps:-0}" -lt 1 ]; then
  fail "F08: gate-generator carries no affirmative 'emit a PowerShell variant' instruction outside comments and examples — Windows without Git Bash dispatches through PowerShell"
  f08_bad=1
fi
[ "$f08_bad" -eq 0 ] && pass "F08: gate-generator targets settings.json, merges, and carries an affirmative PowerShell-variant imperative (necessary, not sufficient)"

# --- F28: "Auto-invoked" is a claim a skill cannot make about itself, and the
#     reverse sweep is the half that mattered: three of the five knowledge skills
#     were referenced by NOTHING, so they shipped and could never load.
if grep -rn 'Auto-invoked' "$SKILLS_DIR"/*/SKILL.md >/dev/null 2>&1; then
  fail "F28: 'Auto-invoked' phrasing survives — a skill loads on description match, so the description must carry trigger terms"
else
  pass "F28: no skill asserts its own auto-invocation"
fi
f28_orphans=0
for d in "$SKILLS_DIR"/*/; do
  sk=$(basename "$d")
  # Every skill needs at least one orchestrator outside its own directory, and the
  # reference must be the NAMESPACED name. The `$sk skill` alternative accepted mere
  # prose — "the mcp-research skill" in a sentence counted as wiring (Codex F3) — which
  # is the same class of defect F28 exists to remove. Namespaced form only; a skill name
  # is also required to be a whole token, so `documentation` cannot be satisfied by
  # `documentation-extras`.
  # NEGATED references do not count. "Never invoke `deepgrade:mcp-research`; it is
  # deprecated" satisfied the previous form (Codex N5) — a mention that FORBIDS the skill
  # was read as wiring it. Negated lines are dropped before the search.
  # An explicit ${CLAUDE_PLUGIN_ROOT}/skills/<name>/ path is accepted too: it is a real,
  # unambiguous reference, and rejecting it was over-strict (Codex Q3).
  if ! grep -rhE "deepgrade:$sk([^A-Za-z0-9_-]|\$)|skills/$sk/SKILL\.md" \
         "$AGENTS_DIR" "$COMMANDS_DIR" "$SKILLS_DIR"/*/SKILL.md 2>/dev/null \
       --exclude-dir="$sk" \
       | grep -viE '(never|do not|don'"'"'t|no longer|deprecated|avoid)[^.]{0,60}('"$sk"')' \
       | grep -q .; then
    fail "F28: skill '$sk' has no affirmative reference from any orchestrator — it ships and can never load"
    f28_orphans=1
  fi
done
[ "$f28_orphans" -eq 0 ] && pass "F28: every skill has a namespaced reference from an orchestrator (reverse sweep)"

# --- Clauses that had a correct product implementation but NO falsifying assertion, so
#     the fix could be reverted with the suite still green (Codex F4). Each is a separate
#     conjunct of a Wave 5 row; a clause buried mid-sentence still counts.

# F10 positive: naming the right variable is only half the row — it must be USED, in an
# executable line. Two corrections from Codex: the whole-file grep was satisfied by the
# expression sitting in an HTML comment while both real uses were replaced (N2), and
# demanding the exact `:-$OLDPWD` fallback rejected a plain `${CLAUDE_PROJECT_DIR}`,
# which is all the row actually requires (Q3).
if awk '/^```bash/{inb=1; next} /^```/{inb=0} inb' "$COMMANDS_DIR/plan-export.md" \
     | grep -v '^[[:space:]]*#' | grep -qE '\$\{CLAUDE_PROJECT_DIR(:-[^}]*)?\}'; then
  pass "F10: plan-export resolves the destination through \${CLAUDE_PROJECT_DIR} in an executable line"
else
  fail "F10: plan-export must USE \${CLAUDE_PROJECT_DIR} in a bash block — the absence of \${PROJECT_ROOT}, or a mention in a comment, does not make the path correct"
fi

# F28 positive: a skill loads on DESCRIPTION MATCH, so removing the trigger terms silently
# unloads it. The negative ("Auto-invoked" absent) cannot see that.
f28_desc_bad=0
for d in "$SKILLS_DIR"/*/; do
  sk=$(basename "$d")
  # fm_get, so a folded `description: >-` scalar is read whole rather than truncated at
  # its first physical line (Codex Q3 flagged the old single-line awk as over-strict).
  desc=$(fm_get "$d/SKILL.md" 'description')
  # An explicit non-trigger disclaimer is disqualifying regardless of length: Codex passed
  # "Do not use when writing any code; this skill has no supported trigger" through the
  # previous phrase match (N5).
  if printf '%s' "$desc" | grep -qiE 'no supported trigger|should not load|do not use'; then
    fail "F28: skill '$sk' description states it should NOT load — that is a disclaimer, not a trigger"
    f28_desc_bad=1
  elif [ "${#desc}" -lt 30 ]; then
    # 30, not 40: `Use when setting CI gates.` is a legitimate short description and the
    # old floor rejected it (Codex Q3). The floor exists only to catch a stub.
    fail "F28: skill '$sk' description is ${#desc} chars — too thin to carry trigger terms, so it will not load on match"
    f28_desc_bad=1
  # "Triggers on - create adr, create brd, …" is trigger phrasing too, and richer than
  # "use when". The first version of this regex rejected it — a false positive in a guard
  # written in the same pass that fixed six others. A guard needs a control run as much as
  # the code it guards, and this one got its control from a real subject.
  elif ! printf '%s' "$desc" | grep -qiE 'use (when|when the|for|this)|invoke when|triggers? on|choose this|when (you|stating|writing|auditing|the)'; then
    fail "F28: skill '$sk' description carries no trigger phrasing (\"use when …\") — nothing for the loader to match"
    f28_desc_bad=1
  fi
done
[ "$f28_desc_bad" -eq 0 ] && pass "F28: every skill description carries trigger phrasing the loader can match"

# F30 positive: doc.md was deleted BECAUSE the skill carries the capability. If the skill
# loses its dispatch or plan awareness, the deletion becomes a regression rather than a
# de-duplication, and every existing F30 assertion stays green.
f30_skill="$SKILLS_DIR/documentation/SKILL.md"
f30_pos=0
grep -q 'CLAUDE_SKILL_DIR' "$f30_skill" 2>/dev/null \
  || { fail "F30: documentation skill lost its \${CLAUDE_SKILL_DIR} dispatch — it absorbed the deleted command's job and cannot do it"; f30_pos=1; }
grep -qE '^## Plan awareness' "$f30_skill" 2>/dev/null \
  || { fail "F30: documentation skill lost its Plan awareness section — plan-scoped output was part of what the deleted command did"; f30_pos=1; }
[ "$f30_pos" -eq 0 ] && pass "F30: documentation skill retains the dispatch and plan awareness it absorbed from the deleted command"

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
[ -e "$COMMANDS_DIR/doc.md" ] && { fail "F30: $COMMANDS_DIR/doc.md still exists"; f30_bad=1; }

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

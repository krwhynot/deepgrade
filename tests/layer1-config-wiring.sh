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
  bad_cmd=0
  for tok in $(grep -rhoE '(^|[[:space:]"'"'"'(])/[a-z][a-z-]*' "$TPL_DIR" 2>/dev/null \
               | tr -d ' "'"'"'(' | sort -u); do
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

eol_subjects=0
eol_bad=0
for f in $(git ls-files '*.sh' '*.js' 'tests/fixtures/*' 2>/dev/null); do
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
  echo "$head_txt" | grep -q '`\.sh`' || { echo "$head_txt" | grep -q '\.sh' || rationale_ok=0; }
  echo "$head_txt" | grep -q '\.js' || rationale_ok=0
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

  # Reverse: nothing in scripts/ is unreferenced. This is the direction that stops
  # dead code shipping — the .sh set was orphaned in exactly this way before 4b.
  orphan=0
  for f in scripts/*; do
    [ -e "$f" ] || continue
    b=$(basename "$f")
    echo "$refs" | grep -qxF "$b" || { fail "F06: scripts/$b is not referenced by hooks.json — unwired code must not ship"; orphan=1; }
  done
  [ "$orphan" -eq 0 ] && pass "F06: no orphaned files in scripts/ (reverse sweep)"

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
  if awk '/^```bash/{inb=1; next} /^```/{inb=0} inb' "$f" | sed 's/#.*$//' | grep -qE '(^|[^\\$])\$1\b'; then
    fail "F09: $(basename "$f") uses \$1 inside a bash block — a command body is not a shell script, so \$1 is never set"
    f09_bad=1
  fi
  if awk '/^```bash/{inb=1; next} /^```/{inb=0} inb' "$f" | grep -qE '^[A-Z_]+="\$0"'; then
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
if grep -q '^argument-hint:' "$COMMANDS_DIR/readiness-generate.md"; then
  pass "F11: readiness-generate declares argument-hint"
else
  fail "F11: readiness-generate is missing argument-hint"
fi

# --- F13: the guard must test the directory the loop actually reads. It tested
#     `plans` while iterating `docs/plans/*/`, so on a normal layout the no-argument
#     overview printed "No plans found." and exited.
if grep -qE '^\s*if \[ ! -d "\$PLANS_DIR" \]' "$COMMANDS_DIR/plan-status.md" \
   && grep -qE 'PLANS_DIR="docs/plans"' "$COMMANDS_DIR/plan-status.md"; then
  pass "F13: plan-status guards the same directory it iterates"
else
  fail "F13: plan-status's existence guard and its loop must reference the same directory"
fi

# --- F14: model-invocability, both directions.
f14_bad=0
for c in codebase-gates plan-export readiness-generate; do
  grep -q '^disable-model-invocation: true' "$COMMANDS_DIR/$c.md" \
    || { fail "F14: $c.md must set disable-model-invocation: true"; f14_bad=1; }
done
# Negative, per the §3.8 discovery-path decision: `plan` must stay model-invocable.
grep -q '^disable-model-invocation' "$COMMANDS_DIR/plan.md" \
  && { fail "F14: plan.md must NOT disable model invocation (§3.8 discovery path)"; f14_bad=1; }
[ "$f14_bad" -eq 0 ] && pass "F14: disable-model-invocation on exactly the three side-effectful commands, not on plan"

# --- F15: host-tool portability.
f15_bad=0
if grep -rnE '(^|[^a-z-])tree +-' "$COMMANDS_DIR"/*.md >/dev/null 2>&1; then
  fail "F15: \`tree\` is not present in stock Git Bash"; f15_bad=1
fi
if grep -rn 'python3 -c' "$COMMANDS_DIR"/*.md >/dev/null 2>&1; then
  fail "F15: a bare \`python3 -c\` has no fallback — python3 is absent on many Windows hosts, python on many Linux ones"; f15_bad=1
fi
if grep -rnE '^\s*(EXPORT_DIR|STAGING)="?/tmp/' "$COMMANDS_DIR"/*.md >/dev/null 2>&1; then
  fail "F15: bare /tmp staging — use \${TMPDIR:-\${TEMP:-/tmp}} so Windows hosts and concurrent runs work"; f15_bad=1
fi
if grep -q 'zip -' "$COMMANDS_DIR/plan-export.md" \
   && ! grep -qE 'powershell[^|]*Compress-Archive' "$COMMANDS_DIR/plan-export.md"; then
  # Requires an actual INVOCATION, not the string anywhere in the file: the first
  # version accepted `grep -q 'Compress-Archive'`, which the explanatory comment on
  # the line above satisfies on its own.
  # Mutation history, because the first reading was wrong: W11 "escaped" twice, but
  # not because of that weakness. The mutation replaced only the FIRST occurrence of
  # the cmdlet name, which is the comment — so it deleted a comment, left the
  # invocation intact, and a green guard was the correct answer. An invalid mutant,
  # not a surviving defect. Re-anchored on the invocation three ways (delete the
  # line, swap the cmdlet, replace the branch with `false`): caught on all three.
  fail "F15: plan-export uses \`zip\` with no PowerShell Compress-Archive invocation — stock Windows has no zip"; f15_bad=1
fi
[ "$f15_bad" -eq 0 ] && pass "F15: no tree, no unguarded python3, no bare /tmp staging, zip has a fallback"

# --- F08: gate-generator writes hooks for a PROJECT, so the target is the `hooks`
#     key of .claude/settings.json. hooks/hooks.json is the PLUGIN-side location and
#     is not read from a project directory, so hooks written there never fire.
f08_bad=0
if grep -q '\.claude/hooks/hooks\.json' "$AGENTS_DIR/gate-generator.md"; then
  fail "F08: gate-generator targets .claude/hooks/hooks.json — not read from a project dir, so generated hooks are inert"
  f08_bad=1
fi
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
grep -qiE 'PowerShell variant' "$AGENTS_DIR/gate-generator.md" \
  || { fail "F08: gate-generator must instruct emitting a PowerShell variant — Windows without Git Bash dispatches through it"; f08_bad=1; }
[ "$f08_bad" -eq 0 ] && pass "F08: gate-generator targets settings.json, merges, and emits a PowerShell variant"

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
  # Every skill needs at least one orchestrator outside its own directory.
  if ! grep -rl "deepgrade:$sk\|$sk skill" "$AGENTS_DIR" "$COMMANDS_DIR" "$SKILLS_DIR"/*/SKILL.md 2>/dev/null \
       | grep -qv "$SKILLS_DIR/$sk/"; then
    fail "F28: skill '$sk' is referenced by no orchestrator — it ships and can never load"
    f28_orphans=1
  fi
done
[ "$f28_orphans" -eq 0 ] && pass "F28: every skill has at least one orchestrator (reverse-reference sweep)"

# ===========================================================================
# 18. F30 stale-reference sweep
#
# The Wave 5 acceptance row is its own line and it is class G: "no `/deepgrade:doc`
# or `commands/doc.md` string survives anywhere". NO guard existed, and I had marked
# F30 closed on the strength of having deleted the file. Two references survived.
#
# "Anywhere" needs a subject scope, because two of the surviving references are
# HISTORY and rewriting them would be falsification, not a fix. Both exemptions below
# are therefore STRUCTURAL and self-expiring — neither is a hardcoded pass, and each
# fires if the condition that justifies it is removed.
# ===========================================================================
echo ""
echo "--- F30 stale-reference sweep ---"

f30_bad=0
[ -e "$COMMANDS_DIR/doc.md" ] && { fail "F30: $COMMANDS_DIR/doc.md still exists"; f30_bad=1; }

# Subject set: every tracked .md OUTSIDE this plan's own artifacts. A plan document
# that says "delete /deepgrade:doc" must be able to name it; product surface must not.
f30_subjects=$(git ls-files '*.md' 2>/dev/null \
  | grep -v '^docs/plans/' \
  | grep -v '^docs/specs/plugin-hardening-v5\.md$')
f30_count=$(printf '%s\n' "$f30_subjects" | grep -c . || true)
# Floor, per the recurring-vacuous-pass lesson: if the derivation matches almost
# nothing, a clean sweep proves nothing.
if [ "$f30_count" -lt 10 ]; then
  fail "F30: subject set is only $f30_count files — the derivation collapsed, so a pass here would be vacuous"
  f30_bad=1
fi

for f in $f30_subjects; do
  [ -f "$f" ] || continue
  grep -qE '/deepgrade:doc\b|commands/doc\.md' "$f" 2>/dev/null || continue
  case "$f" in
    "$CHANGELOG")
      # A changelog's released-version entries are immutable: 4.31.0 genuinely DID ship
      # /deepgrade:doc. Exempt a hit only when it sits under a `## X.Y.Z (date)` heading.
      # A hit in an Unreleased section, or in prose outside any release, still fails.
      f30_live=$(awk '
        /^## [0-9]+\.[0-9]+\.[0-9]+[[:space:]]*\(/ { rel=1; next }
        /^## / { rel=0; next }
        /\/deepgrade:doc|commands\/doc\.md/ { if (!rel) printf "%d ", FNR }
      ' "$f")
      if [ -n "$f30_live" ]; then
        fail "F30: $f references /deepgrade:doc outside a released-version entry (line(s): $f30_live)"
        f30_bad=1
      fi
      ;;
    docs/specs/mcp-research-integration.md)
      # Shipped-feature spec. The F30 banner marks the doc.md half as history; the
      # exemption is conditional on that banner existing and naming F30, so deleting
      # the banner re-arms this check rather than silently keeping the pass.
      grep -q 'SUPERSEDED IN PART.*F30' "$f" \
        || { fail "F30: $f names /deepgrade:doc with no F30 superseded marker"; f30_bad=1; }
      ;;
    *)
      fail "F30: $f still references /deepgrade:doc or commands/doc.md — $(grep -nE '/deepgrade:doc\b|commands/doc\.md' "$f" | head -1 | cut -c1-70)"
      f30_bad=1
      ;;
  esac
done

# THE CHANGELOG EXEMPTION EXPIRES AT 5.0.0. PHV5-080 (Wave 8) writes the 5.0.0 entry,
# and until it does, a reader of the 4.31.0 entry is left believing the command exists.
# That is a genuine cross-wave dependency the spec's row did not capture: F30's sweep
# cannot be fully satisfied by Wave 5 alone. Rather than narrow the row, this asserts
# the successor obligation — the moment the version ships as 5.x without a recorded
# removal, this fails.
f30_ver=$(grep -oE '"version"[[:space:]]*:[[:space:]]*"[^"]+"' "$PLUGIN_JSON" 2>/dev/null | grep -oE '[0-9][^"]*')
case "${f30_ver:-0}" in
  [5-9].*|[1-9][0-9].*)
    grep -qiE '(remove|delete|drop)[^.]{0,60}(/deepgrade:doc|`doc\.md`)' "$CHANGELOG" \
      || { fail "F30: version is $f30_ver but $CHANGELOG never records the /deepgrade:doc removal — the 4.31.0 entry now misleads (PHV5-080)"; f30_bad=1; }
    ;;
esac

[ "$f30_bad" -eq 0 ] && pass "F30: no live /deepgrade:doc or commands/doc.md reference (history exempted structurally, exemption expires at 5.0.0)"

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

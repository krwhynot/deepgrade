#!/usr/bin/env bash
# Phase 3 consistency-sweep gate (approach.md §10.5). v9: round 8 defeated the v8 substring
# allowlists with a crafted line carrying benign tokens ("rejected", "round 7"). Exemptions are
# now FILE-SCOPED EXACT FULL LINES in consistency-sweep-exemptions.txt — a new stale statement
# can never match an existing exemption, and every added exemption is visible in the diff.
#
# Exit 0 = clean. Any banned-pattern hit whose full line is not exempted, any missing artifact,
# any missing positive invariant, or any failed negative self-test exits 1.
# Historical records (approach.md §11, codex-review.md, research/) are exempt by design.
set -euo pipefail
cd "$(dirname "$0")"

EXEMPTIONS_FILE="consistency-sweep-exemptions.txt"   # format: <artifact>\t<exact full line>
fail=0
note () { echo "$1"; fail=1; }

REQUIRED=(approach.md acceptance-matrix.md confidence.md status.json manifest.md "$EXEMPTIONS_FILE" consistency-sweep-canonical.json)
for f in "${REQUIRED[@]}"; do
  [ -s "$f" ] || { echo "MISSING/EMPTY required artifact: $f"; exit 1; }
done

BANNED=(
  'raw-payload'
  'degraded (raw|mode)'
  'POSIX_VERIFIED'
  'WINDOWS_ONLY'
  '1,529'
  'layer5-drift'
  'imported in Wave 6|Wave 6 (immutable )?snapshot'
  '13 (standalone-bundle )?inputs|13-input'
  'catalog refresh'
  'git diff -U0'
  'hunk-level'
  'five (relied-upon )?behaviors'
  'seven (relied-upon )?behaviors|SEVEN relied-upon'
  'dual-form pair|dual-entry pair|dual SessionStart|dual-form SessionStart'
  'public HEAD == release SHA'
  'tag SHA == installed content'
  'ref: v5\.0\.0"?}?$|pin.*source to the tag[^'\''s]'
  'tag archive vs|archive of the tag|against the SHA-pinned tag'
)
# Note: 'seven behaviors' is banned because U7 is EIGHT behaviors as of v9; 'tag SHA ==
# installed content' because identity is the normalized installed-tree comparison; ref-only
# pin phrasing because the pin is the full-SHA source object.

is_exempt () { # $1=file  $2=full line content
  grep -qxF "$1	$2" "$EXEMPTIONS_FILE"
}

check_content () { # $1=label(file) $2=content
  local label="$1" content="$2" pat hits line lineno text
  for pat in "${BANNED[@]}"; do
    hits=$(grep -nE "$pat" <<<"$content" || true)
    [ -z "$hits" ] && continue
    while IFS= read -r line; do
      lineno="${line%%:*}"; text="${line#*:}"
      if ! is_exempt "$label" "$text"; then
        note "STALE [$label:$lineno] (pattern: $pat):"
        echo "    $text"
      fi
    done <<<"$hits"
  done
}

APPROACH_CURRENT=$(awk '/^## 11\. Revision History/{exit} {print}' approach.md)
check_content "approach.md" "$APPROACH_CURRENT"
for f in acceptance-matrix.md confidence.md status.json manifest.md; do
  check_content "$f" "$(cat "$f")"
done

# ---- positive invariants ----------------------------------------------------
require () { grep -qE "$2" <<<"$3" || note "INVARIANT MISSING [$1]: $4"; }
require "approach.md" 'eight.{0,30}behaviors|behaviors.{0,30}eight' "$APPROACH_CURRENT" "U7 eight-behavior contract"
require "approach.md" 'occurrence-addressed' "$APPROACH_CURRENT" "occurrence-addressed ledger model"
require "approach.md" '22 pre-reconciliation|22.{0,10}sources' "$APPROACH_CURRENT" "22-source snapshot arithmetic"
require "approach.md" 'zero hook errors' "$APPROACH_CURRENT" "SessionStart zero-error acceptance"
require "approach.md" 'full-SHA|full 40-char SHA' "$APPROACH_CURRENT" "SHA-pinned source object"
require "approach.md" 'installed-tree comparison' "$APPROACH_CURRENT" "executable identity assertion"
require "approach.md" 'two-commit' "$APPROACH_CURRENT" "two-commit release sequence"
require "approach.md" 'lane-qualified|Lane-qualified' "$APPROACH_CURRENT" "lane-qualified parser states"
require "approach.md" 'BLOCKED' "$APPROACH_CURRENT" "G0 BLOCKED terminal outcome (v11)"
require "approach.md" 'catalog.{1,2}s authoritative' "$APPROACH_CURRENT" "catalog-sha identity authority (v11)"
require "status.json" 'EIGHT relied-upon|eight relied-upon' "$(cat status.json)" "eight-behavior U7 in status"
require "status.json" '22 pre-reconciliation|22 tracked pre-reconciliation' "$(cat status.json)" "22-source contract in status"

# ---- structural state validation (v11 — round 10 defeated the v10 substring checks with three
# mutations: CR-1 out of the manifest table but named in prose, a negated acceptance state passing
# the ACCEPTED substring test, and unenumerated pending language; the v10 checks also passed real
# stale v9 state in status.json) ----
APPROACH_VER=$(head -1 approach.md | grep -oE '\*\*v[0-9]+\*\*' | grep -oE 'v[0-9]+' | head -1)
[ -n "$APPROACH_VER" ] || { echo "INVARIANT MISSING: cannot read approach version from header"; exit 1; }
command -v node >/dev/null || { echo "MISSING TOOL: node is required for structural status.json validation"; exit 1; }

check_manifest_cr () { # $1=manifest file — CR-1 must be a ROW of the Change Records table, not a prose mention
  awk '/^## Change Records/{f=1;next} /^## /{f=0} f' "$1" | grep -qE '^\|\s*\[?CR-1\b'
}

check_cr1_decision () { # $1=CR file — anchored State line; Decision section + bold declarations validated
                        # (v12 — round 11 planted '**Rejected by the owner.**' beside the anchored line and passed)
  if ! grep -qE '^\*\*State: ACCEPTED\*\*' "$1"; then return 1; fi
  # v13 — round 12 appended '**State: VOID**' outside the Decision section and passed the verb
  # blacklist. Parse ALL State markers: there must be exactly one, and it must be ACCEPTED.
  # v14 — round 13 evaded the exact-form scan with case ('**STATE: VOID**') and spacing
  # ('**State : VOID**') variants: the scan is now case- and whitespace-insensitive, joins
  # wrapped lines first, and compares the normalized form.
  # v16 — round 15: '**State:** VOID' wraps the label in its own emphasis span, so the value fell
  # outside the match and the marker was invisible. Strip Markdown emphasis delimiters (* _ `)
  # before scanning so label and value normalize together.
  local markers
  markers=$(tr '\n' ' ' < "$1" | tr -d '*_`' | grep -oiE '\bstate[[:space:]]*:[[:space:]]*[A-Za-z-]+' | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')
  if [ "$markers" != "state:accepted" ]; then return 1; fi
  if grep -qiE 'not[ -]accepted|un-?accepted' "$1"; then return 1; fi
  # a bold decision declaration conflicting with ACCEPTED, anywhere in the file
  if grep -qiE '\*\*[^*]*(reject|declin|refus|rescind|revok|overturn|revers|withdraw|retract)[^*]*\*\*' "$1"; then return 1; fi
  # conflicting decision language inside the Decision section itself
  if awk '/^## Decision/{f=1;next} /^## /{f=0} f' "$1" \
     | grep -qiE 'reject|declin|refus|rescind|revok|overturn|revers|withdraw|retract|\bvoid\b|\bpending\b|supersed'; then return 1; fi
  return 0
}

check_status_state () { # $1=status file  $2=approach version token — parse as JSON, bind the state fields
  node -e '
    const fs = require("fs");
    const [file, ver] = process.argv.slice(1);
    // v14 — round 13: JSON.parse silently keeps the LAST duplicate key, so a contradictory
    // duplicate placed before the canonical one vanishes from the parsed view. Parse with a
    // duplicate-key-rejecting recursive-descent parser; duplicates ANYWHERE in either file fail.
    function parseNoDup(text, label) {
      let i = 0;
      function ws() { while (i < text.length && (text[i] === " " || text[i] === "\t" || text[i] === "\n" || text[i] === "\r")) i++; }
      function fail(msg) { throw new Error(label + ": " + msg + " at offset " + i); }
      function str() {
        let j = i + 1;
        while (j < text.length) {
          if (text[j] === "\\") { j += 2; continue; }
          if (text[j] === "\"") break;
          j++;
        }
        const out = JSON.parse(text.slice(i, j + 1));
        i = j + 1;
        return out;
      }
      function val() {
        ws();
        const c = text[i];
        if (c === "{") return obj();
        if (c === "[") return arr();
        if (c === "\"") return str();
        const m = /^(-?(0|[1-9]\d*)(\.\d+)?([eE][+-]?\d+)?|true|false|null)/.exec(text.slice(i));
        if (!m) fail("bad value");
        i += m[0].length;
        return m[0] === "true" ? true : m[0] === "false" ? false : m[0] === "null" ? null : Number(m[0]);
      }
      function obj() {
        // null-prototype object: plain assignment for every key, no setter semantics.
        // A literal __proto__ key is ALSO rejected outright — via {} it silently sets the
        // prototype, vanishes from JSON.stringify, and is invisible to hasOwnProperty, so it
        // could carry state the canonical comparison never sees.
        i++; const o = Object.create(null); ws();
        if (text[i] === "}") { i++; return o; }
        for (;;) {
          ws();
          if (text[i] !== "\"") fail("expected key");
          const k = str(); ws();
          if (text[i] !== ":") fail("expected colon"); i++;
          const v = val();
          if (k === "__proto__" || k === "constructor" || k === "prototype") fail("FORBIDDEN KEY " + JSON.stringify(k));
          if (Object.prototype.hasOwnProperty.call(o, k)) fail("DUPLICATE KEY " + JSON.stringify(k));
          o[k] = v; ws();
          if (text[i] === ",") { i++; continue; }
          if (text[i] === "}") { i++; return o; }
          fail("bad object");
        }
      }
      function arr() {
        i++; const a = []; ws();
        if (text[i] === "]") { i++; return a; }
        for (;;) {
          a.push(val()); ws();
          if (text[i] === ",") { i++; continue; }
          if (text[i] === "]") { i++; return a; }
          fail("bad array");
        }
      }
      const v = val(); ws();
      if (i !== text.length) fail("trailing content");
      return v;
    }
    let s; try { s = parseNoDup(fs.readFileSync(file, "utf8"), "status.json"); }
    catch (e) { console.error(e.message); process.exit(1); }
    const errs = [];
    const pp = (s.phases || {}).pre_plan || {};
    if (pp.approach_version !== ver) errs.push(`approach_version "${pp.approach_version}" != header ${ver}`);
    const m = String(pp.status || "").match(/v(\d+)/);
    if (!m || "v" + m[1] !== ver) errs.push(`pre_plan.status "${pp.status}" does not carry ${ver}`);
    const rounds = (s.external_review || {}).rounds || [];
    const lastEntry = rounds.length ? rounds[rounds.length - 1] : {};
    const last = lastEntry.round || 0;
    const next = String((s.external_review || {}).next || "");
    // v18 — round 17 reached GO (40/40). The loop terminates on a GO verdict, so next no longer
    // points at another round; it records the terminal state. GO = the last round has score >= 36
    // with a GO verdict that is not NO-GO.
    const lastVerdict = String(lastEntry.verdict || "");
    const isGo = typeof lastEntry.score === "number" && lastEntry.score >= 36
                 && /\bGO\b/.test(lastVerdict) && !/NO-?GO/i.test(lastVerdict);
    if (isGo) {
      if (!/terminal|GO reached|scope lock passes/i.test(next))
        errs.push(`GO reached at round ${last}; external_review.next must record the terminal state, got "${next}"`);
    } else {
      // v12 — round 11 passed "round N is not next; ..." through the old .includes() check
      const expected = `round ${last + 1} against ${ver}`;
      if (next !== expected) errs.push(`external_review.next must be exactly "${expected}", got "${next}"`);
    }
    // v13 — round 12 defeated the v12 affirmative-token regexes with pure negations ("not
    // conditionally blocking", "Wave 0 does not pause", "SHA is not authoritative"): any
    // word-presence check admits its own negation. The locked contracts are therefore bound by
    // exact canonical VALUE against consistency-sweep-canonical.json — recursive value equality,
    // order-insensitive for object members and order-preserving for arrays (see deepEq below;
    // v16 corrected this from the earlier order-sensitive "byte-for-byte" wording after round 15).
    // This extends the pattern external_review.next already used (which has survived every round).
    // Changing a locked contract legitimately requires updating the canonical file in the same
    // diff; that visibility is the design.
    let canon;
    try { canon = parseNoDup(fs.readFileSync("consistency-sweep-canonical.json", "utf8"), "canonical"); }
    catch (e) { console.error(e.message); process.exit(1); }
    // v16 — round 15: JSON.stringify equality is property-ORDER-sensitive, so a value-preserving
    // reorder produced a false RED, contradicting §10.5 ("semantics live in the values"). Deep
    // equality is order-insensitive for object members and order-PRESERVING for arrays (array
    // order IS semantic — e.g. G0.terminal_states).
    function deepEq(a, b) {
      if (a === b) return true;
      if (typeof a !== typeof b) return false;
      if (a === null || b === null) return a === b;
      const aArr = Array.isArray(a), bArr = Array.isArray(b);
      if (aArr !== bArr) return false;
      if (aArr) {
        if (a.length !== b.length) return false;
        for (let k = 0; k < a.length; k++) if (!deepEq(a[k], b[k])) return false;
        return true;
      }
      if (typeof a !== "object") return a === b;
      const ak = Object.keys(a), bk = Object.keys(b);
      if (ak.length !== bk.length) return false;
      for (const k of ak) {
        if (!Object.prototype.hasOwnProperty.call(b, k)) return false;
        if (!deepEq(a[k], b[k])) return false;
      }
      return true;
    }
    const eq = (a, b) => deepEq(a, b);
    // v14 — round 13: .find() validated only the FIRST matching entry, so a second contradictory
    // U6/G0 passed. Exactly one of each is required, and no id may repeat in either array.
    const u6s = (s.non_blocking_unknowns || []).filter(u => u.id === "U6");
    if (u6s.length !== 1) errs.push("exactly one U6 entry required, found " + u6s.length);
    else if (!eq(u6s[0], canon.U6)) errs.push("U6 differs from its canonical locked value (consistency-sweep-canonical.json)");
    const g0s = (s.blocking_gates || []).filter(g => g.id === "G0");
    if (g0s.length !== 1) errs.push("exactly one G0 entry required, found " + g0s.length);
    else if (!eq(g0s[0], canon.G0)) errs.push("G0 differs from its canonical locked value (consistency-sweep-canonical.json)");
    for (const pair of [["non_blocking_unknowns", s.non_blocking_unknowns || []], ["blocking_gates", s.blocking_gates || []]]) {
      const seen = new Set();
      for (const it of pair[1]) {
        // ids must be primitive strings: object ids evade both Set dedup (reference equality)
        // and the === filters above.
        if (typeof it.id !== "string") { errs.push("non-string id in " + pair[0]); continue; }
        if (seen.has(it.id)) errs.push("duplicate id " + it.id + " in " + pair[0]);
        seen.add(it.id);
      }
    }
    if (!eq((s.locked_decisions || {}).release_identity, canon.release_identity)) errs.push("release_identity differs from its canonical locked value (consistency-sweep-canonical.json)");
    if (canon.U6.classification !== "conditionally-blocking") errs.push("canonical U6.classification is not the locked enum value");
    if (!Array.isArray(canon.G0.terminal_states) || !canon.G0.terminal_states.some(t => /^BLOCKED/.test(String(t)))) errs.push("canonical G0.terminal_states lacks a BLOCKED entry");
    const pend = /acceptance requested|awaiting[ _]owner|owner decision pending|acceptance pending|pending acceptance|OPEN: owner/i;
    if (pend.test(JSON.stringify(s))) errs.push("pending-acceptance phrasing present in status.json");
    if (errs.length) { console.error(errs.join("\n")); process.exit(1); }
  ' "$1" "$2"
}

check_manifest_cr manifest.md || note "STRUCTURAL [manifest.md]: CR-1 is not a row of the Change Records table"
check_cr1_decision changes/CR-1.md || note "STRUCTURAL [changes/CR-1.md]: anchored '**State: ACCEPTED**' line missing or negative acceptance phrasing present"
check_status_state status.json "$APPROACH_VER" || note "STRUCTURAL [status.json]: state binding failed (details above)"
if grep -nEi 'acceptance requested|awaiting[ _]owner|owner decision pending|acceptance pending|pending acceptance|OPEN: owner' manifest.md; then
  note "STALE [manifest.md]: pre-acceptance phrasing survives despite CR-1"
fi

# ---- negative self-tests: all known bypass probes MUST be flagged -----------
SELFTEST_FIXTURES=(
  'Round 7 contract: POSIX_VERIFIED is the release state'
  'The source bundle is 13 inputs, proved by inventory'
  'Current mode was not CI_ONLY; use WINDOWS_ONLY'
  'Current runtime contract: the dual-entry pair remains active on healthy hosts; round 7 rejected only its unsupported-host behavior.'
  'Identity: normalized installed-tree comparison - tag archive vs installPath, cache metadata excluded'
)
for fixture in "${SELFTEST_FIXTURES[@]}"; do
  caught=0
  for pat in "${BANNED[@]}"; do
    if grep -qE "$pat" <<<"$fixture" && ! is_exempt "SELFTEST" "$fixture"; then caught=1; break; fi
  done
  [ "$caught" -eq 1 ] || { echo "SELF-TEST FAILED — bypass probe not flagged: $fixture"; exit 1; }
done

# Round 10's three structural mutations, embedded as fixture files the validators must reject:
STRUCT_TMP=$(mktemp -d)
trap 'rm -rf "$STRUCT_TMP"' EXIT
printf '## Change Records\n\n| CR | Date | Summary |\n|----|------|---------|\n\nCR-1 is described in prose elsewhere.\n' > "$STRUCT_TMP/manifest-probe.md"
if check_manifest_cr "$STRUCT_TMP/manifest-probe.md"; then
  echo "SELF-TEST FAILED — prose-only CR-1 passed the table-row check"; exit 1
fi
printf '# CR-1\n\n**State: ACCEPTED**\n\nThe owner decision: NOT ACCEPTED.\n' > "$STRUCT_TMP/cr1-probe.md"
if check_cr1_decision "$STRUCT_TMP/cr1-probe.md"; then
  echo "SELF-TEST FAILED — negated acceptance passed the decision check"; exit 1
fi
cat > "$STRUCT_TMP/status-probe.json" <<'EOF'
{"phases":{"pre_plan":{"status":"v9_revised_awaiting_round9","approach_version":"v9"}},
 "external_review":{"rounds":[{"round":9}],"next":"round 10 against v10"},
 "non_blocking_unknowns":[{"id":"U6","blocks":"nothing"}],
 "blocking_gates":[{"id":"G0"}],
 "locked_decisions":{"release_identity":"tag archive vs installPath"},
 "note":"owner decision pending"}
EOF
if check_status_state "$STRUCT_TMP/status-probe.json" "$APPROACH_VER" 2>/dev/null; then
  echo "SELF-TEST FAILED — stale/pending status fixture passed structural validation"; exit 1
fi

# Round 11's five mutations (v12), generated from the LIVE artifacts so the fixtures cannot go stale.
# The unmutated files are the positive control (validated above); each single mutation must flip the result.
mutate_status () { # $1=mutation id  $2=output path
  node -e '
    const fs = require("fs");
    const [mut, out] = process.argv.slice(1);
    const s = JSON.parse(fs.readFileSync("status.json", "utf8"));
    if (mut === "rid")  s.locked_decisions.release_identity = "Catalog ref is authoritative";
    if (mut === "u6")   s.non_blocking_unknowns.find(u => u.id === "U6").classification = "non-blocking";
    if (mut === "g0") { const g = s.blocking_gates.find(g => g.id === "G0");
                        g.terminal_states = g.terminal_states.filter(t => !/^BLOCKED/.test(t));
                        g.note += " (BLOCKED was discussed in round 10)"; }
    if (mut === "next") s.external_review.next = "round 999 against v0 (deliberately wrong self-test value)";  // rejected in both in-flight and GO-terminal states
    // round 12 (v13): pure-negation mutations that defeated the v12 affirmative-token regexes
    if (mut === "u6neg")  s.non_blocking_unknowns.find(u => u.id === "U6").classification = "not conditionally blocking";
    if (mut === "u6blk")  s.non_blocking_unknowns.find(u => u.id === "U6").blocks = "lane N is not BLOCKED; this condition never blocks lane selection";
    if (mut === "g0neg") { const g = s.blocking_gates.find(g => g.id === "G0");
                           g.terminal_states = g.terminal_states.map(t => /^BLOCKED/.test(t) ? "BLOCKED (Wave 0 does not pause; no owner CR is required)" : t); }
    if (mut === "ridneg") s.locked_decisions.release_identity = "Catalog SHA is not authoritative; the ref must not resolve to it.";
    // round 13 (v14): parser-semantics bypasses — duplicate entries and duplicate JSON keys
    if (mut === "dupu6") s.non_blocking_unknowns.push({id: "U6", classification: "non-blocking", blocks: "nothing"});
    if (mut === "dupg0") s.blocking_gates.push({id: "G0", terminal_states: ["lane N"], note: "no pause required"});
    // v16 — round 15: these raw-text injections are anchored on the U6 object BOUNDARY (its
    // opening brace), not on a specific key+comma, so a legitimate key reorder of status.json
    // cannot silently no-op them. U6 is flat (no nested braces), so [^{}]* isolates it.
    const injectIntoU6 = (text, insertion) =>
      text.replace(/\{([^{}]*"id":\s*"U6"[^{}]*)\}/, "{" + insertion + "$1}");
    if (mut === "dupkey") {
      let t = fs.readFileSync("status.json", "utf8");
      t = injectIntoU6(t, "\"classification\": \"non-blocking\", ");   // duplicate contradictory key before the canonical one
      fs.writeFileSync(out, t);
      process.exit(0);
    }
    // round 14 pre-abort disclosures: __proto__ key and non-string id
    if (mut === "proto") {
      let t = fs.readFileSync("status.json", "utf8");
      t = injectIntoU6(t, "\"__proto__\": {\"classification\": \"non-blocking\"}, ");
      fs.writeFileSync(out, t);
      process.exit(0);
    }
    if (mut === "objid") s.non_blocking_unknowns.push({id: ["U6"], blocks: "nothing"});
    fs.writeFileSync(out, JSON.stringify(s, null, 2));
  ' "$1" "$2"
}
for mut in rid u6 g0 next u6neg u6blk g0neg ridneg dupu6 dupg0 dupkey proto objid; do
  mutate_status "$mut" "$STRUCT_TMP/status-probe-$mut.json"
  if check_status_state "$STRUCT_TMP/status-probe-$mut.json" "$APPROACH_VER" 2>/dev/null; then
    echo "SELF-TEST FAILED — mutation '$mut' passed structural validation"; exit 1
  fi
done
{ cat changes/CR-1.md; printf '\n**Rejected by the owner.**\n'; } > "$STRUCT_TMP/cr1-r11-rejected.md"
if check_cr1_decision "$STRUCT_TMP/cr1-r11-rejected.md"; then
  echo "SELF-TEST FAILED — round-11 CR-1 'Rejected' declaration passed the decision check"; exit 1
fi
{ cat changes/CR-1.md; printf '\n**State: VOID**\n'; } > "$STRUCT_TMP/cr1-r12-void.md"
if check_cr1_decision "$STRUCT_TMP/cr1-r12-void.md"; then
  echo "SELF-TEST FAILED — round-12 CR-1 second State marker passed the decision check"; exit 1
fi
{ cat changes/CR-1.md; printf '\n**STATE: VOID**\n'; } > "$STRUCT_TMP/cr1-r13-upper.md"
if check_cr1_decision "$STRUCT_TMP/cr1-r13-upper.md"; then
  echo "SELF-TEST FAILED — round-13 uppercase STATE marker passed the decision check"; exit 1
fi
{ cat changes/CR-1.md; printf '\n**State : VOID**\n'; } > "$STRUCT_TMP/cr1-r13-spaced.md"
if check_cr1_decision "$STRUCT_TMP/cr1-r13-spaced.md"; then
  echo "SELF-TEST FAILED — round-13 spaced State marker passed the decision check"; exit 1
fi
{ cat changes/CR-1.md; printf '\n**State:** VOID\n'; } > "$STRUCT_TMP/cr1-r15-emph.md"
if check_cr1_decision "$STRUCT_TMP/cr1-r15-emph.md"; then
  echo "SELF-TEST FAILED — round-15 emphasis-wrapped State marker passed the decision check"; exit 1
fi

# Round 15 POSITIVE control (v16): a value-preserving property reorder of U6 must PASS — the
# equality is order-insensitive for object members. If this fails, the gate is over-strict again.
node -e '
  const fs = require("fs");
  const s = JSON.parse(fs.readFileSync("status.json", "utf8"));
  const i = s.non_blocking_unknowns.findIndex(u => u.id === "U6");
  const u = s.non_blocking_unknowns[i];
  const keys = Object.keys(u).reverse();                       // reorder members, same values
  const r = {}; for (const k of keys) r[k] = u[k];
  s.non_blocking_unknowns[i] = r;
  fs.writeFileSync(process.argv[1], JSON.stringify(s, null, 2));
' "$STRUCT_TMP/status-r15-reorder.json"
if ! check_status_state "$STRUCT_TMP/status-r15-reorder.json" "$APPROACH_VER" 2>/dev/null; then
  echo "SELF-TEST FAILED — value-preserving U6 reorder was rejected (equality is order-sensitive again)"; exit 1
fi

if [ "$fail" -eq 0 ]; then
  echo "CONSISTENCY SWEEP: PASS (exact-line exemptions; invariants present; structural state bound; all bypass probes caught)"
  exit 0
else
  echo "CONSISTENCY SWEEP: FAIL — reconcile the items above or, if a line is a legitimate correction note, add it verbatim to $EXEMPTIONS_FILE (the addition will show in the diff and is reviewed in the round record)."
  exit 1
fi

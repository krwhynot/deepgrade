#!/usr/bin/env bash
# Lockstep release script — step 3 of the split sequence (release -> CI -> split).
#
# Built and tested on the monolith BEFORE plugins/ exists, because the 5.0.0/5.0.1
# incident proved the manual ritual fails at one plugin; it will not survive four.
# Manifests are DISCOVERED, not listed, so the same script runs unchanged when the
# split lands: every tracked .claude-plugin/plugin.json is a lockstep member.
#
# The script never writes CHANGELOG content. The changelog entry is the thinking
# part of a release — 5.0.0's missing breaking-change section was a thinking
# failure, and a script that autogenerates the section would hide the next one.
# It REFUSES to release until the entry exists.
#
# Usage:
#   .github/release.sh check                # preflight only (CI-safe, read-only)
#   .github/release.sh run <new-version>    # full release
#   .github/release.sh run <new-version> --dry-run
#
# Lives in .github/ deliberately: scripts/ is subject to the F06 wiring sweep
# (hooks.json or command invocation), and a human-invoked release tool is neither.

set -uo pipefail
cd "$(dirname "$0")/.."

ERRORS=0
err()  { echo "ERROR: $1"; ERRORS=$((ERRORS + 1)); }
warn() { echo "warn:  $1"; }
note() { echo "  ok:  $1"; }

# --- discovery ---------------------------------------------------------------

manifests() {
  git ls-files '.claude-plugin/plugin.json' '*/.claude-plugin/plugin.json'
}

manifest_version() {
  grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$1" | head -1 | sed 's/.*"\([0-9][^"]*\)"$/\1/'
}

# --- preflight ---------------------------------------------------------------

preflight() {
  # 1. Clean tree. A release from a dirty tree tags a tree that never existed.
  if [ -n "$(git status --porcelain)" ]; then
    err "working tree is not clean — a release must tag a committed tree"
  else
    note "working tree clean"
  fi

  # 2. Lockstep. Every tracked manifest carries the same version.
  local vers v m count=0
  vers=""
  while IFS= read -r m; do
    v=$(manifest_version "$m")
    [ -n "$v" ] || { err "no version parseable from $m"; continue; }
    count=$((count + 1))
    if [ -z "$vers" ]; then vers="$v"
    elif [ "$v" != "$vers" ]; then err "version lockstep broken: $m has $v, expected $vers"
    fi
  done < <(manifests)
  [ "$count" -ge 1 ] || err "no plugin manifests found — discovery is broken, not the repo clean"
  VERSION="$vers"
  [ -n "$VERSION" ] && note "$count manifest(s) in lockstep at $VERSION"

  # 3. The F20A quartet agrees with the manifests — at the repo root and in
  #    EVERY plugin directory. The split gives each plugin its own README and
  #    GUIDE; a missing one is an error, not a skip, or a plugin could drop its
  #    docs and the preflight would go quieter instead of louder.
  if [ -f README.md ]; then
    grep -q "Current: v$VERSION" README.md \
      && note "root README states v$VERSION" \
      || err "root README version drift: expected 'Current: v$VERSION'"
  fi
  local d
  while IFS= read -r m; do
    d=$(dirname "$(dirname "$m")")
    [ "$d" = "." ] && continue
    if [ -f "$d/README.md" ]; then
      grep -q "Current: v$VERSION" "$d/README.md" \
        && note "$d README states v$VERSION" \
        || err "$d README version drift: expected 'Current: v$VERSION'"
    else
      err "$d/README.md is missing — every plugin ships its own quartet"
    fi
    if [ -f "$d/GUIDE.md" ]; then
      grep -q "v$VERSION" "$d/GUIDE.md" \
        && note "$d GUIDE states v$VERSION" \
        || err "$d GUIDE version drift: no v$VERSION found"
    else
      err "$d/GUIDE.md is missing — every plugin ships its own quartet"
    fi
  done < <(manifests)

  # 4. The CHANGELOG has a real entry for this version. This is the check whose
  #    absence shipped 5.0.0 without its breaking-change section.
  if grep -qE "^## $VERSION( |\()" CHANGELOG.md; then
    note "CHANGELOG has a $VERSION entry"
  else
    err "CHANGELOG has no entry for $VERSION — write it before releasing; this script will not write it for you"
  fi

  # 5. Catalog pin coherence. The pin legitimately lags DURING a release (it is
  #    updated after the tag exists), so a mismatch warns rather than refuses —
  #    but silence here is the forgotten-pin failure mode.
  local pin_ref
  pin_ref=$(grep -o '"ref"[[:space:]]*:[[:space:]]*"[^"]*"' .claude-plugin/marketplace.json 2>/dev/null | head -1 | sed 's/.*"\(v[^"]*\)"$/\1/')
  if [ -n "$pin_ref" ] && [ "$pin_ref" != "v$VERSION" ]; then
    warn "catalog pin is $pin_ref but manifests are $VERSION — expected only mid-release, forbidden at steady state"
  elif [ -n "$pin_ref" ]; then
    note "catalog pin matches ($pin_ref)"
  fi
}

# --- release -----------------------------------------------------------------

do_run() {
  local NEW="$1" DRY="${2:-}"
  [ -n "$NEW" ] || { echo "usage: release.sh run <new-version> [--dry-run]"; exit 2; }

  preflight
  [ "$ERRORS" -eq 0 ] || { echo ""; echo "preflight failed with $ERRORS error(s) — nothing was changed"; exit 1; }

  local OLD="$VERSION"
  [ "$NEW" != "$OLD" ] || { echo "ERROR: new version equals current ($OLD)"; exit 1; }
  git rev-parse -q --verify "refs/tags/v$NEW" >/dev/null && { echo "ERROR: tag v$NEW already exists"; exit 1; }
  grep -qE "^## $NEW( |\()" CHANGELOG.md || { echo "ERROR: CHANGELOG has no entry for $NEW — write it first"; exit 1; }

  if [ "$DRY" = "--dry-run" ]; then
    echo ""
    echo "dry run — would do, in order:"
    echo "  1. bump $OLD -> $NEW in: $(manifests | tr '\n' ' ')+ per-plugin README/GUIDE + root README"
    echo "  2. bash tests/run-all.sh  (abort on red)"
    echo "  3. commit 'release: $NEW'; tag -a v$NEW"
    echo "  4. git push origin main --follow-tags; verify remote v$NEW deref"
    echo "  5. pin marketplace.json to v$NEW @ released SHA; commit; push; verify pin == deref"
    exit 0
  fi

  local m d
  while IFS= read -r m; do
    sed -i "s/\"version\": \"$OLD\"/\"version\": \"$NEW\"/" "$m"
    d=$(dirname "$(dirname "$m")")
    [ "$d" = "." ] && continue
    sed -i "s/Current: v$OLD/Current: v$NEW/" "$d/README.md"
    sed -i "s/v$OLD/v$NEW/g" "$d/GUIDE.md"
  done < <(manifests)
  sed -i "s/Current: v$OLD/Current: v$NEW/" README.md

  echo "running the suite against the bumped tree..."
  bash tests/run-all.sh || { echo "ERROR: suite red — release aborted, tree left for inspection"; exit 1; }

  git add -A
  git commit -m "release: $NEW"
  git tag -a "v$NEW" -m "$NEW — see CHANGELOG"
  git push origin main --follow-tags

  local SHA REMOTE
  SHA=$(git rev-parse HEAD)
  REMOTE=$(git ls-remote origin "refs/tags/v$NEW^{}" | cut -f1)
  [ "$REMOTE" = "$SHA" ] || { echo "ERROR: remote tag derefs to $REMOTE, expected $SHA"; exit 1; }

  local PIN_OLD
  PIN_OLD=$(grep -o '"sha"[[:space:]]*:[[:space:]]*"[^"]*"' .claude-plugin/marketplace.json | head -1 | sed 's/.*"\([0-9a-f]\{40\}\)"$/\1/')
  sed -i "s/\"ref\": \"v$OLD\"/\"ref\": \"v$NEW\"/; s/\"sha\": \"$PIN_OLD\"/\"sha\": \"$SHA\"/" .claude-plugin/marketplace.json
  git add .claude-plugin/marketplace.json
  git commit -m "release: pin the catalog to the $NEW release commit"
  git push origin main

  echo ""
  echo "released $NEW: tag v$NEW -> $SHA, catalog pinned, verified against origin"
}

# --- dispatch ----------------------------------------------------------------

case "${1:-}" in
  check)
    preflight
    echo ""
    if [ "$ERRORS" -gt 0 ]; then echo "preflight: $ERRORS error(s)"; exit 1
    else echo "preflight: clean"; exit 0; fi ;;
  run)
    do_run "${2:-}" "${3:-}" ;;
  *)
    echo "usage: release.sh check | run <new-version> [--dry-run]"; exit 2 ;;
esac

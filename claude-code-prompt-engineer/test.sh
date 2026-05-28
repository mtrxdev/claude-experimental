#!/usr/bin/env bash
#
# test.sh — Self-contained test harness for the skill's validators.
#
# Proves validate-skill.sh and validate-claude-md.sh behave correctly across
# positive, negative, boundary, and warning cases. Run in CI on every change.
#
# Usage:   ./test.sh
# Exit:    0 = all tests passed, 1 = one or more failed.
#
# Does NOT hit the network, so it is safe for air-gapped CI. (fetch-docs.sh is
# exercised separately by a smoke test that requires egress — see README.)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_VALIDATOR="$SCRIPT_DIR/scripts/validate-skill.sh"
CLAUDE_VALIDATOR="$SCRIPT_DIR/scripts/validate-claude-md.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass=0
failcount=0

# assert_exit <expected_code> <description> -- <command...>
assert_exit() {
  local expected="$1"; shift
  local desc="$1"; shift
  shift  # drop the literal "--"
  local actual
  "$@" >/dev/null 2>&1
  actual=$?
  if [ "$actual" -eq "$expected" ]; then
    echo "  PASS: $desc (exit $actual)"
    pass=$((pass + 1))
  else
    echo "  FAIL: $desc (expected $expected, got $actual)" >&2
    failcount=$((failcount + 1))
  fi
}

echo "Running validator test suite"
echo

# --- validate-skill.sh ------------------------------------------------------
echo "validate-skill.sh:"

printf -- '---\nname: good-skill\ndescription: A valid skill\n---\nbody line\n' > "$TMP/good.md"
assert_exit 0 "valid skill passes" -- bash "$SKILL_VALIDATOR" "$TMP/good.md"

printf -- '---\nname: bad\n---\nbody\n' > "$TMP/no-desc.md"
assert_exit 2 "missing description fails" -- bash "$SKILL_VALIDATOR" "$TMP/no-desc.md"

printf -- '---\nname: BadName\ndescription: x\n---\nbody\n' > "$TMP/bad-name.md"
assert_exit 2 "uppercase name fails" -- bash "$SKILL_VALIDATOR" "$TMP/bad-name.md"

printf 'no frontmatter here\n' > "$TMP/no-fm.md"
assert_exit 2 "missing frontmatter fails" -- bash "$SKILL_VALIDATOR" "$TMP/no-fm.md"

printf -- '---\nname: x\ndescription: y\nunclosed\n' > "$TMP/unclosed.md"
assert_exit 2 "unclosed frontmatter fails" -- bash "$SKILL_VALIDATOR" "$TMP/unclosed.md"

{ printf -- '---\nname: big\ndescription: x\n---\n'; for i in $(seq 1 501); do echo "l$i"; done; } > "$TMP/big-body.md"
assert_exit 2 "501-line body fails" -- bash "$SKILL_VALIDATOR" "$TMP/big-body.md"

assert_exit 1 "missing file argument errors" -- bash "$SKILL_VALIDATOR"

echo

# --- validate-claude-md.sh --------------------------------------------------
echo "validate-claude-md.sh:"

printf '# P\n## Build\n- cmd: x\n' > "$TMP/good-claude.md"
assert_exit 0 "valid CLAUDE.md passes" -- bash "$CLAUDE_VALIDATOR" "$TMP/good-claude.md"

{ echo "# Big"; for i in $(seq 1 205); do echo "- i$i"; done; } > "$TMP/big-claude.md"
assert_exit 2 "201+ lines fails" -- bash "$CLAUDE_VALIDATOR" "$TMP/big-claude.md"

# Warning cases still exit 0 (warnings are advisory, not failures)
printf '# P\n1. a\n2. b\n3. c\n4. d\n' > "$TMP/proc.md"
assert_exit 0 "long procedure warns but passes" -- bash "$CLAUDE_VALIDATOR" "$TMP/proc.md"

assert_exit 1 "missing file argument errors" -- bash "$CLAUDE_VALIDATOR"

echo

# --- summary ----------------------------------------------------------------
echo

# --- self-check: the skill's own SKILL.md must pass its own validator --------
echo "self-check:"
assert_exit 0 "skill's own SKILL.md passes validate-skill.sh" -- \
  bash "$SKILL_VALIDATOR" "$SCRIPT_DIR/SKILL.md"

echo

# --- optional network smoke test (skipped if no egress) ----------------------
# check-latest.sh and fetch-docs.sh need code.claude.com. We don't fail the
# suite on missing network — air-gapped CI is valid — but we report it.
echo "network smoke (optional):"
if curl --fail --silent --max-time 8 https://code.claude.com/docs/llms.txt >/dev/null 2>&1; then
  assert_exit 0 "check-latest.sh runs with egress" -- bash "$SCRIPT_DIR/scripts/check-latest.sh"
else
  echo "  SKIP: no egress to code.claude.com (air-gapped CI is fine)"
fi

echo

# --- documentation consistency (prevents files from drifting apart) ----------
# This is the guard for "files don't know the current state of other files."
# It fails the build if the docs contradict each other or the filesystem.
echo "doc consistency:"

# 1. SKILL.md and README.md must declare the SAME version.
skill_ver="$(grep -oE '^version:[[:space:]]*[0-9.]+' "$SCRIPT_DIR/SKILL.md" | grep -oE '[0-9.]+' || true)"
readme_ver="$(grep -oE 'version:[[:space:]]*[0-9.]+' "$SCRIPT_DIR/README.md" | grep -oE '[0-9.]+' | head -1 || true)"
if [ -n "$skill_ver" ] && [ "$skill_ver" = "$readme_ver" ]; then
  echo "  PASS: SKILL.md and README.md agree on version ($skill_ver)"
  pass=$((pass + 1))
else
  echo "  FAIL: version drift — SKILL.md=$skill_ver README.md=$readme_ver" >&2
  failcount=$((failcount + 1))
fi

# 2. CHANGELOG's top entry must match the SKILL.md version.
changelog_ver="$(grep -oE '^## \[[0-9.]+\]' "$SCRIPT_DIR/CHANGELOG.md" | head -1 | grep -oE '[0-9.]+' || true)"
if [ "$skill_ver" = "$changelog_ver" ]; then
  echo "  PASS: CHANGELOG top entry matches SKILL.md version ($skill_ver)"
  pass=$((pass + 1))
else
  echo "  FAIL: CHANGELOG top is $changelog_ver but SKILL.md is $skill_ver" >&2
  failcount=$((failcount + 1))
fi

# 3. No orphans: every scripts/ and references/ file must be named in SKILL.md.
orphans=0
for f in "$SCRIPT_DIR"/scripts/*.sh "$SCRIPT_DIR"/references/*.md; do
  base="$(basename "$f")"
  grep -q "$base" "$SCRIPT_DIR/SKILL.md" || { echo "  FAIL: $base exists but is never referenced in SKILL.md" >&2; orphans=$((orphans + 1)); }
done
if [ "$orphans" -eq 0 ]; then
  echo "  PASS: every script and reference is cited in SKILL.md (no orphans)"
  pass=$((pass + 1))
else
  failcount=$((failcount + orphans))
fi

# 4. No dangling references: SKILL.md must not cite a scripts//references/ file that is gone.
missing=0
while IFS= read -r ref; do
  [ -z "$ref" ] && continue
  [ -f "$SCRIPT_DIR/$ref" ] || { echo "  FAIL: SKILL.md cites $ref but it does not exist" >&2; missing=$((missing + 1)); }
done < <(grep -oE '(scripts|references)/[a-z-]+\.(sh|md)' "$SCRIPT_DIR/SKILL.md" | sort -u)
if [ "$missing" -eq 0 ]; then
  echo "  PASS: every file SKILL.md cites actually exists (no dangling refs)"
  pass=$((pass + 1))
else
  failcount=$((failcount + missing))
fi

# 5. The dropped subagent must not be referenced anywhere outside CHANGELOG history.
stale="$(grep -rl 'cc-doc-fetcher' "$SCRIPT_DIR" 2>/dev/null | grep -v CHANGELOG | grep -v test.sh || true)"
if [ -z "$stale" ]; then
  echo "  PASS: no stale cc-doc-fetcher references outside CHANGELOG history"
  pass=$((pass + 1))
else
  echo "  FAIL: stale subagent references in: $stale" >&2
  failcount=$((failcount + 1))
fi

echo

# --- summary ----------------------------------------------------------------
total=$((pass + failcount))
echo "-----------------------------------------"
if [ "$failcount" -gt 0 ]; then
  echo "RESULT: $failcount/$total FAILED"
  exit 1
fi
echo "RESULT: $total/$total passed"
exit 0
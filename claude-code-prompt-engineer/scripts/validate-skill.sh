#!/usr/bin/env bash
#
# validate-skill.sh — Lint a SKILL.md against the official Agent Skills rules.
#
# Rules enforced (sourced from code.claude.com/docs/en/skills.md and the
# platform Skill authoring best-practices page):
#   - File exists and is readable
#   - Has YAML frontmatter delimited by --- ... ---
#   - Frontmatter contains a non-empty `description`
#   - `name` (if present): <=64 chars, lowercase/numbers/hyphens only
#   - `description`: <= 1024 chars
#   - Body (everything after frontmatter): <= 500 lines
#
# Usage:
#   ./validate-skill.sh path/to/SKILL.md
#
# Exit codes:
#   0  passed (warnings allowed)
#   1  bad arguments
#   2  one or more hard rules failed

set -euo pipefail

fail=0
warn=0

err()  { echo "  FAIL: $*" >&2; fail=$((fail + 1)); }
note() { echo "  WARN: $*";     warn=$((warn + 1)); }
ok()   { echo "  ok:   $*"; }

main() {
  local file="${1:-}"
  if [ -z "$file" ]; then
    echo "usage: $0 path/to/SKILL.md" >&2
    exit 1
  fi
  if [ ! -r "$file" ]; then
    echo "error: cannot read '$file'" >&2
    exit 1
  fi

  echo "Validating $file"

  # --- Frontmatter presence -------------------------------------------------
  # Frontmatter must start on line 1 with '---' and have a closing '---'.
  if [ "$(head -n 1 "$file")" != "---" ]; then
    err "no YAML frontmatter: line 1 must be '---'"
    report; return
  fi

  # Line number of the closing delimiter (first '---' after line 1).
  local close_line
  close_line="$(awk 'NR>1 && /^---[[:space:]]*$/ {print NR; exit}' "$file")"
  if [ -z "$close_line" ]; then
    err "frontmatter is not closed with a second '---'"
    report; return
  fi
  ok "frontmatter delimited (lines 1-$close_line)"

  # Extract frontmatter body (between the two delimiters).
  local fm
  fm="$(sed -n "2,$((close_line - 1))p" "$file")"

  # --- description ----------------------------------------------------------
  local desc
  desc="$(printf '%s\n' "$fm" | sed -n 's/^description:[[:space:]]*//p' | head -n 1)"
  if printf '%s\n' "$fm" | grep -qE '^description:'; then
    # description present; if it's a folded block (>) the value may be empty on
    # the same line, which is valid — only flag if there's no description key.
    ok "description key present"
    local dlen=${#desc}
    if [ "$dlen" -gt 1024 ]; then
      err "description exceeds 1024 chars ($dlen)"
    fi
  else
    err "missing required 'description' field in frontmatter"
  fi

  # --- name (optional, but validated if present) ----------------------------
  local name
  name="$(printf '%s\n' "$fm" | sed -n 's/^name:[[:space:]]*//p' | head -n 1)"
  if [ -n "$name" ]; then
    local nlen=${#name}
    if [ "$nlen" -gt 64 ]; then
      err "name exceeds 64 chars ($nlen)"
    fi
    if ! printf '%s' "$name" | grep -qE '^[a-z0-9-]+$'; then
      err "name must be lowercase letters, numbers, hyphens only: '$name'"
    else
      ok "name '$name' is valid"
    fi
  else
    note "no 'name' field (optional; directory name will be used)"
  fi

  # --- Body length ----------------------------------------------------------
  local body_lines total
  total="$(wc -l < "$file" | tr -d ' ')"
  body_lines=$((total - close_line))
  if [ "$body_lines" -gt 500 ]; then
    err "body is $body_lines lines (>500). Move detail into references/."
  else
    ok "body is $body_lines lines (<=500)"
  fi

  report
}

# Print the result summary and return 2 on failure, 0 otherwise.
# Returns (does not exit) so callers using `report; return` have no dead code.
report() {
  echo
  if [ "$fail" -gt 0 ]; then
    echo "RESULT: FAILED ($fail error(s), $warn warning(s))"
    return 2
  fi
  echo "RESULT: PASSED ($warn warning(s))"
  return 0
}

main "$@"
exit $?
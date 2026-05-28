#!/usr/bin/env bash
#
# validate-claude-md.sh — Lint a CLAUDE.md against official guidance.
#
# Rules (sourced from code.claude.com/docs/en/memory.md and best-practices.md):
#   HARD:
#     - File exists and is readable
#     - <= 200 lines (docs: "target under 200 lines")
#   WARN (heuristic anti-patterns — judgment required, not auto-fail):
#     - Long multi-step procedures (numbered lists of 3+ consecutive items)
#       -> these belong in a skill, not CLAUDE.md
#     - Prose paragraphs (non-bulleted lines > 120 chars)
#       -> docs favor headers + bullets over dense prose
#
# Usage:
#   ./validate-claude-md.sh path/to/CLAUDE.md
#
# Exit codes:
#   0  passed (warnings allowed)
#   1  bad arguments
#   2  hard rule failed

set -euo pipefail

fail=0
warn=0

err()  { echo "  FAIL: $*" >&2; fail=$((fail + 1)); }
note() { echo "  WARN: $*";     warn=$((warn + 1)); }
ok()   { echo "  ok:   $*"; }

main() {
  local file="${1:-}"
  if [ -z "$file" ]; then
    echo "usage: $0 path/to/CLAUDE.md" >&2
    exit 1
  fi
  if [ ! -r "$file" ]; then
    echo "error: cannot read '$file'" >&2
    exit 1
  fi

  echo "Validating $file"

  # --- HARD: line count -----------------------------------------------------
  local lines
  lines="$(wc -l < "$file" | tr -d ' ')"
  if [ "$lines" -gt 200 ]; then
    err "$lines lines (>200). Move procedures to skills, reference docs to links."
  else
    ok "$lines lines (<=200)"
  fi

  # --- WARN: long numbered procedure ----------------------------------------
  # Count the longest run of consecutive lines beginning with "N." (1-9).
  local max_run
  max_run="$(awk '
    /^[[:space:]]*[1-9][0-9]?\./ { run++; if (run > max) max = run; next }
    { run = 0 }
    END { print max + 0 }
  ' "$file")"
  if [ "$max_run" -ge 3 ]; then
    note "found a $max_run-step numbered procedure; multi-step procedures belong in a skill"
  else
    ok "no long numbered procedures"
  fi

  # --- WARN: dense prose ----------------------------------------------------
  # Non-bullet, non-header lines longer than 120 chars suggest prose paragraphs.
  local prose
  prose="$(awk '
    /^[[:space:]]*[-*#>|]/ { next }   # skip bullets, headers, quotes, tables
    /^[[:space:]]*$/        { next }   # skip blank
    /^[[:space:]]*```/      { next }   # skip code fences
    { if (length($0) > 120) c++ }
    END { print c + 0 }
  ' "$file")"
  if [ "$prose" -gt 0 ]; then
    note "$prose long prose line(s) (>120 chars); prefer headers + bullets"
  else
    ok "no dense prose paragraphs"
  fi

  echo
  if [ "$fail" -gt 0 ]; then
    echo "RESULT: FAILED ($fail error(s), $warn warning(s))"
    exit 2
  fi
  echo "RESULT: PASSED ($warn warning(s))"
  exit 0
}

main "$@"
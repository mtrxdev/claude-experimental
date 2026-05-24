#!/usr/bin/env bash
set -euo pipefail

SKILL="skills/meta-prompt.md"
FAIL=0

pass() { echo "✓ $1"; }
fail() { echo "✗ $1"; FAIL=1; }

check_present() {
  local desc="$1" pattern="$2"
  grep -qE "$pattern" "$SKILL" && pass "$desc" || fail "$desc"
}

check_absent() {
  local desc="$1" pattern="$2"
  grep -qE "$pattern" "$SKILL" && fail "$desc (found — should be absent)" || pass "$desc"
}

echo "=== meta-prompt smoke ==="
echo "target: $SKILL"
echo ""

# File
[ -f "$SKILL" ] && pass "file exists" || { echo "✗ not found: $SKILL"; exit 1; }

# Frontmatter
check_present "frontmatter: name"        "^name: meta-prompt"
check_present "frontmatter: description" "^description: "

# Required sections
check_present "section: SCOPE"           "^## SCOPE"
check_present "section: BEFORE DRAFTING" "^## BEFORE DRAFTING"
check_present "section: ROLE"            "^## ROLE"
check_present "section: QUESTIONS"       "^## QUESTIONS"
check_present "section: TOOL CAPABILITIES" "^## TOOL CAPABILITIES"
check_present "section: FETCH DOCS"      "^## FETCH DOCS"
check_present "section: DRAFT"           "^## DRAFT"
check_present "section: DELIVER"         "^## DELIVER"

# Constraints
check_absent  "no XML tags"              "<[a-zA-Z][^>]*>"
check_present "Four Ds present"          "Four Ds"
check_present "structured choices"       "numbered"
check_present "out-of-scope template"    "cannot be fixed at the prompt level"
check_present "stop directive"           "Then stop"
check_present "user_input tool"          "user_input"

# Self-awareness
check_present "references orchestration" "meta-prompt-orchestration"
check_present "references project-instr" "meta-prompt-project-instruction"

# URL coverage
check_present "URL: models"             "about-claude/models/overview"
check_present "URL: tool-use overview"  "agents-and-tools/tool-use/overview"
check_present "URL: web search"         "web-search-tool"
check_present "URL: code execution"     "code-execution-tool"
check_present "URL: computer use"       "computer-use-tool"
check_present "URL: release notes"      "release-notes/overview"
check_present "URL: extended thinking"  "extended-thinking"

echo ""
echo "=== orchestration smoke ==="
ORCH="skills/meta-prompt-orchestration.md"
echo "target: $ORCH"
echo ""

[ -f "$ORCH" ] && pass "file exists" || { echo "✗ not found: $ORCH"; FAIL=1; }

check_file() {
  local desc="$1" pattern="$2" file="$3" expect="${4:-present}"
  if grep -qE "$pattern" "$file"; then
    [ "$expect" = "present" ] && pass "$desc" || { fail "$desc (found — should be absent)"; }
  else
    [ "$expect" = "present" ] && fail "$desc" || pass "$desc"
  fi
}

# Structure
check_file "H1 title"          "^# meta-prompt"          "$ORCH"
check_file "state 1: RECEIVE"  "^1\. RECEIVE"            "$ORCH"
check_file "state 2: ROLE"     "^2\. IDENTIFY ROLE"      "$ORCH"
check_file "state 3: GATHER"   "^3\. GATHER INFO"        "$ORCH"
check_file "state 4: TOOL"     "^4\. TOOL CHECK"         "$ORCH"
check_file "state 5: FETCH"    "^5\. FETCH DOCS"         "$ORCH"
check_file "state 6: FOUR Ds"  "^6\. FOUR Ds CHECK"      "$ORCH"
check_file "state 7: STRUCTURE" "^7\. CHOOSE STRUCTURE"  "$ORCH"
check_file "state 8: DRAFT"    "^8\. DRAFT"              "$ORCH"
check_file "state 9: DELIVER"  "^9\. DELIVER"            "$ORCH"
check_file "loop map section"  "^## Loop map"            "$ORCH"
check_file "arrow syntax"      "→"                        "$ORCH"
check_file "STOP markers"      "STOP"                     "$ORCH"

# Fences: exactly 4 top-level code fences (≤3 leading spaces)
FENCE_COUNT=$(grep -cE '^ {0,3}```' "$ORCH" || true)
[ "$FENCE_COUNT" -eq 4 ] && pass "4 top-level code fences (2 paired blocks)" \
                           || fail "expected 4 top-level fences, got $FENCE_COUNT"

# No XML tags
check_file "no XML tags"        "<[a-zA-Z][^>]*>"            "$ORCH" absent
check_file "self-identifies"    "Companion to"               "$ORCH"
check_file "references skill"   "meta-prompt\.md"            "$ORCH"

echo ""
if [ "$FAIL" -eq 0 ]; then
  echo "ALL CHECKS PASSED"
else
  echo "CHECKS FAILED: $FAIL"
  exit 1
fi

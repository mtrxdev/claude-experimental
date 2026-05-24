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

# URL coverage
check_present "URL: models"             "about-claude/models/overview"
check_present "URL: tool-use overview"  "agents-and-tools/tool-use/overview"
check_present "URL: web search"         "web-search-tool"
check_present "URL: code execution"     "code-execution-tool"
check_present "URL: computer use"       "computer-use-tool"
check_present "URL: release notes"      "release-notes/overview"
check_present "URL: extended thinking"  "extended-thinking"

echo ""
if [ "$FAIL" -eq 0 ]; then
  echo "ALL CHECKS PASSED"
else
  echo "CHECKS FAILED: $FAIL"
  exit 1
fi

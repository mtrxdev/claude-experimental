#!/usr/bin/env bash
#
# fetch-docs.sh — Pull fresh snapshots of the core Claude Code doc pages.
#
# Source of truth: https://code.claude.com/docs/llms.txt
# Writes one .md per page into the directory given as $1 (default: ./snapshots).
#
# Usage:
#   ./fetch-docs.sh [output_dir]
#
# Exit codes:
#   0  all pages fetched
#   1  bad arguments / environment
#   2  one or more pages failed to fetch

set -euo pipefail

readonly BASE="https://code.claude.com/docs/en"
readonly INDEX="https://code.claude.com/docs/llms.txt"

# Core pages a prompt engineer needs grounded. Keep this list short and curated;
# the full index has ~60 pages and caching all of them defeats the purpose.
readonly PAGES=(
  best-practices
  memory
  skills
  features-overview
  common-workflows
  sub-agents
  hooks
  model-config
  output-styles
  workflows
  agents
  settings
)

main() {
  local out_dir="${1:-./snapshots}"

  if ! command -v curl >/dev/null 2>&1; then
    echo "error: curl is required but not found on PATH" >&2
    exit 1
  fi

  mkdir -p "$out_dir"

  # Record provenance so a reader knows when and from where these came.
  {
    echo "# Claude Code doc snapshot"
    echo "# Fetched: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "# Index:   $INDEX"
  } > "$out_dir/_manifest.txt"

  local failed=0
  for page in "${PAGES[@]}"; do
    local url="$BASE/$page.md"
    local dest="$out_dir/$page.md"
    printf 'fetching %-22s ... ' "$page"
    if curl --fail --silent --show-error --location \
            --max-time 30 --retry 2 --retry-delay 1 \
            "$url" -o "$dest"; then
      echo "ok ($(wc -l < "$dest" | tr -d ' ') lines)"
      echo "$page <- $url" >> "$out_dir/_manifest.txt"
    else
      echo "FAILED"
      echo "$page <- $url  [FAILED]" >> "$out_dir/_manifest.txt"
      failed=$((failed + 1))
    fi
  done

  echo
  if [ "$failed" -gt 0 ]; then
    echo "warning: $failed page(s) failed. See $out_dir/_manifest.txt" >&2
    exit 2
  fi
  echo "All ${#PAGES[@]} pages fetched into $out_dir"
}

main "$@"
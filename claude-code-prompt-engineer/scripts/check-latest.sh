#!/usr/bin/env bash
#
# check-latest.sh — Discover the CURRENT Claude Code model and feature set live.
#
# Why this exists: any hardcoded "latest model" goes stale the moment a new one
# ships (Opus 4.8 launched the same day this skill was first written, instantly
# falsifying a pinned reference). This script asks the official source instead
# of trusting memory or a cached file.
#
# It prints, for the model + feature picture:
#   1. The model alias table (from model-config.md) — what `opus`/`sonnet` resolve to
#   2. The current docs index (llms.txt) — so new feature pages are discoverable
#   3. The effort levels currently documented
#
# Usage:
#   ./check-latest.sh
#
# Exit codes:
#   0  fetched the model-config page successfully
#   1  curl missing
#   2  could not reach the docs (likely air-gapped or network error)
#
# NOTE: requires network egress to code.claude.com. In air-gapped environments
# this will exit 2; fall back to the dated snapshot from fetch-docs.sh and tell
# the user the model list may be stale.

set -uo pipefail

readonly MODEL_DOC="https://code.claude.com/docs/en/model-config.md"
readonly INDEX="https://code.claude.com/docs/llms.txt"

main() {
  if ! command -v curl >/dev/null 2>&1; then
    echo "error: curl required" >&2
    exit 1
  fi

  local model_page index_page
  model_page="$(curl --fail --silent --show-error --location \
                 --max-time 30 --retry 2 "$MODEL_DOC" 2>/dev/null)" || {
    echo "error: could not reach $MODEL_DOC (air-gapped? network down?)" >&2
    echo "fall back to ./fetch-docs.sh snapshots and warn the user about staleness." >&2
    exit 2
  }
  index_page="$(curl --fail --silent --location --max-time 30 --retry 2 "$INDEX" 2>/dev/null || true)"

  echo "=============================================================="
  echo " CURRENT Claude Code model + effort picture"
  echo " Source: $MODEL_DOC"
  echo " Checked: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "=============================================================="
  echo

  echo "## Model aliases (what opus / sonnet / haiku resolve to right now):"
  echo "$model_page" \
    | grep -iE '`(default|best|opus|sonnet|haiku|opusplan)' \
    | sed 's/|/ /g; s/`//g; s/^[[:space:]]*//' \
    | grep -iE 'opus|sonnet|haiku|default|best|opusplan' \
    | head -20
  echo

  echo "## Effort levels currently documented:"
  echo "$model_page" \
    | grep -ioE '(low|medium|high|max|xhigh|ultracode)' \
    | tr '[:upper:]' '[:lower:]' | sort -u | paste -sd' ' -
  echo

  echo "## Tier defaults (the 'default' alias):"
  echo "$model_page" \
    | grep -iE 'defaults? to (opus|sonnet)' \
    | sed 's/^[[:space:]*-]*//' | head -6
  echo

  if [ -n "$index_page" ]; then
    echo "## Feature pages in the current docs index relevant to artifacts:"
    echo "$index_page" \
      | grep -iE 'skills|memory|hooks|sub-agents|workflows|output-styles|model-config|best-practices' \
      | sed 's/^- //' | head -20
  else
    echo "## (could not fetch docs index; feature list may be incomplete)"
  fi

  echo
  echo "Reconciliation note: the docs page above is the source of truth for the"
  echo "model an alias resolves to. Announcement posts (anthropic.com/news) may"
  echo "describe a newer model before this page updates — when they disagree,"
  echo "tell the user both and prefer the alias (e.g. 'opus') over a pinned"
  echo "version number, since aliases always float to the latest."
}

main "$@"
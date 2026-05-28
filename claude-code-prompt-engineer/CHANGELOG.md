# Changelog

All notable changes to this skill are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/);
this project adheres to [Semantic Versioning](https://semver.org/).

## [2.1.1] - 2026-05-28

### Fixed
- **Cross-file drift.** The README declared version 2.0.0 while SKILL.md was on
  2.1.0, and the README contradicted itself on the test count ("13 checks" in
  one place, "11 assertions" in another). All version stamps and counts are now
  consistent across SKILL.md, README.md, and CHANGELOG.md.

### Added
- **Doc-consistency checks in `test.sh`** (5 new checks, 18 total) that FAIL the
  build on the "files don't know each other's current state" class of bug:
  version agreement across SKILL.md / README.md / CHANGELOG.md; no orphaned
  scripts or references; no dangling references; and no stray references to
  removed components. Proven with a negative test (planted drift → build fails).

## [2.1.0] - 2026-05-28

### Removed
- **Dropped the `cc-doc-fetcher` subagent and the `agents/` folder.** A subagent
  placed inside a skill's `agents/` directory is not discovered by Claude Code —
  subagents load only from `~/.claude/agents/` or `.claude/agents/`. The folder
  looked correct but did not wire up, so the SKILL.md step that delegated to it
  could not work as written.

### Changed
- SKILL.md Step 1 now fetches docs **directly with the WebFetch tool** (already
  in `allowed-tools`) instead of delegating to a subagent. The skill is now
  fully self-contained and portable: one folder, no companion install.
- Surfaced `scripts/fetch-docs.sh` in SKILL.md Step 1 (previously an orphan —
  it existed but was never referenced, so Claude had no cue to use it).
- README updated: removed the subagent install step and the `agents/` tree
  entry; install is now a single `cp -r`.
- All references to `cc-doc-fetcher` in `references/*.md` replaced with the
  direct-WebFetch instruction.

### Fixed
- Three structural defects found in a fresh-eyes audit: the orphaned script, the
  non-loading subagent placement, and the now-inaccurate README install steps.

## [2.0.0] - 2026-05-28

### Changed (breaking: workflow now starts with a mandatory intake)
- **SKILL.md is now self-updating.** It no longer states any model version from
  memory. Step 1 runs a live check (`check-latest.sh`) before recommending any
  model, effort level, or feature. Rationale: Opus 4.8 + dynamic workflows
  shipped the same day v1.0.0 was written, instantly falsifying v1's pinned
  model notes. Aliases (`opus`) are now recommended over version numbers.
- **SKILL.md always opens with a tappable intake** (`ask_user_input_v0`) to
  learn the user's goal, role, and skill level before generating anything, so a
  non-engineer or trainee can use it without knowing the jargon.
- **`model-guide.md` rewritten** to teach the method (prefer aliases, account
  for per-provider model resolution) instead of pinning versions.
- **`prompt-principles.md`** artifact table expanded to include output styles
  and dynamic workflows.

### Added
- `scripts/check-latest.sh` — discovers the CURRENT per-provider model
  resolution and documented effort levels live from `code.claude.com`.
- `references/feature-map.md` — the orchestration ladder (subagents vs agent
  teams vs dynamic workflows) and how to trigger dynamic workflows, `/effort
  ultracode`, and `/deep-research`.
- `test.sh` self-check: the skill's own SKILL.md must pass its own validator.
- `test.sh` optional network smoke test for `check-latest.sh` (skipped, not
  failed, when air-gapped).
- `fetch-docs.sh` now also snapshots the `workflows` and `agents` pages.

### Notes
- Documents Opus 4.8, dynamic workflows (research preview), effort control, and
  the `ultracode` effort tier — all verified against live official sources on
  2026-05-28, not from memory.

## [1.0.0] - 2026-05-28

### Added
- Initial release.
- `SKILL.md` meta-prompt engineer covering four artifact types: CLAUDE.md,
  SKILL.md skills, task prompts, and output styles.
- `agents/cc-doc-fetcher.md` — Haiku subagent that fetches a single official
  Claude Code doc page and returns a focused summary (read-only, WebFetch only).
- `references/prompt-principles.md` — canonical guide for all artifact types.
- `references/model-guide.md` — model aliases, effort levels, recommendations.
- `references/hooks-cheatsheet.md` — hook events and selection guidance.
- `scripts/fetch-docs.sh` — pulls fresh snapshots of 10 core doc pages.
- `scripts/validate-skill.sh` — lints SKILL.md against official structural rules.
- `scripts/validate-claude-md.sh` — lints CLAUDE.md against official guidance.
- `test.sh` — network-free CI harness; 11 assertions across the validators.
- `README.md`, `LICENSE.txt` (MIT), and this changelog.

### Notes
- All content grounded in `https://code.claude.com/docs/llms.txt`.
- All shell scripts pass shellcheck 0.11.0 with zero warnings.
- Documented limitations: bash-dependent validation gate, network-dependent
  doc fetcher, and snapshot drift in references.
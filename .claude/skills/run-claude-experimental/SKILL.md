---
name: run-claude-experimental
description: Verify, lint, and smoke-test the claude-experimental skills repo. Use when asked to run, test, verify, or validate the meta-prompt skill or any skill file in this repo.
---

This repo contains prompt engineering skills (Markdown files with YAML frontmatter). There is no server or GUI — the driver is `smoke.sh`, a bash script that validates `skills/meta-prompt.md` for required sections, constraints, and URL coverage.

All paths below are relative to the repo root (`/home/user/claude-experimental/`).

## Prerequisites

None beyond bash. No packages to install.

## Run (agent path)

```bash
bash .claude/skills/run-claude-experimental/smoke.sh
```

Run from the repo root. Exits 0 on pass, 1 on failure. Output is line-by-line ✓/✗.

| Check category | What it validates |
|---|---|
| File + frontmatter | File exists, `name:` and `description:` fields present |
| Sections | All required `## SECTION` headers present |
| Constraints | No XML tags, Four Ds present, out-of-scope template intact |
| URLs | Key doc URLs present in the FETCH DOCS table |

## Run (human path)

Same command — there is no interactive surface.

## Gotchas

- **Must run from repo root**, not from inside the skill directory. The smoke script uses the path `skills/meta-prompt.md` relative to `$PWD`.
- The XML check (`<[a-zA-Z][^>]*>`) catches angle-bracket tags. URLs and markdown are safe; only actual tag syntax will trigger it.

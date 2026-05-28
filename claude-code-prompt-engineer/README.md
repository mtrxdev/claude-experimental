# claude-code-prompt-engineer

A Claude Code skill that lets **anyone — engineer or first-day trainee** —
generate correct Claude Code artifacts: `CLAUDE.md` files, `SKILL.md` skills,
task prompts, and output styles. Two things make it safe for non-experts and
durable over time:

- **It always asks first.** Every run opens with tappable questions (goal, role,
  skill level) so you don't need to know the jargon to get a good result.
- **It's self-updating.** It never states a model version or feature from
  memory — it fetches the live official docs each run, so it stays correct even
  as new models and features ship.

/ version: 2.1.1 · license: MIT /

---

## What it does

When you ask Claude Code to write a CLAUDE.md, build a skill, draft a task
prompt, or create an output style, this skill:

1. Classifies which artifact type you actually need (CLAUDE.md vs skill vs hook
   vs prompt vs output style).
2. Generates it using rules curated from the official docs.
3. **Validates** the result with a shell linter and only delivers if it passes.
4. Tells you where to install it and what it does not cover.

It is grounded, not memorized: when a feature detail might be stale, it fetches
the live doc page directly with WebFetch.

---

## Layout

```
claude-code-prompt-engineer/
├── SKILL.md                      Main skill: intake → live-refresh → generate → validate
├── LICENSE.txt                   MIT
├── CHANGELOG.md                  Version history
├── README.md                     This file
├── test.sh                       CI harness (18 checks incl. doc-consistency; network-optional)
├── references/
│   ├── prompt-principles.md      Canonical guide for all artifact types
│   ├── model-guide.md            How to recommend models WITHOUT pinning a version
│   ├── feature-map.md            Orchestration ladder + dynamic workflows
│   └── hooks-cheatsheet.md       Hook events and when to use each
└── scripts/
    ├── check-latest.sh           Discover CURRENT per-provider models + effort levels (needs egress)
    ├── fetch-docs.sh             Snapshot core doc pages (needs egress)
    ├── validate-skill.sh         Lint a SKILL.md against official rules
    └── validate-claude-md.sh     Lint a CLAUDE.md against official guidance
```

## How it behaves on every run

1. **Intake** — asks goal, role, and skill level via tappable buttons, then
   confirms in plain language (defining terms for non-experts).
2. **Live refresh** — runs `check-latest.sh` and/or fetches the relevant doc
   page with WebFetch so model and feature facts are current, never from memory.
3. **Generate** — produces the artifact, recommending model *aliases* (`opus`)
   rather than version numbers so the advice doesn't go stale.
4. **Validate** — runs the matching linter; never delivers a failing artifact.
5. **Deliver** — install path, boundaries, and the model/effort rationale in
   language sized to the user's skill level.

---

## Install

**Personal** (all your projects):

```bash
cp -r claude-code-prompt-engineer ~/.claude/skills/
```

**Project-scoped** (one repo, shared via version control):

```bash
cp -r claude-code-prompt-engineer .claude/skills/
```

The skill is fully self-contained — it fetches docs directly with WebFetch, so
there are no companion files to install separately.

Invoke directly with `/claude-code-prompt-engineer`, or just describe the task
("write me a CLAUDE.md for…") and it triggers automatically.

---

## Verify (CI)

The validators are tested by a self-contained harness that does **not** touch
the network, so it is safe for air-gapped pipelines:

```bash
./test.sh            # 18 checks; exit 0 = pass
```

Lint the shell scripts:

```bash
shellcheck scripts/*.sh test.sh
```

Smoke-test the live doc fetcher (**requires network egress** to
`code.claude.com`):

```bash
./scripts/fetch-docs.sh /tmp/snapshots && cat /tmp/snapshots/_manifest.txt
```

A suggested CI gate runs `shellcheck` + `./test.sh` on every change and treats a
nonzero exit as a build failure.

---

## Using the validators standalone

```bash
./scripts/validate-skill.sh path/to/SKILL.md         # exit 0 pass, 2 fail
./scripts/validate-claude-md.sh path/to/CLAUDE.md     # exit 0 pass, 2 fail
```

Exit-code contract for all scripts: `0` success, `1` bad arguments/environment,
`2` validation failure.

---

## Known limitations

- The validation gate requires `bash`. In runtimes without a shell, the skill
  degrades to a manual rule check (weaker than the automated linter).
- `fetch-docs.sh` requires network egress; in air-gapped environments, commit a
  snapshot directory instead. The snapshot manifest records fetch time so
  staleness is visible.
- The `references/` files are a curated snapshot of the docs and will drift over
  time. Use WebFetch on the live doc page for confirmation when precision matters.

## Internal consistency

`test.sh` includes doc-consistency checks that fail the build if the files drift
apart: the version must match across SKILL.md, README.md, and the top CHANGELOG
entry; every script and reference must be cited in SKILL.md (no orphans); every
file SKILL.md cites must exist (no dangling references); and no removed
component may be referenced outside CHANGELOG history. Run `./test.sh` after any
edit — it catches the "one file doesn't know another changed" class of bug.

---

## Source

All rules are derived from the official Claude Code documentation index at
`https://code.claude.com/docs/llms.txt`. No third-party or memorized claims.
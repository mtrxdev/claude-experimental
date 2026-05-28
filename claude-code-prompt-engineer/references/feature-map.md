# Claude Code Feature Map
> PRINCIPLE: the feature set grows constantly. This file orients you to the
> major orchestration choices, but run `scripts/check-latest.sh` (which lists
> the live docs index) or WebFetch the relevant page before claiming a feature exists
> or describing its exact behavior. Dynamic workflows did not exist when this
> skill was first written; assume more have shipped since.

---

## The orchestration ladder — who holds the plan

When a task is bigger than one prompt, there are four tools. The difference is
WHO decides what runs next and WHERE intermediate results live. Match the tool
to the scale, then point the user at the right artifact.

| Tool | What it is | Who orchestrates | Scale |
|---|---|---|---|
| **CLAUDE.md / skill / prompt** | Instructions Claude follows | Claude, in one context | One task |
| **Subagents** | Workers Claude spawns | Claude, turn by turn | A few per turn |
| **Agent teams** | Multiple independent sessions | A lead session | Several sessions |
| **Dynamic workflows** | A JS script the runtime executes | The script | Dozens–hundreds of agents |

Use the lightest tool that fits. Don't recommend a dynamic workflow for a
two-file change, and don't recommend plain subagents for a 500-file migration.

## Dynamic workflows (research preview)

A dynamic workflow is a JavaScript script that orchestrates subagents at scale.
Claude writes the script for the task you describe; a runtime executes it in
the background while the session stays responsive. The script holds the loop,
branching, and intermediate results, so Claude's context holds only the final
answer.

**When to recommend it:** codebase-wide bug sweep, large migration (hundreds of
files), a research question whose sources must be cross-checked, or a hard plan
worth drafting from several independent angles before committing. Its extra
value over "just more agents" is repeatable quality patterns — e.g. independent
agents adversarially reviewing each other's findings before reporting.

**How a user triggers one** (verify current mechanics by WebFetching
`workflows`):
- Include the word **`workflow`** anywhere in a prompt → Claude writes one for
  that single task. (`alt+w` ignores an unintended trigger.)
- `/effort ultracode` → Claude decides when a task warrants a workflow, for
  every substantive task in the session.
- `/deep-research <question>` → the built-in bundled workflow: fans out web
  searches, cross-checks sources, returns a cited report.
- `/workflows` → watch/manage running and completed workflows.
- After a good run, save the script as a reusable command.

**Availability/limits to tell the user:**
- Research preview — expect rough edges; don't point it at production-critical
  migrations without review.
- Requires a recent Claude Code version (the docs state a minimum; check it).
- Available on paid plans (Pro via a `/config` toggle; Max/Team; Enterprise is
  admin-enabled at launch) and via the API and major cloud providers.
- Requires the WebSearch tool for `/deep-research`.

## Other features worth routing to (confirm live before detailing)

- **Routines / scheduled tasks** — run prompts on a schedule on Anthropic
  infrastructure (keep running when your machine is off), or `/loop` for
  in-session polling.
- **Output styles** — change how Claude communicates (role/tone/format) without
  changing what it knows. A fourth artifact type this skill generates.
- **Hooks** — deterministic shell/HTTP/prompt automation on lifecycle events
  (see `references/hooks-cheatsheet.md`).
- **MCP** — connect Claude Code to external services (Jira, Drive, Slack, custom).
- **Auto memory** — Claude accumulates learnings across sessions without you
  writing them.

## The honesty/reliability angle (relevant when recommending models for review)

Recent Opus releases have pushed hard on not letting flawed work pass
unremarked and on flagging uncertainty rather than overclaiming. When a user's
task is code review, delivery, or anything where a silent wrong answer is
costly, this is a reason to recommend the current top Opus alias at higher
effort. Confirm the current model's specific behavior via the system card /
news rather than quoting a number from memory.
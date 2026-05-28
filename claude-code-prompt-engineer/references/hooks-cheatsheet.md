# Claude Code Hooks Cheatsheet
> Curated from https://code.claude.com/docs/en/hooks.md (official).
> For full schemas and JSON I/O formats, fetch the live page with WebFetch
> (`https://code.claude.com/docs/en/hooks.md`).

---

## What hooks are

User-defined shell commands, HTTP endpoints, or LLM prompts that fire
automatically at points in Claude Code's lifecycle. Configured in
`settings.json` under a `hooks` key. Hooks are deterministic automation —
use them when you want guaranteed behavior, not model judgment.

## Cadences

- **Once per session**: `SessionStart`, `SessionEnd`
- **Once per turn**: `UserPromptSubmit`, `Stop`, `StopFailure`
- **Every tool call**: `PreToolUse`, `PostToolUse`

## The events you'll reach for most

| Event | Fires | Common use |
|---|---|---|
| `SessionStart` | Session begins/resumes | Load env, print reminders |
| `UserPromptSubmit` | Before Claude sees a prompt | Inject context, block prompts |
| `PreToolUse` | Before a tool runs — **can block it** | Guard `rm`, `git push`, secrets |
| `PostToolUse` | After a tool succeeds | Format-on-save, lint, notify |
| `PostToolUseFailure` | After a tool fails | Error capture, alerting |
| `Stop` | Claude finishes responding | Run tests, post summary |
| `PreCompact` / `PostCompact` | Around context compaction | Save/restore state |
| `SubagentStart` / `SubagentStop` | Subagent lifecycle | Track delegated work |
| `FileChanged` | A watched file changes on disk | Reactive rebuilds |

## Matcher + condition pattern

A `PreToolUse` hook that blocks `rm` commands narrows twice: `matcher` to the
Bash tool, then `if` to subcommands matching `rm *`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "if": "Bash(rm *)", "command": "block-rm.sh" }
        ]
      }
    ]
  }
}
```

## Hook types

- `command` — shell command; input arrives on stdin (Pre/PostToolUse get
  `file_path` as an absolute path for Write/Edit/Read)
- HTTP — input arrives as the POST request body
- prompt — an LLM evaluation step

## Decision control (selected)

- `PreToolUse` can **block** a tool call.
- `PermissionDenied` (auto-mode classifier denial): return `{retry: true}` to
  tell the model it may retry.
- Hook output over 50K chars is saved to disk with a path + preview rather than
  dumped into context.

## When to recommend a hook vs a skill vs CLAUDE.md

- **Hook** — deterministic, no LLM, must always happen on an event
  (run ESLint after every edit, block force-push).
- **Skill** — a workflow you or Claude invoke when relevant.
- **CLAUDE.md** — a fact Claude should always know (build command, convention).
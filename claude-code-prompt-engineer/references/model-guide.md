# Claude Code Model & Effort Guide
> PRINCIPLE: never state "the latest model is X" from this file. Model
> resolution changes per provider and per release. Run
> `scripts/check-latest.sh` to get the current picture, or WebFetch
> `https://code.claude.com/docs/en/model-config.md`. This file teaches the
> METHOD, not a frozen answer.

---

## The one rule that prevents staleness

**Recommend aliases, not version numbers.** Aliases (`opus`, `sonnet`, `haiku`)
always float to the latest model for the user's provider. A pinned version like
`claude-opus-4-6` is correct only until the next release and only on some
providers. When a user needs "the best model," tell them to use `opus`, not a
number — then it stays correct automatically.

This is not a style preference. A version pinned in a prompt is wrong the day a
new model ships. An alias is never wrong.

## Latest model resolution is PER-PROVIDER

The same alias resolves to different versions depending on where Claude Code
runs. Do not assume one answer. As of the last live check, `opus` resolved
differently on the Anthropic API vs AWS vs Bedrock/Vertex/Foundry. Always run
`check-latest.sh` to get the current per-provider mapping before stating a
specific version. If you must name a version, name the provider too.

## Model aliases (stable; what they MEAN doesn't change)

| Alias | Meaning |
|---|---|
| `default` | Clears overrides; resolves to the tier/provider default |
| `best` | Most capable available (currently equals `opus`) |
| `opus` | Latest Opus for complex reasoning |
| `sonnet` | Latest Sonnet for daily coding |
| `haiku` | Fast, efficient, for simple tasks |
| `opus[1m]` / `sonnet[1m]` | 1M-token context for long sessions |
| `opusplan` | Opus in plan mode, Sonnet in execution |

The aliases are stable. What each one *resolves to* is not — check live.

## Effort levels (verify the current set with check-latest.sh)

Effort controls adaptive reasoning depth. The documented set has GROWN over
time (low/medium/high/max, then xhigh, then ultracode), so do not treat any
list here as complete — run `check-latest.sh` to see what exists now.

General guidance that holds across the set:
- **medium** — recommended default for most coding; higher can overthink.
- **high / max** — hard debugging, complex architecture.
- **ultracode** — combines top-tier reasoning (`xhigh`) with automatic dynamic
  workflow orchestration: Claude plans a workflow for each substantive task
  instead of waiting to be asked. Session-scoped; resets on a new session.
  Available only on models that support `xhigh`. Drop back to `/effort high`
  for routine work.
- **"ultrathink"** in a prompt triggers high effort for that one turn without
  changing the session setting.

Set with `/effort <level>`, the `--effort` flag, the slider in `/model`, or
`CLAUDE_CODE_EFFORT_LEVEL`.

## How to recommend a model/effort in a generated prompt

- **Large feature, plan then build** → `opusplan` (Opus plans, Sonnet executes)
- **Routine implementation / tests** → `sonnet`, medium effort
- **Bulk mechanical edits** → `haiku`
- **Hard bug or subtle architecture** → `opus` + `/effort high`, or "ultrathink"
- **Huge codebase to read** → `opus[1m]` or `sonnet[1m]`
- **Repo-scale migration or audit needing many agents** → see dynamic workflows
  in `references/feature-map.md`; consider `/effort ultracode`

## Enterprise pinning

Aliases float; to freeze a version use the full model name (e.g.
`claude-opus-4-8`) or `ANTHROPIC_DEFAULT_OPUS_MODEL`. Admins restrict the picker
with `availableModels` in managed settings. Run `check-latest.sh` to get the
exact current model strings before writing a pin into enterprise config.
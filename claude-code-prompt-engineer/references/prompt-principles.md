# Claude Code Prompt Principles
> Curated from https://code.claude.com/docs/llms.txt — official knowledge base only.
> Source docs: best-practices.md, memory.md, skills.md, features-overview.md,
> common-workflows.md, workflows.md, output-styles.md.
> NOTE: this file teaches the rules for each artifact type. It does NOT list the
> current latest model — that is fetched live (see model-guide.md + check-latest.sh).

---

## The Artifact Types — When to Use Each

| You want Claude to... | Use |
|---|---|
| Always know something (conventions, build commands, "never do X") | **CLAUDE.md** |
| Do something on demand or load knowledge only when relevant | **Skill (SKILL.md)** |
| Execute a specific task right now | **Task prompt** |
| Communicate in a different role/tone/format | **Output style** |
| Do something automatically on a lifecycle event (deterministic) | **Hook** |
| Tackle repo-scale work needing dozens–hundreds of agents | **Dynamic workflow** |

**Decision rule**: A fact → CLAUDE.md. A procedure or reference → Skill. A
one-shot job → Task prompt. A change to how Claude *talks* → Output style.
Must-always-happen automation → Hook. Too big for one conversation (mass
migration, codebase audit, cross-checked research) → Dynamic workflow. See
`feature-map.md` for the full orchestration ladder (subagents vs teams vs
workflows).

---

## CLAUDE.md — What Makes It Effective

**Load**: Every session, automatically. Costs tokens every time.

**Include only:**
- Bash commands Claude can't guess (build, test, run)
- Code style rules that differ from language defaults
- Testing instructions and preferred test runners
- Repo etiquette (branch naming, PR conventions)
- Architectural decisions specific to this project
- Developer environment quirks (required env vars)
- Common gotchas and non-obvious behaviours

**Exclude:**
- Anything Claude can figure out by reading the code
- Standard language conventions Claude already knows
- Long explanations or tutorials (put those in a skill)
- File-by-file descriptions of the codebase
- Multi-step procedures (put those in a skill)

**Size target**: Under 200 lines. Every line should answer: *"Would removing this cause Claude to make a mistake?"* If not, cut it. Bloated CLAUDE.md files cause Claude to ignore instructions.

**Format**: Use markdown headers and bullets. Specific, concise. Positive and negative examples where useful.

```markdown
# CLAUDE.md example
## Build & test
- Build: `pnpm build`
- Test single file: `pnpm test path/to/file.test.ts` (never the whole suite)
- Typecheck after edits: `pnpm typecheck`

## Code style
- ES modules only — no `require()`
- Destructure imports: `import { foo } from 'bar'`

## Git
- Branch names: `feat/`, `fix/`, `chore/` prefix
- Never force-push main
```

---

## SKILL.md — What Makes It Effective

**Load**: On demand — when invoked with `/skill-name` or when Claude decides it's relevant.

**Frontmatter (YAML between `---`):**
```yaml
---
description: When to load this skill. Be specific — Claude pattern-matches on this.
---
```

The `description` is the trigger. Make it pushy and specific: include exact phrases a user might say. Weak descriptions cause undertriggering.

**Body**: Instructions, workflow steps, reference patterns, examples.

**Content types:**
- *Reference skill*: knowledge Claude applies to ongoing work (API conventions, style guides)
- *Task skill*: step-by-step workflow invoked with `/skill-name`

**Size target**: Under 500 lines for `SKILL.md`. Longer reference material goes in `references/` subdirectory and is loaded on demand.

**Supporting files** (optional, all in skill directory):
```
my-skill/
├── SKILL.md           ← required
├── references/        ← detailed docs loaded as needed
├── scripts/           ← executable scripts
└── assets/            ← templates, examples
```

```yaml
# Skill SKILL.md example — task type
---
description: Runs the full deployment checklist. Use when the user says "deploy", "ship", "release", or asks to push to production.
---

Deploy steps:
1. Run `pnpm test` — fix any failures before proceeding
2. Run `pnpm build` — confirm clean build
3. Commit with message: `chore: pre-deploy build`
4. Push to `main`
5. Monitor deploy logs at https://deploy.example.com
```

---

## Task Prompts — What Makes Them Effective

A task prompt is a one-shot instruction to Claude Code. Quality follows three principles:

### 1. Give Claude a way to verify its work
This is the highest-leverage thing you can do. Without verification criteria, Claude produces code that looks right but may not work.

| Weak | Strong |
|---|---|
| "implement email validation" | "write `validateEmail`. test cases: `user@example.com` → true, `invalid` → false. run tests after." |
| "make the dashboard look better" | "[screenshot] implement this design. take a screenshot, compare to original, list differences, fix them." |
| "fix the login bug" | "users report login fails after session timeout. check `src/auth/` token refresh. write a failing test, then fix it." |

### 2. Scope precisely
- Name the file, not just the feature
- State the constraint (avoid mocks, use existing patterns, no new libraries)
- Point to an example in the codebase: *"look at HotDogWidget.php as the pattern"*

### 3. Use the Explore → Plan → Implement → Commit flow
For anything touching multiple files:
```
[Plan Mode] read /src/auth and understand session handling
[Plan Mode] I want to add Google OAuth. What files need to change? Create a plan.
[Normal Mode] implement the OAuth flow from your plan. write tests, run suite, fix failures.
[Normal Mode] commit with a descriptive message and open a PR
```

Skip planning for: typo fixes, single-line changes, renaming a variable. Use planning for: multi-file changes, unfamiliar code, uncertain approach.

---

## The Three Failure Modes (Inversion)

What guarantees a bad Claude Code prompt:

1. **No verification criteria** — Claude has no feedback loop, mistakes pile up
2. **Vague scope** — Claude guesses the wrong file, pattern, or constraint
3. **Everything in CLAUDE.md** — context bloat makes Claude ignore your instructions

Avoid these and you get 80% of the benefit.

---

## Live Docs Index
Always available at: `https://code.claude.com/docs/llms.txt`

Key pages for prompt engineering:
- `https://code.claude.com/docs/en/best-practices.md`
- `https://code.claude.com/docs/en/memory.md`
- `https://code.claude.com/docs/en/skills.md`
- `https://code.claude.com/docs/en/features-overview.md`
- `https://code.claude.com/docs/en/common-workflows.md`
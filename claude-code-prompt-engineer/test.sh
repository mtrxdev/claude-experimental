# Code Review — `test.sh`

Review of the pasted validator test harness. Focus: correctness bugs that would
fire in CI, plus cleanup. Ranked most-severe first.

---

## Findings

### 1. HIGH — Unguarded globs cause false orphan failures

**Location:** orphan check (`for f in "$SCRIPT_DIR"/scripts/*.sh "$SCRIPT_DIR"/references/*.md`)

`nullglob` is not set. When `scripts/` or `references/` contains no matching
files — or the directory doesn't exist at all — the glob does **not** expand and
the loop body runs once with the literal string `.../references/*.md`.

```bash
base="$(basename "$f")"          # → "*.md"
grep -q "$base" "$SKILL.md"      # greps for literal "*.md" → no match
orphans=$((orphans + 1))          # spurious failure
```

**Failure scenario:** A perfectly valid skill that ships scripts but no
`references/` directory (or vice-versa) fails the suite with
`FAIL: *.md exists but is never referenced in SKILL.md`. The build goes red on
correct input.

**Fix:** Enable nullglob around the loop so non-matching globs expand to nothing:

```bash
shopt -s nullglob
for f in "$SCRIPT_DIR"/scripts/*.sh "$SCRIPT_DIR"/references/*.md; do
  ...
done
shopt -u nullglob
```

---

### 2. MEDIUM — CHANGELOG version check passes vacuously when versions are empty

**Location:** doc-consistency check 2 (`if [ "$skill_ver" = "$changelog_ver" ]`)

Check 1 guards against an empty version with `[ -n "$skill_ver" ]`, so a missing
`version:` in `SKILL.md` correctly FAILs there. Check 2 has no such guard:

```bash
if [ "$skill_ver" = "$changelog_ver" ]; then   # ""  =  ""  → true
```

**Failure scenario:** `SKILL.md` has no `version:` field. `skill_ver` and
`changelog_ver` are both empty. Check 1 prints `FAIL: version drift`, but check 2
prints `PASS: CHANGELOG top entry matches SKILL.md version ()` — a misleading
green line asserting a match between two empty strings.

**Fix:** Mirror check 1's non-empty guard:

```bash
if [ -n "$skill_ver" ] && [ "$skill_ver" = "$changelog_ver" ]; then
```

---

### 3. LOW — Duplicate, empty "summary" section

**Location:** the first `# --- summary ---` block (immediately after the
`validate-claude-md.sh` tests)

```bash
# --- summary ----------------------------------------------------------------
echo
```

This block contains only an `echo` — no summary logic. The real summary lives at
the bottom of the file. The stray header is dead scaffolding that misleads a
reader into thinking results are tallied here.

**Fix:** Delete the early `# --- summary ---` block; keep only the final one.

---

### 4. LOW — `grep -v test.sh` treats the name as a regex

**Location:** stale-reference check 5

```bash
grep -rl 'cc-doc-fetcher' "$SCRIPT_DIR" 2>/dev/null | grep -v CHANGELOG | grep -v test.sh
```

`test.sh` is a regex here, so the `.` matches any character — `testXsh` would
also be excluded. Harmless today (no such files), but fragile.

**Fix:** Anchor as a fixed string: `grep -vF test.sh` (and `grep -vF CHANGELOG`).

---

## Notes (no change needed)

- `set -uo pipefail` without `-e` is **correct** here: the `"$@"; actual=$?`
  pattern in `assert_exit` depends on a non-zero exit not aborting the script.
- `assert_exit` blindly `shift`s the `--` separator without verifying it. Safe as
  long as every call site passes `--` (they all do), so this is style, not a bug.
- The dangling-ref regex `(scripts|references)/[a-z-]+\.(sh|md)` only matches
  lowercase-and-dash filenames. Fine for the current naming convention; would
  silently skip a file with digits/uppercase. Low priority.
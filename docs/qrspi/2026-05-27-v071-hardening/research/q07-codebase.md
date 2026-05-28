---
status: draft
question_ids: [7, 16]
research_type: codebase
---

# Q7, Q16: Evergreen-markdown lint enforcement in `test-evergreen-markdown.bats`

## Summary

**TL;DR:** `tests/unit/test-evergreen-markdown.bats` enforces two families of lint — an evergreen-markdown token scan (repo-wide `*.md`) with 7 forbidden-token patterns and 5 path-shaped carve-out groups plus one inline marker syntax, and a jargon scan (scoped to `skills/**` + `agents/**`) with 4 additional token families. When both carve-outs and inline markers are fully disabled, there are exactly 5 violations across 2 files, all in the evergreen scan; the jargon scan has 0 violations.

**Key findings:**
- The evergreen scan enforces 3 regex families: `release-version`, `milestone-wording`, and `pr-issue-ref`.
- The jargon scan enforces 4 regex families: `bare-paren-pr-ref`, `mechanism-codename`, `b-code-in-parens`, and `half-step-number`.
- Path-shaped carve-outs are 5 groups (6 `case` patterns) implemented in `_is_path_exempt()`. The `CHANGELOG.md` carve-out matches only the exact repo-root path; `docs/qrspi/CHANGELOG.md` is technically not covered by any carve-out (but has no violations).
- The inline exemption syntax is exactly `<!-- evergreen-exempt -->` as the literal string on the line (awk: `/<!-- evergreen-exempt -->/ { next }`).
- All 5 violations outside carve-outs already carry `<!-- evergreen-exempt -->` markers; with carve-outs disabled but inline markers active they would still pass. With both disabled, they fail.

**Surprises:** `docs/qrspi/CHANGELOG.md` is not covered by any path-shaped carve-out (the `CHANGELOG.md` carve-out requires an exact bare filename match), yet it contains no violations.

**Caveats:** The scan was performed against the current git-tracked files (233 `.md` files total). The awk patterns in this report are transcribed directly from the bats file; no pattern-equivalence testing was done.

---

## Full findings

### Q7: Token patterns, carve-outs, and exemption syntax

#### Source file
`tests/unit/test-evergreen-markdown.bats` (433 lines), loaded helper: `tests/helpers/skill-markdown.bash`.

---

#### Scan 1 — Evergreen-markdown scan (repo-wide `*.md`)

Implemented in `_check_file_for_evergreen()` (lines 80–114) and the repo-wide test `[T17] repo-wide evergreen-markdown scan` (lines 205–240).

**Forbidden-token families (3):**

| Family name | awk regex | Canonical examples |
|---|---|---|
| `release-version` | `v[0-9]+\.[0-9]+` | `v0.7`, `v1.2` |
| `milestone-wording` | `in v[0-9]+\.[0-9]+\|after this release\|after the [a-zA-Z]+ release` | `in v0.7`, `after this release` |
| `pr-issue-ref` | `(see\|per\|fixes\|closes) +#[0-9]+` | `per #42`, `see #172` |

Note: `release-version` and `milestone-wording` are checked independently — a line containing `in v0.7` will emit two `EVERGREEN HIT` lines (one per family). Line 116 of `skills/implementer-protocol/SKILL.md` demonstrates this double-trigger.

**Diagnostic format:**
```
EVERGREEN HIT: <rel_path>:<lineno> [<family>]: <full line text>
```

---

#### Scan 2 — Jargon scan (`skills/**/*.md` + `agents/**/*.md` only)

Implemented in `_check_file_for_jargon()` (lines 272–303) and the test `[jargon] skills/** + agents/** scan` (lines 405–432). Scope is intentionally narrower than the repo-wide scan.

**Forbidden-token families (4):**

| Family name | awk regex | Canonical examples |
|---|---|---|
| `bare-paren-pr-ref` | `\(#[0-9]+` | `(#112 PR-1 ...)` |
| `mechanism-codename` | `(^\|[^A-Za-z])Mechanism [A-Z]([^A-Za-z]\|$)` | `Mechanism A` |
| `b-code-in-parens` | `\(B[0-9]+[a-z]?\)` | `(B5)`, `(B5a)` |
| `half-step-number` | `(^\|[^A-Za-z])[sS][tT][eE][pP] (5\.5\|7\.5)([^0-9]\|$)` | `step 5.5`, `STEP 7.5` |

The `half-step-number` pattern matches only the two retired half-step labels `5.5` and `7.5`; other fractional step numbers (e.g., `step 5.2`) are not forbidden.

**Diagnostic format:**
```
JARGON HIT: <rel_path>:<lineno> [<family>]: <full line text>
```

---

#### Path-shaped carve-outs

Implemented in `_is_path_exempt()` (lines 36–72). Returns `0` (exempt) or `1` (not exempt). Uses `case` shell pattern matching; no external tools.

| Carve-out # | `case` pattern | Scope description |
|---|---|---|
| 1 | `docs/qrspi/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-*/*` | Dated pipeline artifact directories (`docs/qrspi/YYYY-MM-DD-*/**`) |
| 2 | `CHANGELOG.md` | Exact bare filename at repo root |
| 3 | `tests/fixtures/*` | Test fixture files |
| 4a | `docs/superpowers/plans/*` | Dated point-in-time implementation plans |
| 4b | `docs/superpowers/specs/*` | Dated point-in-time spec/design docs |
| 5 | `reviews/*` | Reviewer-finding artifacts |

**Exact `case` declaration syntax** (from lines 39–70):
```bash
case "$rel" in
  docs/qrspi/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-*/*)
    return 0 ;;
esac
case "$rel" in
  CHANGELOG.md)
    return 0 ;;
esac
case "$rel" in
  tests/fixtures/*)
    return 0 ;;
esac
case "$rel" in
  docs/superpowers/plans/*)
    return 0 ;;
  docs/superpowers/specs/*)
    return 0 ;;
esac
case "$rel" in
  reviews/*)
    return 0 ;;
esac
```

Each carve-out group is a separate `case` statement (not a single combined one).

**Note on `CHANGELOG.md`:** The sole `CHANGELOG.md` file tracked by git is at `docs/qrspi/CHANGELOG.md`, not at the repo root. Carve-out 2 (`CHANGELOG.md`) matches only the exact string `CHANGELOG.md` (no path prefix), so `docs/qrspi/CHANGELOG.md` is not covered by carve-out 2. It is also not covered by carve-out 1 (which requires a dated subdirectory `YYYY-MM-DD-*`). The file is scanned — but contains no violations.

---

#### Inline carve-out syntax

Declared in the file's header comment (line 20) and implemented identically in both `_check_file_for_evergreen` and `_check_file_for_jargon`:

```awk
/<!-- evergreen-exempt -->/ { next }
```

- **Token:** `<!-- evergreen-exempt -->`
- **Position:** anywhere on the line (awk matches substring; the comment does not need to be at the end, but is conventionally placed there)
- **Scope:** single-line only; suppresses all family checks for that line
- **Application:** both the evergreen scan and the jargon scan use the same pattern

---

#### Currently exempted files via inline markers

Files where at least one line bears `<!-- evergreen-exempt -->`:

| File | Line | Content (abbreviated) |
|---|---|---|
| `agents/qrspi-code-quality-reviewer.md` | 106 | `…flag bare references like \`// fixes #123\` that add no signal…` |
| `skills/implementer-protocol/SKILL.md` | 115 | `\| Release-version token \| \`v\d+\.\d+\` \| \`v0.7\`, \`v1.2\` \|` |
| `skills/implementer-protocol/SKILL.md` | 116 | `\| Milestone wording \| … \| \`in v0.7\`, \`after this release\` \|` |
| `skills/implementer-protocol/SKILL.md` | 117 | `\| PR or issue reference … \| \`per #42\`, \`see #172\` \|` |

These lines document the forbidden-token patterns themselves and must carry examples that would otherwise trigger the lint.

---

### Q16: Violations with carve-outs and inline markers disabled

#### Methodology
- All 233 git-tracked `*.md` files scanned
- No `_is_path_exempt()` filtering applied (all path-shaped carve-outs disabled)
- The `<!-- evergreen-exempt -->` skip rule removed from awk (inline markers disabled)
- Both scans (evergreen and jargon) run

---

#### Evergreen scan: violations outside carve-outs (with inline markers also disabled)

**Total: 5 hits across 2 files**

| File | Line | Violation type | Triggering content |
|---|---|---|---|
| `agents/qrspi-code-quality-reviewer.md` | 106 | `pr-issue-ref` | `…flag bare references like \`// fixes #123\`…` |
| `skills/implementer-protocol/SKILL.md` | 115 | `release-version` | `\| Release-version token \| \`v\d+\.\d+\` \| \`v0.7\`, \`v1.2\` \|` |
| `skills/implementer-protocol/SKILL.md` | 116 | `release-version` | `\| Milestone wording \| … \| \`in v0.7\`, \`after this release\` \|` |
| `skills/implementer-protocol/SKILL.md` | 116 | `milestone-wording` | same line as above (double-trigger: contains `in v0.7` and `after this release`) |
| `skills/implementer-protocol/SKILL.md` | 117 | `pr-issue-ref` | `\| PR or issue reference … \| \`per #42\`, \`see #172\` \|` |

**Per-file count:**

| File | Hit count |
|---|---|
| `agents/qrspi-code-quality-reviewer.md` | 1 |
| `skills/implementer-protocol/SKILL.md` | 4 |

**By violation type:**

| Type | Count |
|---|---|
| `release-version` | 2 |
| `milestone-wording` | 1 |
| `pr-issue-ref` | 2 |

**Notes:**
- All 5 lines already carry `<!-- evergreen-exempt -->`. With inline markers active (even if carve-outs are off), all would be suppressed and 0 violations would remain.
- Line 116 of `skills/implementer-protocol/SKILL.md` triggers two families (`release-version` and `milestone-wording`) because it contains both `v0.7` and `after this release` in the example column of a documentation table.

---

#### Jargon scan: violations with inline markers disabled

**Total: 0 hits across all 74 scanned files** (`skills/**/*.md` + `agents/**/*.md`)

No violations of `bare-paren-pr-ref`, `mechanism-codename`, `b-code-in-parens`, or `half-step-number` exist in any currently-tracked file under `skills/` or `agents/`, even with inline exemption markers disabled.

---

#### Files that would become failing if only carve-outs were re-enabled (inline markers still off)

Same 2 files; same 5 hits. The carve-out paths (`docs/qrspi/YYYY-MM-DD-*/`, `reviews/`, `docs/superpowers/`, `tests/fixtures/`, `CHANGELOG.md`) contain the vast majority of token occurrences in the repo but all of these are legitimately within carve-out scope and do not appear in the "violations" list.

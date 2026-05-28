---
status: draft
question_ids: [5, 13]
research_type: codebase
---

# Q5, Q13: `skill-markdown.bash` exported functions, `extract_section` contracts, and `extract_review_round` definition and call-sites

## Summary

**TL;DR:** `tests/helpers/skill-markdown.bash` exports four public functions — `extract_section`, `extract_and_grep`, `assert_section_contains`, and `require_repo_root` — plus two internal helpers prefixed `_skill_md_`. `extract_section` uses a single-pass awk implementation; a section ends at the next same-level heading line outside of any nesting rule, or at EOF. The `extract_review_round` helper referenced in Q13 is not in the shared helper file; it is a local function defined inline in `tests/unit/test-skill-md-content-patterns.bats` (lines 167–176), is fence-aware (tracks `` ``` `` blocks to avoid false-positive boundary matches), and has only two call sites, both in that same file.

**Key findings:**
- `skill-markdown.bash` exports exactly four public functions: `extract_section`, `extract_and_grep`, `assert_section_contains`, and `require_repo_root`. The private helpers `_skill_md_die` and `_skill_md_prefix_for_level` are also defined there but are not part of the public contract.
- `extract_section` accepts three positional args (`file`, `heading_level` ∈ {H2, H3}, `heading_text`). It prints lines strictly *between* the matching heading and the next same-level heading (boundary lines excluded), or through EOF. Section end is determined by a single-pass awk: a line beginning with the exact level prefix (`## ` or `### `) whose character immediately after the prefix is neither `#` nor empty terminates the section. H3 children inside an H2 section are thus included, not treated as H2 boundaries.
- `extract_section` has three failure-return behaviors (all rc=1, `skill-markdown:` diagnostic to stderr): file unreadable; heading anchor not found (detected via awk sentinel on stderr); extract is empty (silent-pass guard).
- `extract_review_round` is **not** in `tests/helpers/skill-markdown.bash`; it is defined locally in `tests/unit/test-skill-md-content-patterns.bats` (lines 167–176). Its presence in the shared helper was explicitly rejected in the file's own commentary: "extract_review_round is retained as a local helper (fence-aware, not replaceable by the generic extract_section)."
- `extract_review_round` takes one parameter (`file`), includes the `### Review Round` heading line itself in its output, tracks code-fence state (```` ``` ```` toggle), and exits at the first out-of-fence `### ` or `## ` line. It has no error-checking (no unreadable-file or empty-extract guard).
- `extract_review_round` has exactly two call sites, both in `tests/unit/test-skill-md-content-patterns.bats`: line 185 and line 206, both in `[T36-1]` tests operating on `$DESIGN_FILE` (`skills/design/SKILL.md`).
- `run_review_round` (defined in `tests/unit/test-change-type-classification.bats`) is a completely different, unrelated helper that simulates a review-loop dispatch round; it is not a section-extraction helper.

**Surprises:** `extract_review_round` includes the `### Review Round` heading line itself in its output (unlike `extract_section`, which always excludes the target heading from the extract). The function's existence as a local helper rather than a shared one is explicitly documented inline.

**Caveats:** Only `tests/helpers/`, `tests/unit/`, `tests/integration/`, `tests/acceptance/`, and `scripts/` were searched. No other helper directories exist in the repo tree at the time of this investigation.

---

## Full findings

### Q5: Exported functions of `tests/helpers/skill-markdown.bash`

**File:** `tests/helpers/skill-markdown.bash`

#### Public API surface (four functions)

The file header (lines 8–39) declares four public behavioral helpers and explicitly documents the calling convention:

| Function | Calling convention | Parameters |
|---|---|---|
| `extract_section` | Direct call (no `run`) | `<file> <heading_level> <heading_text>` |
| `extract_and_grep` | Direct call (no `run`) | `<file> <heading_level> <heading_text> <regex>` |
| `assert_section_contains` | `run` semantics | `<file> <heading_level> <heading_text> <regex>` |
| `require_repo_root` | Direct call (no `run`) | none |

The calling-convention note is load-bearing: three of the four functions are designed to be called WITHOUT BATS `run`, so a non-zero return directly fails the enclosing `@test` block. `assert_section_contains` is the sole function designed for `run` semantics.

#### Private helpers

- `_skill_md_die <message>` (lines 48–50): emits `skill-markdown: <message>` to stderr.
- `_skill_md_prefix_for_level <H2|H3>` (lines 56–65): echoes `## ` or `### ` for valid levels; returns 1 with a loud diagnostic for any other value.

---

#### `extract_section` — parameter contract

**Signature:** `extract_section <file> <heading_level> <heading_text>`

- `$1` (`file`): path to a readable markdown file.
- `$2` (`heading_level`): one of `H2` or `H3` (case-sensitive, exact match). Anything else triggers `_skill_md_prefix_for_level` rc=1.
- `$3` (`heading_text`): exact heading text string (no prefix; the function prepends `## ` or `### ` internally).

The function constructs `target_line="${prefix}${text}"` (e.g., `## Alpha`) and searches for an exact line match.

#### `extract_section` — section-end determination

Implemented as a single-pass awk (lines 95–120):

```awk
BEGIN { inside = 0; found = 0; plen = length(prefix) }
{
  if (inside == 1) {
    if (substr($0, 1, plen) == prefix) {
      ch = substr($0, plen + 1, 1)
      if (ch != "#" && ch != "") {
        inside = 0
        next
      }
    }
    print $0
    next
  }
  if ($0 == target) {
    inside = 1
    found = 1
    next
  }
}
```

**Boundary rule:** once inside a section, any line whose first `plen` characters exactly equal `prefix` AND whose character at position `plen+1` is neither `#` nor empty terminates the section. This means:
- For an H2 extract (`prefix = "## "`): a line like `## Next Section` terminates the section, but `### SubSection` does NOT (its first three characters are `###`, not `## `).
- For an H3 extract (`prefix = "### "`): a line like `### Next H3` terminates the section, but `## H2 Above` also terminates the section (its first four characters are `## N`, not `### `). Wait — actually: `## H2` starts with `## `, not `### `, so `substr("## H2", 1, 4)` = `## H` ≠ `### `. So H2 lines do NOT match the H3 prefix and are NOT treated as H3 section terminators. H3 sections therefore end only at the next H3 (same-level) or at EOF.

**Section end at EOF:** the `found` flag is set when the anchor is matched; the awk `END` block writes a sentinel marker `__SKILL_MD_FOUND_ANCHOR__` to `/dev/stderr` regardless of whether the section ended early or at EOF.

#### `extract_section` — exit-anchor behaviors

Three failure paths (all rc=1, `_skill_md_die` diagnostic to stderr, nothing to stdout):

1. **File unreadable** (line 79–82): `[ ! -r "$file" ]` → `extract_section: file unreadable: $file`
2. **Heading anchor not found** (lines 134–140): the awk sentinel `__SKILL_MD_FOUND_ANCHOR__` is absent from stderr_tmp → `extract_section: heading anchor not found in $file: ${prefix}${text}`
3. **Empty extract** (lines 142–145): `awk_out` is empty string → `extract_section: extract is empty (silent-pass guard) in $file: ${prefix}${text}`

Additionally: awk failure (`awk_rc` ≠ 0) triggers `extract_section: awk failed on $file (rc=$awk_rc)`.

Success path: prints the extracted block via `printf '%s\n' "$awk_out"`, rc=0.

**Bash 3.2 portability note** (line header, lines 41–42): no associative arrays, no `mapfile`, no `${var,,}`, no coproc, no `wait -n`.

---

#### `extract_and_grep` — parameter contract and exit behaviors

**Signature:** `extract_and_grep <file> <heading_level> <heading_text> <regex>`

- Calls `extract_section "$file" "$level" "$text"` and pipes the output through `grep -E -- "$regex"`.
- rc=0 + matching lines to stdout on success.
- rc=1 + `_skill_md_die` diagnostic if `extract_section` fails (propagates the rc directly via `|| return 1`) or if `grep` matches nothing (empty `$matches`).

#### `assert_section_contains` — BATS-shaped wrapper

**Signature:** `assert_section_contains <file> <heading_level> <heading_text> <regex>`

- Calls `extract_and_grep ... >/dev/null 2>&1`; returns 0 on success.
- On failure: emits `assert_section_contains FAILED: $file:$level $text:$regex` to stderr; returns 1.
- Designed for `run` invocation (BATS `$status`/`$output` pattern).

#### `require_repo_root` — resolution strategy

Two strategies, tried in order:
1. Walk up from `$BATS_TEST_DIRNAME` (up to 8 levels) looking for a `.git` directory.
2. Call `git rev-parse --show-toplevel` (cwd-relative).

Exports `REPO_ROOT` on success, rc=0. Fails loudly with `require_repo_root: could not resolve REPO_ROOT from BATS_TEST_DIRNAME or git rev-parse --show-toplevel`, rc=1.

---

#### Test files that load `tests/helpers/skill-markdown.bash`

The following files contain `load '../helpers/skill-markdown'` (or equivalent):

**Unit tests:**
- `tests/unit/test-helpers-skill-markdown.bats` (self-pin / contract tests for the helper itself)
- `tests/unit/test-skill-md-content-patterns.bats`
- `tests/unit/test-ci-workflow-shape.bats`
- `tests/unit/test-config-model-routing.bats`
- `tests/unit/test-g5-telemetry-emission.bats`
- `tests/unit/test-routing-matrix-application.bats`
- `tests/unit/test-worktree-aware-defaults.bats`
- `tests/unit/test-plan-post-approval-split.bats`
- `tests/unit/test-cache-hit-rate.bats`
- `tests/unit/test-cache-control-capability-gate.bats`
- `tests/unit/test-citation-density-validator.bats`
- `tests/unit/test-cross-skill-contracts.bats`
- `tests/unit/test-quick-tier-wording.bats`
- `tests/unit/test-section-anchor-refresh.bats`
- `tests/unit/test-hygiene-self-check.bats`
- `tests/unit/test-replan-boundary-with-goals.bats`
- `tests/unit/test-wave-context-shape.bats`
- `tests/unit/test-parallelize-vocab.bats`
- `tests/unit/test-red-verification-gate.bats`
- `tests/unit/test-ui-task-fields.bats`
- `tests/unit/test-parallelize-owns-defers.bats`
- `tests/unit/test-test-writer-dual-mode.bats`
- `tests/unit/test-section-anchor-index-shape.bats`
- `tests/unit/test-run-third-party-llm.bats`
- `tests/unit/test-section-anchor-narrow-read.bats`
- `tests/unit/test-tdd-dispatch-order.bats`
- `tests/unit/test-reference-gate-fields.bats`
- `tests/unit/test-no-summary-shim-dispatches.bats`
- `tests/unit/test-bash32-runtime-coverage.bats`
- `tests/unit/test-commit-hygiene-invariants.bats`
- `tests/unit/test-evergreen-markdown.bats`
- `tests/unit/test-replan-archive-and-populate.bats` (grep match, not `load` — confirmed by grep of `require_repo_root`)

**Integration tests:**
- `tests/integration/test-reference-gate-pause.bats`

**Acceptance tests:**
- `tests/acceptance/v07-phase1/test-phase1-acceptance.bats`

(Note: `tests/acceptance/test-review-pause.bats` and `tests/acceptance/test-replan-minor-path-roadmap-driven.bats` match on `extract_section` / `assert_section_contains` usage but do not appear to load the helper via `load '../helpers/skill-markdown'`; they may inline equivalent logic.)

---

### Q13: `extract_review_round` — definition, parameters, return shape, and call sites

#### Definition location

`tests/unit/test-skill-md-content-patterns.bats`, lines 167–176.

The function is **not** in `tests/helpers/skill-markdown.bash` and is **not** defined in any script under `scripts/`. The file's own comment (line 34) explicitly documents why: *"extract_review_round is retained as a local helper (fence-aware, not replaceable by the generic extract_section)."*

#### Full definition (verbatim)

```bash
# extract_review_round <file>
# Extracts the `### Review Round` subsection from the design SKILL.md, robust
# to fenced code-block content (which contains `## Approach`, `## Key
# Decisions`, etc., that would otherwise confuse the simple H2 extractor).
# Tracks code-fence state and only stops on a real (out-of-fence) `### `/`## `
# heading after the Review Round heading is entered.
extract_review_round() {
  local file="$1"
  awk '
    /^```/ { fence = !fence; if (in_b) print; next }
    !fence && $0 == "### Review Round" { in_b = 1; print; next }
    in_b && !fence && /^### / { exit }
    in_b && !fence && /^## / { exit }
    in_b { print }
  ' "$file"
}
```

#### Parameters

- `$1` (`file`): path to the file to scan (used as `"$file"` in the awk call; no readability pre-check performed).

#### Return shape

- **stdout**: all lines from `### Review Round` (inclusive — the heading line itself is printed) through the last line before the next out-of-fence `### ` or `## ` heading, or through EOF.
- Fence-toggle lines (lines matching `` /^```/ ``) that occur while `in_b=1` are also printed (the awk rule `if (in_b) print`).
- **No error checking**: unlike `extract_section`, there is no check for an unreadable file, missing anchor, or empty extract. If `### Review Round` is absent, `awk_out` is empty and the caller must handle the empty-string case itself (the callers at lines 186 and 207 each check `[ -z "$section" ]` and return 1 with a diagnostic).

#### Section-end determination

The section ends at the first line (outside a code fence) that either:
- matches `/^### /` (another H3 heading), OR
- matches `/^## /` (an H2 heading)

Code fences are tracked by `fence = !fence` on any line matching `/^```/`. Lines inside a fence are printed if `in_b=1` and not subject to boundary detection.

**Key difference from `extract_section`:** `extract_section` uses an exact same-level prefix check (H2 ends only at H2; H3 ends only at H3). `extract_review_round` exits on either `### ` or `## `, meaning an H2 heading encountered while scanning an H3 section also terminates extraction.

#### Call sites (exhaustive)

Only two call sites exist, both in `tests/unit/test-skill-md-content-patterns.bats`:

| Line | Context | Argument |
|---|---|---|
| 185 | `[T36-1] design SKILL Review Round Claude-reviewer checks no longer reference deprecated 'acceptance criteria' phrasing` | `"$DESIGN_FILE"` (`skills/design/SKILL.md`) |
| 206 | `[T36-1] design SKILL Review Round still asserts the design addresses all goals` | `"$DESIGN_FILE"` (`skills/design/SKILL.md`) |

There are no call sites in `scripts/`, `tests/helpers/`, `tests/integration/`, `tests/acceptance/`, or any other test file.

#### Note on the unrelated `run_review_round` helper

`tests/unit/test-change-type-classification.bats` defines `run_review_round <change_type> <referenced_files_json>` (lines 82–94) and `run_review_round_with_menu <change_type> <referenced_files_json> <menu_result_override>` (lines 151–164). These are review-loop simulation helpers for testing routing logic (auto-apply / pause / malformed dispatch) — they are not section-extraction helpers and are unrelated to `extract_review_round`.

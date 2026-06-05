---
status: draft
question_ids: [8]
research_type: codebase
---

# Q08: Bats assertion forms and helper structure in `test-using-qrspi-vocab.bats`

## Summary

**TL;DR:** The file uses three assertion forms: bare `[ "$status" -eq/ne 0 ]` after `run grep` (for the five early tests), and inline `[[ "$body" == *…* ]]` / `[[ "$body" != *…* ]]` substring checks (for the eight H4 pin tests). The earlier H4 pin tests (`model_routing:` block and `trusted_path:` block) structurally differ from the later ones (`validators:` block and `Missing model_routing:` block) by omitting the `[ -n "$body" ]` guard. The `_extract_h4` helper is defined locally in the test file, not shared; the only shared helper across `tests/unit/` is `tests/helpers/skill-markdown.bash`.

**Key findings:**
- **Three assertion forms** are used in the file: (1) `run grep` + `[ "$status" -eq/ne 0 ]`, (2) `[[ "$body" == *"..."* ]]` (positive substring), and (3) `[[ "$body" != *"..."* ]]` (negative substring).
- **Five early tests** (lines 77–110) use `run grep -F … "$USING_QRSPI_SKILL"` followed by `[ "$status" -ne 0 ]` (absence) or `[ "$status" -eq 0 ]` (presence) — classic bats `run`+status pattern.
- **Eight H4 pin tests** (lines 112–215) call `_extract_h4` directly (no `run`) and assert with `[[ … ]]` double-bracket substring forms, never through `run`.
- **Structural split among the H4 pin tests:** `model_routing:` block (lines 112–134) and `trusted_path:` block (lines 136–159) do **not** include a `[ -n "$body" ]` non-empty guard. `validators:` block (lines 161–185) and `Missing model_routing:` block (lines 187–215) **do** add `[ -n "$body" ]` as the first assertion inside the test body. Comments in those later tests explicitly note this as a "sanity" safeguard against the empty-string silent-pass risk.
- **`_extract_h4` is a locally-defined function** in `test-using-qrspi-vocab.bats` (lines 45–66). It is not provided by the shared helper. The same function is independently copy-pasted into three other unit-test files: `test-config-model-routing.bats:26`, `test-g5-telemetry-emission.bats:16`, and `test-citation-density-validator.bats:20`.
- **The only shared helper file** in `tests/unit/` is `tests/helpers/skill-markdown.bash`, loaded via `load '../helpers/skill-markdown'` (line 36). It provides: `extract_section`, `extract_and_grep`, `assert_section_contains`, `extract_section_fence_aware`, `require_repo_root`, and the private `_skill_md_die` and `_skill_md_prefix_for_level`. The shared helper handles H2 and H3 anchors only — it explicitly does not support H4.
- 31 of the ~91 unit-test `.bats` files load `../helpers/skill-markdown`; no other shared helper files exist in `tests/helpers/`.
- `setup()` calls `require_repo_root` (from the shared helper) and sets `USING_QRSPI_SKILL` and `USING` to the same file path (`$REPO_ROOT/skills/using-qrspi/SKILL.md`).

**Surprises:** `_extract_h4` is duplicated verbatim across four `.bats` files rather than being promoted into `skill-markdown.bash`, even though the shared helper explicitly notes it supports H2/H3 only. The two earlier H4 pin tests for `model_routing:` and `trusted_path:` lack the empty-body guard that the file's own comments identify as necessary for the later sections — the asymmetry is structural, not cosmetic.

**Caveats:** Investigation was limited to the files in `tests/unit/` and `tests/helpers/`. No other helper directories (e.g., `tests/integration/helpers/`) were exhaustively checked for additional shared functions.

---

## Full findings

### Assertion forms in `test-using-qrspi-vocab.bats`

**File:** `tests/unit/test-using-qrspi-vocab.bats` (215 lines)

The file contains 13 `@test` blocks organized in two groups:

#### Group 1 — `run grep` + status assertions (lines 77–110, five tests)

Tests: existence check, two absence tests, two presence tests.

| Test | Assertion form | What it checks |
|---|---|---|
| `SKILL.md exists` (line 77) | `[ -f "$USING_QRSPI_SKILL" ]` | File presence |
| `retired role→provider/model schema doc is gone` (line 81) | `run grep -F …; [ "$status" -ne 0 ]` | String absence |
| `retired precedence-chain 'role lookup' wording is gone` (line 88) | `run grep -F …; [ "$status" -ne 0 ]` | String absence |
| `schema doc carries the claude-code: host key` (line 95) | `run grep -F …; [ "$status" -eq 0 ]` | String presence |
| `schema doc carries the copilot-cli: host key` (line 100) | `run grep -F …; [ "$status" -eq 0 ]` | String presence |
| `schema doc carries a versioned tier row` (line 105) | `run grep -F …; [ "$status" -eq 0 ]` | String presence |

All six tests in this group grep the full SKILL.md file without section scoping.

#### Group 2 — `_extract_h4` + `[[ ]]` substring assertions (lines 112–215, eight tests)

Each test calls `_extract_h4` (locally defined) directly — **not** wrapped in `run` — assigns the result to `body`, then uses bash `[[ ]]` double-bracket substring tests.

**Positive ("fail-loud contract pinned") tests** check for two substrings:
```bash
[[ "$body" == *"halts and reports"* ]]
[[ "$body" == *"never falls back silently"* ]] || [[ "$body" == *"never fall back silently"* ]]
```
The OR form covers a singular/plural variant of "falls/fall".

**Negative ("anti-pattern wording absent") tests** check for two absent substrings:
```bash
[[ "$body" != *"silently fall back to the agent-bundled default"* ]]
[[ "$body" != *"silently degrade"* ]]
```

#### Structural split: earlier vs. later H4 pin tests

The four H4 anchors tested are:
1. `` `model_routing:` block `` — tested at lines 112–134
2. `` `trusted_path:` block `` — tested at lines 136–159
3. `` `validators:` block `` — tested at lines 161–185
4. `` Missing `model_routing:` block in `config.md` `` — tested at lines 187–215

**Earlier pairs** (`model_routing:` and `trusted_path:`, lines 112–159) assign `body` and immediately apply `[[ ]]` assertions **with no `[ -n "$body" ]` guard**:

```bash
# model_routing: fail-loud (line 112–123)
local body
body="$(_extract_h4 "$USING" '`model_routing:` block')"
[[ "$body" == *"halts and reports"* ]]
[[ "$body" == *"never falls back silently"* ]] || [[ "$body" == *"never fall back silently"* ]]
```

**Later pairs** (`validators:` and `Missing model_routing:`, lines 161–215) prepend `[ -n "$body" ]` before the `[[ ]]` assertions:

```bash
# validators: fail-loud (line 161–175)
local body
body="$(_extract_h4 "$USING" '`validators:` block')"
[ -n "$body" ]   # ← guard added in later pairs
[[ "$body" == *"halts and reports"* ]]
[[ "$body" == *"never falls back silently"* ]] || [[ "$body" == *"never fall back silently"* ]]
```

Comments in the later tests (lines 171–172, 199–202) explicitly justify this as a silent-pass safeguard: if `_extract_h4` returns an empty body (e.g., because the anchor is absent), the `[[ "$body" != *"..."* ]]` negative assertions would silently succeed on an empty string. The earlier tests for `model_routing:` and `trusted_path:` do not include this guard.

---

### Helper functions: local vs. shared

#### Locally defined in `test-using-qrspi-vocab.bats`

**`_extract_h4`** (lines 45–66):
- Takes `file` and `text` (the heading text after `#### `).
- Uses a single-pass `awk` to extract lines between the matching `#### <text>` line and the next `^#{1,4} ` boundary.
- Returns 1 with a diagnostic to stderr if the anchor is not found or if the extracted body is empty.
- Called directly (not via `run`) in all H4 pin tests.

This function is **not** defined in the shared helper (`skill-markdown.bash`). It is independently duplicated (as a copy-paste) in three other unit-test files:
- `tests/unit/test-config-model-routing.bats:26`
- `tests/unit/test-g5-telemetry-emission.bats:16`
- `tests/unit/test-citation-density-validator.bats:20`

The file's comment at lines 39–44 acknowledges that the shared helper supports only H2/H3 and that `_extract_h4` "mirrors the `_extract_h4` helper defined in `test-config-model-routing.bats`."

#### Shared across unit tests: `tests/helpers/skill-markdown.bash`

Loaded via `load '../helpers/skill-markdown'` (line 36). This is the **only** shared helper file for `tests/unit/`. It defines:

| Function | Purpose |
|---|---|
| `_skill_md_die` (line 48) | Private: emit `skill-markdown:` prefixed diagnostic to stderr |
| `_skill_md_prefix_for_level` (line 56) | Private: map `H2`→`## ` or `H3`→`### ` |
| `extract_section` (line 70) | Extract lines between a named H2 or H3 heading and the next same-level heading |
| `extract_and_grep` (line 154) | `extract_section` + `grep -E` on the extract |
| `assert_section_contains` (line 183) | BATS-shaped wrapper around `extract_and_grep` (designed for `run` invocation) |
| `extract_section_fence_aware` (line 221) | Like `extract_section` but treats code-fence-enclosed heading-shaped lines as non-boundaries |
| `require_repo_root` (line 318) | Export `REPO_ROOT` via `.git` walk or `git rev-parse`; called in `setup()` |

**Usage in `test-using-qrspi-vocab.bats`:** Only `require_repo_root` is called from the shared helper (in `setup()`, line 69). None of `extract_section`, `extract_and_grep`, or `assert_section_contains` are used — the file uses its local `_extract_h4` instead for all section-scoped assertions.

31 out of approximately 91 `.bats` files in `tests/unit/` load `../helpers/skill-markdown`. No other shared helper files exist in `tests/helpers/`.

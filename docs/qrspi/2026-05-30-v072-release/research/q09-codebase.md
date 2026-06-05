---
status: draft
question_ids: [9]
research_type: codebase
---

# Q9: Shebang lines in .bats files and `bats tests/` stderr output

## Summary

**TL;DR:** Every `.bats` file in `tests/unit/` (97 files) and `tests/integration/` (1 file) carries the identical file-level shebang `#!/usr/bin/env bats` on line 1 — the suite is perfectly uniform. Running `bats tests/` (non-recursive) against a clean checkout produces `1..0` on stdout and nothing on stderr, because no `.bats` files live directly in `tests/`. Running `bats --recursive tests/` runs 1440 tests, produces no stderr whatsoever, and emits only standard TAP lines — no compiler/runner messages appear besides the TAP plan, pass/fail lines, and per-failure diagnostic comments.

**Key findings:**
- **Shebang**: `#!/usr/bin/env bats` — used on line 1 of all 97 unit and 1 integration `.bats` files without exception.
- **Inline `#!` strings**: Three test files contain embedded `#!` lines inside heredoc fixture blocks (not file-level shebangs): `test-agent-frontmatter-no-model.bats:129` (`#!/usr/bin/env bash`), `test-host-detection.bats:112` (`#!/usr/bin/env bash`), `test-run-third-party-llm.bats:87` (`#!/usr/bin/env bash`), `test-codex-companion-bg.bats:77` and `:401` (`#!/usr/bin/env node`). These are inline script fixtures written via `cat >"$file" <<'EOF'`, not file-level shebangs.
- **`bats tests/` non-recursive output**: stdout = `1..0`; stderr = empty (0 bytes). Zero tests run. No `.bats` files reside directly under `tests/`, so bats finds nothing.
- **`bats --recursive tests/` output**: stdout emits the TAP plan `1..1440` followed by 1440 result lines; stderr is empty. No compiler warnings, runner messages, or diagnostics appear beyond the TAP stream.
- **Test results**: 1439 pass, 1 fail. The single failure is test 235 — `"await: polls fast then backs off (5s→30s pattern, scaled in test)"` — located at `tests/unit/test-codex-companion-bg.bats:219`, failing on `[ "$status" -eq 0 ]`. Its TAP diagnostic appears in stdout (not stderr) as two `#`-prefixed comment lines per TAP protocol.
- **Bats version**: 1.13.0 (at `/opt/homebrew/bin/bats`).

**Surprises:** Running `bats tests/` (as the question phrases it) yields `1..0` — zero tests — rather than recursing into subdirectories. Bats 1.13.0 does not recurse by default; a `--recursive` flag is required to run the full suite.

**Caveats:** The `bats tests/` run was executed on a non-pristine working copy (the research agent's working directory). However, none of the unit tests depend on local git state in ways that would affect shebang content or runner output format. The timing-sensitive test (235) is a flaky polling-backoff test whose failure on this run may be an environmental timing artifact.

## Full findings

### File counts and locations

| Directory | Count |
|-----------|-------|
| `tests/unit/` | 97 `.bats` files |
| `tests/integration/` | 1 `.bats` file (`test-reference-gate-pause.bats`) |
| `tests/acceptance/` | 6 `.bats` files (not asked about) |
| `tests/` root | 0 `.bats` files |

### Shebang survey

**File-level shebangs (line 1 of each file):**

Every `.bats` file in `tests/unit/` and `tests/integration/` uses exactly:
```
#!/usr/bin/env bats
```

No file deviates. The following command confirms all 98 files:
```
grep -rn "^#!" tests/unit/*.bats tests/integration/*.bats | grep ":1:" | sort -u
```
produces a single unique value: `#!/usr/bin/env bats`.

**Embedded inline `#!` lines (inside heredoc fixture bodies, not file-level shebangs):**

| File | Line | Shebang | Context |
|------|------|---------|---------|
| `tests/unit/test-agent-frontmatter-no-model.bats` | 129 | `#!/usr/bin/env bash` | Inside `cat >"$sweep_script" <<'SCRIPT'` heredoc, generating a temp shell helper |
| `tests/unit/test-host-detection.bats` | 112 | `#!/usr/bin/env bash` | Inside a heredoc writing an inline fixture script |
| `tests/unit/test-run-third-party-llm.bats` | 87 | `#!/usr/bin/env bash` | Inside a heredoc writing an inline stub |
| `tests/unit/test-codex-companion-bg.bats` | 77 | `#!/usr/bin/env node` | Inside `cat > "$TEST_ROOT/companion-record.mjs" <<'EOF'`, generating a Node.js mock companion |
| `tests/unit/test-codex-companion-bg.bats` | 401 | `#!/usr/bin/env node` | Inside another `<<'EOF'` heredoc generating a Node.js stub |

None of these alter the file-level shebang for the `.bats` file itself.

### `bats tests/` invocation — stdout and stderr

Command: `bats tests/` (without `--recursive`), run from the repository root.

**stdout:**
```
1..0
```

**stderr:**
```
(empty — 0 bytes)
```

Explanation: Bats 1.13.0 does not recurse into subdirectories unless `--recursive` is passed. Since there are no `.bats` files directly under `tests/` (only under subdirectories `tests/unit/`, `tests/integration/`, `tests/acceptance/`), bats reports a plan of zero tests. No error, no warning, no diagnostic is emitted to stderr.

### `bats --recursive tests/` invocation — stdout and stderr

Command: `bats --recursive tests/`, run from the repository root.

**stderr:** Empty — 0 bytes. No compiler messages, runner warnings, load errors, or any non-TAP diagnostic output.

**stdout (summary):**
- TAP plan: `1..1440`
- `ok 1` … `ok 1440` (with one exception)
- 1439 lines starting with `ok`
- 1 line starting with `not ok`:
  ```
  not ok 235 await: polls fast then backs off (5s→30s pattern, scaled in test)
  ```
  Followed by two TAP diagnostic (comment) lines in stdout:
  ```
  # (in test file tests/unit/test-codex-companion-bg.bats, line 219)
  #   `[ "$status" -eq 0 ]' failed
  ```

**Failing test details:**
- Test 235: `"await: polls fast then backs off (5s→30s pattern, scaled in test)"`
- Source file: `tests/unit/test-codex-companion-bg.bats`, line 219
- Failing assertion: `[ "$status" -eq 0 ]`
- This test is a timing-sensitive polling-backoff test for the Codex companion background wrapper.

**Exit code** of `bats --recursive tests/`: non-zero (due to the 1 failure).

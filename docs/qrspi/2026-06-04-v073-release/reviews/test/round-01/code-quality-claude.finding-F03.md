---
reviewer: code-quality-claude
phase: test
round: 01
severity: minor
change_type: defect
finding_id: F03
title: test-g3 integration test uses non-idiomatic `trap RETURN` for fixture cleanup instead of the file's own `teardown()` pattern
files:
  - tests/acceptance/v07-phase1-test-phase/test-g3-absorption-pipeline.bats
---

## What

`test-g3-absorption-pipeline.bats` does not define `setup()` / `teardown()`. Instead, the lone `integration:` test (line 65-80) installs an in-body trap:

```bash
fix="$(mktemp -d)"
trap 'rm -rf "$fix"' RETURN
cat > "$fix/design.md" <<'EOF'
...
```

## Why it matters

- **Idiom mismatch with the rest of the suite.** Every other file in the v07-phase1-test-phase folder cleans tmpdirs via `setup()`/`teardown()` (test-cd1, test-g4, test-g5, test-g6, test-integration-dispatch-chain, test-regressions). The reader has to context-switch to understand why this one file is different. The mechanical effect is identical for the happy path; the maintenance cost is the inconsistency.

- **`RETURN` trap is fragile under bats's wrapping.** bats internally wraps `@test "foo" { ... }` into a generated function and runs each test in a child shell with its own EXIT-trap machinery. RETURN traps fire when the wrapped function returns — that does include returns triggered by a failed `[ ... ]` assertion (since bats lets the function exit non-zero rather than `exit`-ing the shell). So the trap *does* run for both pass and fail paths today. But this behaviour depends on bats not switching to `exit` semantics inside the wrapper, and on no `set -E` / inherited-trap interaction with future bats versions. Using the documented `teardown()` hook is the contract; `trap RETURN` is an undocumented coincidence.

- **The cleanup target is in `$TMPDIR` (default `mktemp -d`), so leakage doesn't pollute `$REPO_ROOT`** — this is strictly better than F02 — but the bats-managed `$BATS_TEST_TMPDIR` is simpler still and removes the cleanup question entirely.

## Recommended fix

```bash
setup() {
  FIX="$BATS_TEST_TMPDIR/abs"
  mkdir -p "$FIX"
}

@test "integration: design-absorption-markers.sh produces TSV redirect map shape against marker fixture" {
  cat > "$FIX/design.md" <<'EOF'
  ...
EOF
  run "$ABS_SCRIPT" "$FIX/design.md"
  ...
}
```

No `teardown()` needed; bats removes `$BATS_TEST_TMPDIR` itself.

## Verification

- The single integration test continues to pass.
- After the fix, `find /tmp -maxdepth 2 -name 'tmp.*' -mmin -1` shows no orphan after a deliberately failed assertion mid-test.

---
reviewer: code-quality-claude
phase: test
round: 01
severity: critical
change_type: defect
finding_id: F01
title: test-g2 uses bash-4-only `shopt -s globstar` and `**` glob — will hard-fail or silently under-scan on the bash32 CI runner
files:
  - tests/acceptance/v07-phase1-test-phase/test-g2-bats-id-hygiene.bats
note: written to reviews/test/ root because reviews/test/round-01/ did not exist when dispatched; orchestrator should move into round-01/ subdir.
---

## What

`tests/acceptance/v07-phase1-test-phase/test-g2-bats-id-hygiene.bats` lines 20-21 and 32-33 execute:

```bash
shopt -s globstar
matches="$(grep -rE '@test "[^"]*\[T[0-9]+' tests/**/*.bats 2>/dev/null || true)"
```

Both `shopt -s globstar` and the `**` recursive glob it enables were added in **bash 4.0**. The dispatch brief and the repo's CI matrix explicitly include a `bash32` runner.

## Why it matters (two failure modes, both bad)

1. **Hard-fail mode (most likely).** On bash 3.2, `shopt -s globstar` prints `shopt: globstar: invalid shell option name` and exits **non-zero**. bats applies `set -e` semantics inside `@test` bodies — both tests fail at that line with a confusing diagnostic, before the grep ever runs. Result: red CI on the bash32 runner for both `@test` blocks in this file (lines 17-27 and 29-39), masking whatever real corpus violations the sweep was meant to catch.

2. **Silent under-scan mode (if `shopt`'s exit status were swallowed).** Without globstar enabled, bash 3.2 treats `**` as a plain `*` — `tests/**/*.bats` expands to `tests/*/*.bats`, **only one directory level deep**. The test files themselves live at `tests/acceptance/v07-phase1-test-phase/*.bats` (3 levels), as does every file under `tests/unit/`, `tests/lint/`, `tests/acceptance/v07-phase1/`. The "verbatim plan-gate raw-grep across the bats corpus" sweep silently misses the entire corpus past the first level. A reintroduced `[Tnn]` token anywhere below the first directory slides through.

This is the §12 self-consistent-defenses pattern: the lint exists to catch a regression class in the bats corpus, but on the very runner that exercises the most environment variation (bash32), the defense either crashes or under-fires — i.e. it does not function in the environment it is defending.

## Recommended fix

Replace the globstar expansion with `find` (POSIX-clean, works in bash 3.2 and 4+):

```bash
# Drop both `shopt -s globstar` lines.
matches="$(find tests -type f -name '*.bats' -print0 \
  | xargs -0 grep -E '@test "[^"]*\[T[0-9]+' 2>/dev/null || true)"
```

Same change for the `R\d+-F\d+` sweep on line 33. `find -print0 | xargs -0` handles arbitrary paths safely and recurses unconditionally.

## Verification

After the fix, on a bash 3.2 invocation:
- `bats tests/acceptance/v07-phase1-test-phase/test-g2-bats-id-hygiene.bats` should pass clean.
- Plant a `[T99]` token (Bash-assembled at runtime, like the existing boundary test on line 46) inside any `tests/unit/*.bats` fixture and confirm the sweep flags it from arbitrary depth.

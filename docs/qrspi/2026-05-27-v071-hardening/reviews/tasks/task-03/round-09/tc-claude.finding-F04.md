---
finding: F04
round: 9
reviewer: tc-claude
severity: low
change_type: test_quality
status: open
---

# F04 — sec.F01 TOCTOU test discards function return/output; symlink cleanup is not in teardown

## Location

- **Test file:** `tests/unit/test-helpers-skill-markdown.bats` lines 532-542
  (`[sec-F01] extract_section_fence_aware: mktemp-generated signal-tmp does not follow
  pre-planted symlink (TOCTOU fix)`)

## Issue A — extraction correctness is not verified

The test correctly asserts the attack target file is not overwritten after the
fix.  But it invokes the function with `>/dev/null 2>&1 || true`, which
unconditionally swallows both the return code and standard output:

```bash
extract_section_fence_aware "$FIXTURE_DIR/valid.md" "### Some Section" \
  >/dev/null 2>&1 || true
```

The fixture file contains a valid, non-empty section.  If the mktemp fix
accidentally broke normal extraction (e.g. awk signal file is always empty
now), the function would return 1 and emit no output — but the `|| true`
makes the test pass anyway.  The test is blind to that regression: it only
observes what did NOT happen to `attack_target`, not what DID happen in
the function.

### Suggested addition

Capture return code and output separately, and assert success:

```bash
local out rc
out="$(extract_section_fence_aware "$FIXTURE_DIR/valid.md" "### Some Section" 2>/dev/null)"
rc=$?
rm -f "$predictable_path"
# Security property: attack target must be unmodified.
local content
content="$(cat "$attack_target")"
[ "$content" = "ORIGINAL_CONTENT" ]
# Correctness property: the fix must not break normal extraction.
[ "$rc" -eq 0 ]
[[ "$out" == *"### Some Section"* ]]
[[ "$out" == *"content line that is not empty"* ]]
```

## Issue B — symlink not cleaned up in `teardown()`

The symlink at `/tmp/skill-md-fence-signal-$$` is planted at line 520 and
removed at line 536 inside the test body.  `teardown()` only removes
`$FIXTURE_DIR`.  If the test aborts between those two lines (e.g. because an
assertion on line 521 fails, or BATS receives SIGKILL), the symlink leaks into
`/tmp` and stays there until the bats process PID is recycled.  A subsequent
run with the same PID would find the symlink already present before the test
plants it — which could perturb the test result or produce a false positive.

### Suggested addition

Track the predictable path in a variable that `teardown()` always cleans up,
or use a `bats_trap` (BATS ≥ 1.5) to guarantee cleanup:

```bash
teardown() {
  rm -rf "$FIXTURE_DIR"
  # Belt-and-suspenders: remove the symlink if it was left by sec.F01
  rm -f "/tmp/skill-md-fence-signal-$$"
}
```

Alternatively, move the symlink inside `$FIXTURE_DIR` by pointing it at the
predictable path only via a local symlink wrapper (though that changes the
attack-model fidelity slightly).

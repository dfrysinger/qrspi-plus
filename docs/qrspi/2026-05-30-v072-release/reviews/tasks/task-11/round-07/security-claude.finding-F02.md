---
finding_id: F02
reviewer: security-claude
model: claude-sonnet-4.6
round: 7
task: 11
severity: low
change_type: correctness
referenced_files:
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats:2812-2830
---

# security-claude — task-11 round-07 — F02 (LOW / INFO)

## No ordering test for `_fp_tmp` trap-before-compose_prompt

The new bats tests verify the trap *string* is present:
```bash
grep -qE "trap '.*rm -f.*\\\$_fp_tmp.*EXIT|..." "$script"
grep -qE "trap '.*rm -f.*\\\$_fp_tmp.*INT" "$script"
grep -qE "trap '.*rm -f.*\\\$_fp_tmp.*TERM" "$script"
```

These do NOT verify:
1. **Ordering**: that the trap is installed *before* `compose_prompt` executes.
   A regression moving the trap after compose_prompt would pass all 3 greps.
2. **Relay assignment timing**: no analog to the `_manifest_tmp` ordering test
   ("manifest lock-held block resets _manifest_tmp before trap install").
3. **Behavioral coverage**: no test actually signals the process to verify
   the file is removed.

**Contrast with manifest tests (bats lines 2832-2855):** extracts line numbers
and asserts `reset_line < trap_line` — structural ordering, not just string
presence. No analogous test for `_fp_tmp`.

## Recommended addition

```bash
@test "_fp_tmp trap is installed before compose_prompt runs" {
  local script="$REPO_ROOT/scripts/run-codex-review.sh"
  local trap_line compose_line
  trap_line="$(grep -n "trap '.*rm -f.*\\\$_fp_tmp" "$script" | head -1 | cut -d: -f1)"
  compose_line="$(grep -n 'compose_prompt > "\$_fp_tmp"' "$script" | head -1 | cut -d: -f1)"
  [ -n "$trap_line" ] && [ -n "$compose_line" ]
  (( trap_line < compose_line )) \
    || { echo "ERROR: _fp_tmp trap (line ${trap_line}) must precede compose_prompt (line ${compose_line})"; return 1; }
}
```

## Note

Reviewer returned chat-only; orchestrator persisted this finding verbatim.

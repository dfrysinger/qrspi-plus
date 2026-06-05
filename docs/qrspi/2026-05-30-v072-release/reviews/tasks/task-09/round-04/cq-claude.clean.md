# CQ Review — Round 4 — Clean

**Reviewer:** cq-claude  
**Round:** 4  
**Scope:** R3 fixes — jq exit-code guard (Issue A), AC11 grep tightening (Issue B), stale-comment rewrite (Issue C), new AC12 test

## Summary

All three production-code fixes and the new AC12 test are clean. No new code-quality issues found in the R3 diff.

## Checklist Notes

### Issue A — jq exit-code guard (`run-codex-review.sh` line 625–626)

`var="$(cmd)"` propagates `cmd`'s exit status in bash; the `||` fires when jq
exits non-zero or is absent (exit 127). The `$?` reference inside the `{ }`
error message is evaluated before any subsequent command runs, so it correctly
reflects jq's exit code. Self-consistent defense: the guard's own correctness
does not depend on jq being present. ✓

### Issue B — grep tightening to `\-\-model` (`test-phase1-acceptance.bats` line 1702)

`\-` outside `[]` in ERE is treated as literal `-` by both GNU grep and BSD grep
(macOS). Tighter than the previous bare `model` match; no portability concern on
target platforms. ✓

### Issue C — comment rewrite (`run-codex-review.sh` lines 589–618)

Old block mixed stale R2 rationale with orientation prose. New blocks are split:
first block orients (what jq does, defense-in-depth), second block explains the
non-obvious `set +e` constraint and why the guard is necessary. Both categories
are legitimate. ✓

### AC12 new test

- PATH-shim technique correctly overrides system jq with a stub that exits 1.  
- Three assertions cover all required observable behaviors: non-zero exit, `jq`
  named in stderr, no manifest written despite the failure.  
- No `trap` for cleanup on early `return 1` — consistent with the pattern used
  by every other test in the file; DRY/cleanup consolidation is deferred.  
- Test name and comment block clearly describe scenario and motivation. ✓

### Deferred items (not raised)

- ID hygiene and DRY duplication: deferred to v0.7.3 per scope.

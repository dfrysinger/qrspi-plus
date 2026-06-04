# Security Review — Task 16, Round 08 (fix-7 increment)

**Reviewer:** security-claude  
**Commit range:** ccc3d0a → 89dac63  
**Verdict:** ✅ Approved — no new security regressions

---

## Scope of this review

Fix-7 added `[ -f ]` (regular-file predicate) alongside the existing `[ -r ]` at three guard sites in `scripts/_resolve-lib.sh`:

| Site | Line | Guard expression (after fix) |
|------|------|-------------------------------|
| resolve_tier — Layer 2 (agent file) | L85 | `[ -n "$agent_file" ] && [ -f "$agent_file" ] && [ -r "$agent_file" ]` |
| resolve_tier — Layer 3 (CONFIG_MD) | L99 | `[ -n "${CONFIG_MD:-}" ] && [ -f "${CONFIG_MD:-}" ] && [ -r "${CONFIG_MD:-}" ]` |
| resolve_model — CONFIG_MD halt | L142 | `[ -z "${CONFIG_MD:-}" ] \|\| [ ! -f "${CONFIG_MD:-}" ] \|\| [ ! -r "${CONFIG_MD:-}" ]` |

Plus one hermetic bats regression test (no new guard logic in test code).

---

## Analysis

### TOCTOU

`[ -f ]` is evaluated in the same compound `[ ]` expression as the existing `[ -r ]`, so it does not widen the existing TOCTOU window between the guard and the downstream `grep`. The race surface is identical to what was already accepted in prior rounds.

### Path traversal

`[ -f ]` is a pure Boolean predicate — it adds no new expansion of `$agent_file` or `${CONFIG_MD}` into any shell sink beyond what `[ -r ]` already did. Paths at these three sites remain operator/dispatch-owned (D1 deferred-as-acknowledged). No new traversal surface.

### Injection

The `-f` test introduces no new pattern into `grep`, `sed`, or any other downstream sink. It gates the existing code path with a stricter condition; it does not widen it.

### Special-file narrowing (security improvement, not regression)

`[ -f ]` **closes** a minor edge case: a directory, named pipe (FIFO), character/block device, or socket at the watched path could previously satisfy `[ -r ]` and reach the `grep` call. With `[ -f ]`, only regular files and symlinks resolving to regular files pass. Symlink-following semantics of `-f` and `-r` are identical (both follow), so no new symlink escalation path is introduced.

### Privilege escalation / auth

No authentication, privilege, or session logic is touched by this change.

### Bats test

The new regression test is hermetic (fixtures are operator-controlled files under the repo tree, no user-supplied input). No injection sink in the test itself.

---

## Conclusion

Adding `[ -f ]` is a strictly stricter predicate that eliminates a narrow set of non-regular-file paths from reaching `grep`. It introduces no new TOCTOU window, no injection surface, no path traversal vector, and no privilege-escalation path. All three guard sites are correct and safe.

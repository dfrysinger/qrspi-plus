---
finding_id: R1-F02
severity: low
change_type: correctness
referenced_files: ["tests/unit/test-change-type-partition.bats:137-161"]
artifact: code
round: 1
reviewer: silent-failure-claude
---

**Audit test silently skips missing scoped files via `[[ -f "$f" ]] || continue`.**

The audit loop iterates a hard-coded scope array of six paths with `[[ -f "$f" ]] || continue` — if any scoped file is absent, the loop silently moves on and the test passes green. Failure modes this masks:

1. Fixture moved/renamed/untracked (e.g., to `round-02/`) — audit silently no-ops.
2. Emission siblings consolidated back into SKILL.md (T01-style refactor pattern) — scope shrinks silently.
3. Typo in scope entry — silent no-op rather than loud regression.

The audit's contract is "every file in this list is clean of `category:`" — missing files violate that contract just as a `category:` line would, by the same loud-failure principle T04 is enforcing.

**Fix:** Replace `[[ -f "$f" ]] || continue` with `[[ -f "$f" ]] || { echo "scope audit: required file missing: $f"; return 1; }`.

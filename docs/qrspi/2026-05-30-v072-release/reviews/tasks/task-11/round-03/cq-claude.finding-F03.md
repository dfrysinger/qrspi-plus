---
finding_id: R3-F03
reviewer: cq-claude
severity: low
change_type: style
referenced_files:
  - scripts/run-codex-review.sh
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats
---

# F03 — QRSPI task IDs in test names, runtime error strings, and production code comments

**Convergent with cq-codex R3-F02.** cq-claude expands the surface inventory:

**Test names (new @test declarations):**
- `[T11 dispatch-manifest AC1/AC2/AC3/AC4/AC5] ...`

**Runtime error strings (strict surface — visible to operators):**
- `"manifest missing T11 'dispatch_spec' object"` line ~1482
- `"manifest missing T11 top-level 'agent' field"` line ~1489
- `"manifest missing T11 top-level 'mode' field"` line ~1491
- `"manifest missing T11 top-level 'status' field"` line ~1493

**Production code comments:**
- `# (T20 lands that)` in emit_first_party_manifest_entry
- `# T20's dispatch-companion.sh will emit one ...` in third-party dispatch block

**Context note:** T7 and T9 references are already pervasive in pre-existing test names — systemic pattern, not isolated to T11. Whether to remediate only this task's additions or batch with a broader cleanup is the orchestrator's call.

**Fix:** describe behavior, not task ID. Test names → `[dispatch-manifest] third-party entry has nested dispatch_spec plus background job metadata`. Runtime strings → `manifest missing 'dispatch_spec' object`. Comments → "the post-rename dispatch script" instead of "T20".

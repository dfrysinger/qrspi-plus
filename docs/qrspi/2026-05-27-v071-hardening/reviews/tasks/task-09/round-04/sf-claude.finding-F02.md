---
finding_id: R4-F02
severity: low
change_type: correctness
referenced_files: [tests/unit/test-agent-frontmatter-no-model.bats]
artifact: task-09/tests/unit/test-agent-frontmatter-no-model.bats
round: 4
reviewer: sf-claude
persistence_note: orchestrator-persisted (reviewer chat-only fallback)
---

**Title:** Inline sweep script in message-shape test uses pre-fix awk (no CR strip, no in_scalar) — diverges from production `_frontmatter`

**Location:** `tests/unit/test-agent-frontmatter-no-model.bats:128`

The sweep script written into `$BATS_TEST_TMPDIR/sweep-one-file.sh` contains its own `_frontmatter`:
```bash
_frontmatter() {
  awk '/^---$/{n++;if(n==1){next}if(n==2){exit}}n==1{print}' "$1"
}
```

This is the **R2-era unfixed implementation** — it omits both `gsub(/\r$/, "")` (sf.F01 fix) and the `in_scalar` tracking (sf.F02 fix). The comment at line 96 falsely claims it "mirrors the per-file detection + message construction used in the main sweep test." For CRLF or block-scalar fixtures, the inline script produces empty output — the assertion `[[ "$output" == *"$fixture"* ]]` would fail with no diagnostic about CRLF/scalar as root cause.

A genuine regression where production `_frontmatter` fails on CRLF would not be caught by this test because the sweep_script's independent `_frontmatter` would also fail for the same unrelated reason.

**Fix:** Either (a) source the production helper directly in the inline sweep script instead of redefining `_frontmatter`, or (b) update the comment to honestly describe what the inline copy validates.

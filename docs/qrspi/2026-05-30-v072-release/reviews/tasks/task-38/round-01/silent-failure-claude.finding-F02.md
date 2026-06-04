# F02 — "When present, verify…" qualifier suppresses absence findings

**Severity:** medium
**Category:** Silent fallback / inappropriate error transformation
**File:** `agents/qrspi-structure-reviewer.md:38-39`

Each new check uses header form "X present and coherent/complete" but body says "When present, verify…". A `structure.md` missing the unified architecture diagram or `## Test Architecture` section passes silently — body conditional false, no finding emitted, despite headers signaling expectation.

**Recommended fix:** Reword body to explicit two-branch ("Verify present; if absent, emit finding") OR reword header to "X coherent (when present)" if absence is genuinely not a defect.

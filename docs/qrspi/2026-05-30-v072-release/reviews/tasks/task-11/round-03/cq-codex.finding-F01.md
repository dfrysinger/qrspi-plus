---
finding_id: R3-F01
reviewer: cq-codex
severity: high
change_type: correctness
referenced_files:
  - scripts/run-codex-review.sh
---

# F01 — First-party dispatch drops prompt-assembly failures, always exits success

**File:** scripts/run-codex-review.sh lines 793-797

`compose_prompt > "$_fp_prompt_file"` runs without exit-code checking, then `DISPATCH_FILE=` is emitted, manifest is written, and `exit 0` fires unconditionally. This regresses prior fail-loud behavior — a failed prompt build is recorded as a successful dispatch.

**Convergent with sf-codex R3-F01:** sf-codex independently flagged the same issue from the silent-failure angle.

**Fix:** see sf-codex R3-F01 (same scope, same fix sketch).

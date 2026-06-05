---
finding_id: R1-F01
reviewer_tag: code-quality-claude
round: 1
task: 25
severity: high
change_type: correctness
referenced_files:
  - skills/_shared/prompt-design-rules.md
---

## F01 — ID Hygiene: QRSPI-internal goal IDs in prompt-prose runtime strings

Three goal IDs appear in diff-added lines of `prompt-design-rules.md` (now LLM-consumable runtime prompt prose via `!cat`):
- Line 4: `**Last applied:** 2026-06-02 (v0.7.2 G31 refresh — ...)`
- Line 112: `(Sources: G1 Sub-Rule B + CD-2 acceptance criteria.)`
- Line 113: `Presence ≡ locked (G30); no placeholder bodies (CD-2). (Sources: G30 + CD-2.)`

These match QRSPI pattern `\b[GRDFTQ]-?[0-9]+[A-Za-z]?\b`. None qualify for exemption. File is loaded as runtime instruction → strict surface. IDs are opaque inside-baseball (R1-cuttable).

Fix:
- Line 4: remove `G31` from Last applied
- Lines 112-113: drop `(Sources: ...)` parentheticals (inside-baseball, R1-cuttable)

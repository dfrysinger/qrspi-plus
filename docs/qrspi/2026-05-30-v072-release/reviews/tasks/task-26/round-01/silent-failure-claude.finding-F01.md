---
reviewer: silent-failure-claude
round: 1
finding_id: R1-F01
severity: high
change_type: correctness
referenced_files:
  - skills/plan/SKILL.md
  - skills/design/SKILL.md
---

# F01 — `!cat` includes have no error handling; missing target hollows out classification rules

`!cat skills/_shared/prompt-prose-detection.md` and `!cat …/prompt-prose-writer-addition.md` are the sole delivery channel for content-semantic detection / writer rules. If the target file is absent or the resolution path differs, the directive produces no output and emits no error.

**Step 1 case is materially worse than the writer sites.** T26 *replaced* the path-glob fallback in `skills/plan/SKILL.md` Step 1 (Per-Task Classification) with `!cat`-based detection. If the include silently fails, Step 1 reads:

> Apply the detection above to the planned target files. If the target IS prompt prose, classify lightweight.

with "above" empty. No detection criteria, no fallback. Mis-classifications cascade into F02 (silent skip).

**Fix:** Add a PRECONDITION line above each `!cat` block (or a single one above Step 1 specifically) naming both shared files as required inputs — same convention as artifact gating for goals.md/design.md. At minimum guard Step 1 since the old fallback was removed.

**Adjudication: ACT in fix-cycle 2** (cycle 1 already in flight for cq F01/F02).

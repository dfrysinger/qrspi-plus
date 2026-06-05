---
finding_id: R3-F01
reviewer_tag: cq-codex
round: 3
severity: low
change_type: clarity
referenced_files: [scripts/run-codex-review.sh]
---

# cq-codex F01: Stale "Hand-built JSON object" comment after jq rewrite

**Where:** scripts/run-codex-review.sh:589-593

The comment says this block is a "Hand-built JSON object" with controlled values, but the code now builds JSON via `jq` (612-617). That comment is now inaccurate and conflicts with the newer rationale (603-610), increasing reader confusion.

**Why this matters:** Comments should explain intent, not contradict the implementation.

**Suggested fix:** Remove or rewrite 589-593 to match the `jq -nc --arg ...` approach. Keep the T09-scope rationale (594-602) and the defense-in-depth rationale (603-610); drop the obsolete printf framing.

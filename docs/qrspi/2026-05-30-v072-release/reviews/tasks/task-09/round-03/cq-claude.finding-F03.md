---
finding_id: R3-F03
reviewer_tag: cq-claude
round: 3
severity: medium
change_type: correctness
referenced_files: [tests/acceptance/v07-phase1/test-phase1-acceptance.bats]
---

# cq-claude F03: AC11 diagnostic grep `model` asymmetrically looser than AC10's `reviewer-tag`

**Location:** tests/acceptance/v07-phase1/test-phase1-acceptance.bats line 1702

AC10 (line 1639) checks `grep -qiE 'reviewer-tag'` — a hyphenated token unlikely in unrelated error messages.

AC11 (line 1702) checks `grep -qiE 'model'` — a plain English word that appears in many contexts ("model not found", "model config", upstream tool diagnostics). If a different error fires before argument-parse validation — e.g., a missing-file error containing "model" — the diagnostic assertion would silently pass even though the rejection path never executed.

AC11's own comment block notes `--model is allowlist-validated symmetrically with --reviewer-tag`, making the asymmetric grep pattern surprising.

**Why this matters:** Test goes from "validates the rejection path executed" to "validates that any error contains the word model." That's a meaningful weakening of the assertion's discriminating power and falls under correctness, not pure style, because it can let a regression pass silently.

**Suggested fix:** Tighten to `grep -qiE '\-\-model'` (matching the actual error message `error: --model must match ...`).

**NOVEL — not raised by cq-codex.**

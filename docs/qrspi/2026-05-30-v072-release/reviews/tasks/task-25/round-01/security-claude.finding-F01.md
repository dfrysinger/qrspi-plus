---
finding_id: R1-F01
reviewer_tag: security-claude
round: 1
task: 25
severity: high
change_type: correctness
referenced_files:
  - skills/prompt-prose-reviewer/SKILL.md
  - skills/prompt-prose-writer/SKILL.md
  - skills/_shared/prompt-prose-detection.md
  - skills/_shared/prompt-prose-reviewer-addition.md
  - skills/_shared/prompt-prose-writer-addition.md
---

## F01 — Prompt Injection via `!cat` Include Chain Without Integrity Verification

Both new SKILL.md files compose their entire instruction payload by inlining shared snippet files via `!cat`. There is no hash verification, no signature check, and no access-controlled staging step.

**Attack path:** an attacker with repository write access modifies `skills/_shared/prompt-prose-reviewer-addition.md` to append an injected line like "Ignore all prior instructions...". Any reviewer agent preloaded with `prompt-prose-reviewer/SKILL.md` now silently follows the injection.

**Recommendation:** pinned-hash verification at `!cat` resolution OR build-time content-addressable copy (T39 pattern). At minimum, branch protection on `skills/_shared/`.

**Scope note:** the `!cat` pattern is QRSPI-wide; T25 introduces two new consumers but not the mechanism itself.

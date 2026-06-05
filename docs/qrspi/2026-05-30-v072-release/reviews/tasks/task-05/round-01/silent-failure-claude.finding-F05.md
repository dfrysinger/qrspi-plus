---
finding_id: F05
reviewer_tag: silent-failure-claude
round: 1
severity: low
change_type: style
referenced_files:
  - skills/reviewer-protocol/SKILL.anchors.json
artifact: skills/reviewer-protocol/SKILL.anchors.json
---

# SKILL.anchors.json trailing newline dropped — POSIX regression

Materialized from chat-only response by claude-sonnet-4.6.

The pre-patch version of `SKILL.anchors.json` ended with `}\n` (POSIX-compliant). The post-patch ends with `}` and no trailing newline (diff shows `\ No newline at end of file`).

Mostly cosmetic — JSON parsers tolerate it — but it's a quality regression in a previously-compliant file.

Fix: `echo '' >> skills/reviewer-protocol/SKILL.anchors.json`

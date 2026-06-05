---
finding_id: R1-F01
reviewer_tag: security-codex
artifact: plan.md
round: 1
severity: high
change_type: correctness
location: "Task 16 (G22) — _resolve-lib.sh precedence, plan.md ~994, ~1009, ~1021"
---

## Issue

T16 explicitly requires fallback to hardcoded `medium` when tier resolution exhausts override/agent/default sources. The precedence chain ends in "hardcoded medium with loud warning" rather than fail-loud halt.

## Why (security gap)

Invalid/missing routing config does not hard-fail; dispatch proceeds on an unintended model/vendor path. A misconfigured routing surface ships as "success" with wrong-vendor dispatch — exactly the silent-substitution class G7b exists to close.

## Fix

Require missing/invalid tier resolution to be fatal (non-zero exit), not default-substituted. Add tests asserting rejection at each precedence step. Note: design.md's CD-1 source for this fallback should also be reviewed; the carve-out may need to be removed at the design level.

## Disposition note (orchestrator)

Concurs with sf-codex F01 (same surface, escalated to high). sf-claude F01 also flagged the same surface at low. Verifier should consolidate.

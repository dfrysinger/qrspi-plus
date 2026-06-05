---
finding_id: R1-F01
reviewer_tag: scope-codex
artifact: plan.md
round: 1
severity: high
change_type: scope
location: "Plan-level Phase 1 acceptance block and slice sequencing rationale"
---

## Issue

Plan includes a Phase 1 acceptance-criteria block and a Dependency Graph section that articulates slice sequencing rationale. Per skills/plan/owns-defers.md, vertical-slice authoring and phase boundaries are owned by phasing.md; plan.md should defer to those sources, not re-author them.

## Why

Duplicating phasing content in plan.md creates two sources of truth. Future edits to slice ordering or acceptance criteria must update both files in lock-step; one will drift.

## Fix

Replace the Phase 1 acceptance block with a one-line pointer to phasing.md's Phase 1 acceptance criteria section. Replace the slice sequencing rationale with a pointer to phasing.md's vertical-slice section. Plan retains the per-task `Dependencies:` bullets (which ARE plan-owned).

## Disposition note (orchestrator)

Counter-evidence: scope-claude verdict is that this content stays at plan's altitude because Phase 1 acceptance is plan-authored when there is a single phase. Surfaced here for verifier triage.

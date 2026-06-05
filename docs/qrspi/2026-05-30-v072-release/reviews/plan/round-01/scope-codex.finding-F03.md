---
finding_id: R1-F03
reviewer_tag: scope-codex
artifact: plan.md
round: 1
severity: medium
change_type: scope
location: "plan.md aggregate size (2733 lines for 44 tasks)"
---

## Issue

Plan aggregate length (~2733 lines) suggests scope inflation beyond concise plan intent — content has been pulled in from downstream artifacts (design/structure).

## Why

Size is a proxy for boundary drift. Even if each individual task respects altitude, an aggregate that approaches structure.md's size is a smell that downstream content has migrated upward.

## Fix

Audit per-task average (62 lines/task) against the owns-defers rubric; tighten any task whose prose is >80 lines by replacing inlined design/structure content with cross-references.

## Disposition note (orchestrator)

Counter-evidence: scope-claude explicitly judged 62 lines/task as "consistent with the corpus average." Size-as-smell may be a false signal under the new 5-prose-section template. Surfaced here for verifier triage.

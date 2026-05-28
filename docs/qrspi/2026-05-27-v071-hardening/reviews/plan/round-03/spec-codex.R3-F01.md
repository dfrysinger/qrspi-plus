---
finding_id: R3-F01
severity: high
change_type: correctness
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 3
reviewer: spec-codex
---

G6 behavior over-constrained vs goal/design intent (Interpretation + Scope)

Evidence:
- goals.md (lines 145-149): mismatch handling framed as a diagnostic (candidate C), not a hard stop
- design.md (line 55): mismatch should emit a one-line diagnostic at goals-time
- plan.md Tasks 6/7 (lines 193, 210, 213): mismatch must "return non-zero" / "propagates non-zero exit"

Issue: Plan elevates mismatch from diagnostic to failure gate, blocking intentional operator overrides and exceeding stated intent.

Fix: Change mismatch expectation to emit one-line diagnostic and continue with configured policy unless an explicit fail-closed addition lands in goals.

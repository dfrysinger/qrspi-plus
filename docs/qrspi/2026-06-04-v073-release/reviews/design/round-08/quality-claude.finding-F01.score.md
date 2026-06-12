---
verifier_status: passed
score: 75
actual_model: unknown
defect_class: dangling-reference
---

Verified the quoted CD-2 line 33 text matches exactly, including the "narrowed per G4's pipeline-mode rules" clause. Read G4 (lines 242–266): Outcome/Solution/Why/Dependencies/Acceptance all describe `upstream_paths` content selection by pipeline mode for `scripts/upstream-paths.sh` — there is no mention of diff scope, diff base, or narrowing semantics. G4's "pipeline-mode rules" govern which upstream artifacts feed the verifier's lazy-Read window, not what range a diff covers. So CD-2's reference to G4 for diff-narrowing is a real cross-reference defect: an implementer reading CD-2 to wire up `review-prep.sh` for the Plan step will open G4 and find no diff-narrowing specification.

The finding is concrete, well-cited, and actionable. The recommended fixes are both reasonable (drop the misreference, or relocate the rule into G4 if pipeline-mode-aware narrowing was actually intended). Severity "medium" is appropriate — it's a clarity/contradiction defect inside a design document, not a behavioral hazard, but it does force a guess at implementation time.

Not 100 because there is a charitable reading where the author meant "narrowed per G4's pipeline-mode-driven artifact set" (i.e., narrowed to the files G4 governs) — but even under that reading, the prose is ambiguous enough to merit a fix, and the finding's prescription holds.

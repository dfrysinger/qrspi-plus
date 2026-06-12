---
verifier_status: passed
score: 25
defect_class: scope-boundary-drift
---

Cite Check: design.md L281–L385 exists and the cited region contains the G5 solution blocks. Citation token uses `:L…` rather than canonical `#L…`, but the intent is unambiguous and the line range resolves; treating as parseable in spirit.

Substance: The finding claims "long executable shell/procedural blocks (multi-step command sequences and branching behavior)" exceed the "few illustrative lines" cap. Reading the cited region:

- Lines 281–317 are verbatim SKILL-prose blocks (Orchestration Boundary sections to be inlined into integrate/test/using-qrspi SKILLs). Per owns-defers, Design OWNS "prompt-writing specifics (the actual prose a SKILL or agent file will carry, paraphrased or verbatim when load-bearing)." These are not shell or function bodies.
- Lines 322–333 describe the `scripts/orchestration-boundary-check.sh` behavior via prose (numbered steps, what the script reads, where it writes). The only inline shell tokens are short illustrative one-liners (`git status --porcelain`, the `git log … | awk` pipeline) — well within the "2–3 line illustrative" allowance.
- Lines 337–362 are SKILL prose for the batch-gate menu items and autopilot branching defaults — design-altitude solution detail (acceptance criteria / outcome description), not executable bodies.
- Line 319 explicitly defers env-wrapping mechanism detail to Plan, indicating self-aware boundary-keeping.

There is no 20-line shell body, no function body, no full test-case enumeration. The "branching behavior" cited is prose describing autopilot mode policy (commit-based → revert; uncommitted → halt), which is solution definition Design OWNS. The finding's premise ("exceeding the allowed few illustrative lines") is not substantiated by the cited region — it appears to misread verbatim SKILL prose (OWNED) as executable procedure (DEFERRED).

Borderline/weak scope flag; primarily a misclassification of prose-design blocks. Low confidence this is a real boundary violation.

---
verifier_status: passed
score: 35
actual_model: unknown
defect_class: boundary-drift
---

The finding flags Design naming concrete script files (`scripts/upstream-paths.sh`, `scripts/review-prep.sh`) and concrete skill files to edit as boundary drift into Structure/Plan territory.

Checking the OWNS/DEFERS contract in `skills/_shared/design-altitude-boundary.md`:
- OWNS explicitly includes "Cross-Goal Decisions (CDs) that establish vocabulary, **named architectural components by purpose**, and cross-cutting invariants."
- OWNS also includes "prompt-writing specifics (the actual prose a SKILL or agent file will carry, paraphrased or verbatim when load-bearing)" — which authorizes naming the SKILL files whose prose is being authored.
- DEFERS includes "File architecture (which file holds which component, directory layout, module boundary lines — Structure's job)."

The CDs do name script paths (e.g., `scripts/upstream-paths.sh`), which sits at the tension line between "named component by purpose" (OWNS) and "which file holds which component" (DEFERS). Reasonable readers can interpret either way; the existing pattern in v0.7.2 designs has been to name scripts by purpose with their conventional path. The finding offers no specific quoted prose or line citation showing a placement decision that clearly crosses the DEFERS line beyond what OWNS authorizes (e.g., directory layout decisions or module boundary lines).

The finding is also blanket — `referenced_files` cites design.md as a whole with no line range and the prose body provides only parenthetical examples without quoted text. That makes Cite Check a no-op (no specific quoted content to verify) but also means the finding lacks the specificity to drive a high-confidence accept.

Real tension exists, but the OWNS clause for "named architectural components by purpose" plausibly covers the cited pattern, and the finding does not isolate prose that unambiguously belongs to Structure (e.g., directory layout or module boundaries). Moderate-low confidence; not a clear scope violation.

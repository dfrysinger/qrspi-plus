# R03 Apply-Fix Log

## Applied (2 findings — high-confidence quality)

### quality-claude.R3-F02 (score 80) — G5 cross-cutting scope asymmetry
**Fix applied** (option b — extend coverage):
- L321: `<!-- prose-design: skills/{integrate,test}/SKILL.md -->` → `{implement,integrate,test}`
- L383 acceptance: extended to require Step N block in all three SKILLs, with rationale noting Implement's wave-dispatch stage-commit chain is exactly where commit-based drift is most likely.

Result: "every phase boundary" claim in the cross-cutting note is now accurate; batch-gate violation menu item ({implement,integrate,test} scope) is no longer dead code at Implement.

### quality-claude.R3-F03 (score 70) — revert cap missing from prose-design block
**Fix applied** at L357 (autopilot commit-based violations bullet):
Added explicit "Cap auto-revert at 1 attempt per phase" with full halt-and-surface specification (halt marker name, emit string, post-revert violation listing) directly inside the verbatim prose-design block so the orchestrator's loop-termination is in the artifact orchestrators actually consume.

The edge-cases body block at L375 remains as the design rationale; the prose-design block now carries the operational rule verbatim.

## Deferred (2 findings — low-confidence scope, no actionable citations)

### scope-codex.R3-F01 (score 35) — file architecture / placement
**Not actionable as cited.** Finding asserts boundary drift but cites no specific passages. Verifier (sidecar score 35) notes:
- OWNS explicitly includes "named architectural components by purpose" — naming `scripts/upstream-paths.sh`, `scripts/review-prep.sh` etc. by purpose-path falls within this carve-out.
- DEFERS covers "directory layout, module boundary lines" — none of which the design prescribes.
- Finding has `referenced_files: design.md` with no line range, no quoted prose.

No change applied. Documented as acknowledged-but-soft per verifier reasoning.

### scope-codex.R3-F02 (score 30) — test mechanics
**Not actionable as cited.** Finding asserts over-specification of test mechanics but cites no specific passages. Verifier (sidecar score 30) notes:
- OWNS contract explicitly permits "acceptance criteria including concrete examples and rough test-pairing shapes."
- The enumerated marker regexes in G3.a are load-bearing design content (the patterns ARE the cross-skill vocabulary contract).
- Short grep/awk one-liners in Acceptance bullets are typical acceptance-check shape; DEFERS list flags "full unit-test code" and "executable shell beyond a few illustrative lines" — neither is present.

No change applied. Documented as acknowledged-but-soft per verifier reasoning.

## Dropped (5 findings — low score or hallucinated)

- quality-claude.R3-F01 (0) — Mermaid diagram requirement: HALLUCINATED. No such hard requirement in design owns/defers; recurring quality-reviewer fabrication tracked for v0.7.3 enhancement (add negative-check list to qrspi-design-reviewer).
- quality-claude.R3-F04 (45) — Consolidated Test Strategy section: below clarity threshold (80). Same pattern as F01.
- quality-codex.R3-F01 (10) — Mermaid: same.
- quality-codex.R3-F02 (20) — Test Strategy: same.
- quality-codex.R3-F03 (40) — Research citation formality: below correctness threshold (70). Design references research questions inline; formal citation is not an OWNS requirement.

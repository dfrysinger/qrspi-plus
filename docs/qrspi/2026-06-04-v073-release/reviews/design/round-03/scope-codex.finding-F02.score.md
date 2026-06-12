---
verifier_status: passed
score: 30
actual_model: unknown
defect_class: altitude-drift
---

The finding asserts boundary drift but cites no specific passages — no quoted prose, no line ranges, no enumerated examples of which "exact lint/test filenames" or "concrete grep/awk command patterns" cross the line. Cite Check is a no-op (no specific factual cites), but the lack of grounding makes the finding hard to act on.

Reading the artifact, candidates the reviewer might have in mind include: exact regex patterns in G3.a (4 marker patterns), the exact filename `tests/lint/test-bats-test-name-id-hygiene.bats` in G2, and the `grep -rE '@test "[^"]*\[T[0-9]+'` acceptance check. However, the locked OWNS contract (`skills/_shared/design-altitude-boundary.md`) explicitly permits "acceptance criteria including concrete examples and rough test-pairing shapes" and per-solution Acceptance subsections with "concrete examples." The enumerated marker patterns in G3.a are arguably load-bearing design content (they ARE the contract the script implements — cross-skill vocabulary), and grep commands in Acceptance bullets are typical acceptance-check shape, not Plan-level mechanics.

The DEFERS list flags "Full unit-test code" and "executable shell beyond a few illustrative lines" — design.md does NOT contain test bodies or long shell scripts; what it contains are short acceptance grep one-liners and regex pattern enumerations defending design contracts. These fit the carve-outs.

The finding is plausible-but-soft: a senior reviewer might agree there's some over-specification, but the lack of citation and the explicit OWNS carve-out for concrete examples mean this reads more as a stylistic impression than a verifiable boundary violation. Scoring 30 — somewhat real concern, insufficient grounding, mostly within design's OWNS envelope.

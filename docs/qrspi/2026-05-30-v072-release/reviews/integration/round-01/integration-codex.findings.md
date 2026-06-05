# Codex (gpt-5.3-codex) integration review findings — round 01

## R1-F01 (high, correctness)
**Files:** skills/using-qrspi/SKILL.md:L416-L423, L551-L553; skills/_shared/reviewer-dispatch-prose.md:L6-L31; skills/reviewer-protocol/SKILL.md:L23-L36
Cross-task dispatch/config contract internally inconsistent. using-qrspi still documents Codex routing via run-codex-review.sh + run-third-party-llm.sh and mismatch handling keyed on `codex_reviews`, but merged dispatch surface and reviewer matrix moved to dispatch-agent.sh/await-round.sh and `second_reviewer`.

## R1-F02 (high, correctness)
**Files:** skills/structure/SKILL.md:L34-L39; skills/using-qrspi/SKILL.md:L551-L553, L626-L633
Structure's config-validation still validates `codex_reviews`, while using-qrspi now rejects that field and requires `second_reviewer`. Producer/consumer mismatch on config.md.

## R1-F03 (high, correctness)
**Files:** skills/_shared/structure-altitude-boundary.md:L3-L16; tests/unit/test-skill-md-content-patterns.bats:L255-L259
OWNS/DEFERS heading shape drift: shared structure boundary uses `### What Structure OWNS/DEFERS`, but consumers still parse for H3 heading text `Structure OWNS`.

## R1-F04 (medium, correctness)
**Files:** skills/reviewer-protocol/SKILL.md:L3-L15; tests/unit/test-clean-sentinel-and-schema-guard.bats:L3-L11
Reviewer-protocol emission contract moved out of SKILL.md to sibling files, but integration guards still consume SKILL.md.

## R1-F05 (medium, correctness)
**Files:** CONTRIBUTING.md:L105; tests/unit/test-evergreen-markdown.bats:L24-L25, L110-L116
CONTRIBUTING.md includes release token (`v0.7.2+`), violating repo-wide evergreen scan.

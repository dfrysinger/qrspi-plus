# Claude (sonnet-4.6) integration review findings — round 01

10 findings (high=10), all correctness, covering Group B + Group C.

## R1-F01 — T7 dispatch-surface drift across 12 tests
T7/TE1, TE3-TE13 + dispatch-surface-mismatch warning pin specific prose in skills/using-qrspi/SKILL.md describing Codex/host detection. Merged prose drifted from per-task tip pins.

## R1-F02 — T24 autopilot grep regressions (2 tests)
tests/unit/test-detect-interaction-mode.bats: `<autopilot_mode>` literal and "Autopilot mode is currently active" sentinel must be absent from skills/ and agents/. Sibling tasks reintroduced.

## R1-F03 — T17 repo-wide evergreen-markdown scan
Sibling tasks added evergreen prose with `v[0-9]+\.[0-9]+`, `(see|per|fixes|closes) #NNN`, etc. outside carve-outs.

## R1-F04 — G21 corpus: bats body-assertion guard
test-using-qrspi-vocab.bats H4 extraction returning empty bodies for one or more model_routing/trusted_path/validators/Missing-block H4 sub-blocks.

## R1-F05 — reviewer-protocol clean.md sentinel format
Sentinel format spec relocated to skills/reviewer-protocol/first-party-emission.md but test still pins SKILL.md contents.

## R1-F06 — T13 scripts/ Task-tool subagent dispatch absent
A script reintroduced 'Task tool' / 'subagent_type' literal.

## R1-F07 — M51 structure SKILL OWNS subsection drift
Pin asserts specific OWNS subsection (build-sync gate / marketplace.json) under skills/structure/SKILL.md ## Structure OWNS H2.

## R1-F08 — design/structure SKILL.md OWNS/DEFERS H3 family-shape (×2 pins)
Uniform H3 family shape under both `## … OWNS` / `## … DEFERS` sections drifted.

## R1-F09 — Threshold rule: scope/intent kept regardless of score
Pin asserts threshold-rule prose carries "scope and intent kept regardless of verifier score" — clause lost.

## R1-F10 — await-round: polls fast then backs off
scripts/await-round.sh polling cadence changed; pin expects poll-fast-then-back-off.

---
reviewer: spec-codex
round: 2
task: 7
model: gpt-5.3-codex
status: clean
---

# Spec Review (Codex) — T07 R2 — CLEAN

No blocking findings — **spec pass**.

Evidence spot-checks:

- **Original T07 requirements intact**
  - `## Informational Findings` remains in required location with prefix shape, intended use, structural-confidence downstream behavior, log-only/no auto-apply/no pause, and unprefixed backward-compat: `skills/reviewer-protocol/SKILL.md:L145-L157`.
  - Verifier carve-out is still before false-positive list and still includes literal `Informational:`, first-non-blank-line rule, and 75/50/25 anchors: `agents/qrspi-finding-verifier.md:L19-L39`.
  - Existing sidecar/contract assertions remain in tests (not removed): `tests/unit/test-verifier-agent-file.bats:L60-L154`; G14/T07 assertions still present: `...:L156-L315`.

- **R2 fix clusters addressed**
  - **ID hygiene** (G14 labeling cleaned in test names/messages): diff in `tests/unit/test-verifier-agent-file.bats` (renames from "G14 ..." to neutral informational labels).
  - **Confused-deputy guard** added in protocol: `skills/reviewer-protocol/SKILL.md:L157`; covered by test `...bats:L299-L314`.
  - **Pause-grep negation** fixed: `...bats:L287-L289` now requires negated pause phrasing.
  - **DROP/KEEP boundary unification** updated in verifier: `agents/qrspi-finding-verifier.md:L34-L37`.

- **DROP/KEEP wording vs design intent (§G14)**
  - Design intent says normal threshold applies, structurally real keeps, premise-wrong drops: `design.md:L1496-L1498`.
  - New wording ("≥50 keep, <50 drop; 26–49 not separate") is faithful clarification of that same threshold behavior: `agents/qrspi-finding-verifier.md:L34-L37`.

Advisory only: one auxiliary file outside target list changed (`skills/reviewer-protocol/SKILL.anchors.json`), appears to be mechanical line-offset maintenance from added protocol text.

# Round 07 — Dispositions

## Header
- verifier_enabled: true
- scored: 5 findings | kept: 1 | dropped: 4 | failed: 0
- clean sentinels: 10

## Reviewer tally (14 reviewers)

**Clean (10):** spec-claude, spec-codex, quality-claude, quality-codex, scope-claude, security-claude, silent-failure-claude, goal-traceability-claude, goal-traceability-codex, test-coverage-claude.

**Findings (4 dropped, 1 kept):**

| Finding | change_type | Score | Disposition |
|---|---|---|---|
| security-codex.F01 (path-traversal halt) | correctness | 25 | DROP — sec-claude defended absorbed disposition (canonicalization trips before any byte enters `build/`); orchestrator E2 fix from round-06 already enumerated the related halts |
| scope-codex.F01 (L11 "fully independent" vs L110 T39 deps) | correctness | 62 | DROP — clarity-flavor consistency issue; L110 is the authoritative load-bearing statement; T39 deps metadata is correct |
| silent-failure-codex.F01 (T16 hardcoded medium fallback) | correctness | 15 | DROP — CD-1 goals-permitted operator-facing fallback per round-07 sf-claude clean; would require design+goals backward loop |
| test-coverage-codex.F01 (T39 build-twice determinism) | correctness | 28 | DROP — DoD's reproducibility requirement is sufficiently bounded by AC #4 `git diff --exit-code build/` from a clean source tree; tc-claude clean did not flag |
| **test-coverage-codex.F02 (T25 stale-ref grep)** | correctness | **72** | **KEEP** — T25 DoD L1400 names the invariant but Test Expectations didn't pin the assertion |

## Fix applied (1 edit)

**E1 — T25 Test Expectations stale-ref grep assertion:**

`plan.md` L1408 — added one bullet between the file-existence/deletion-check
and the verbatim-diff bullets:

> "Repo-wide grep audit asserts zero remaining live references to
> `docs/prompt-design-guide.md` outside historical CHANGELOG entries
> (matches DoD invariant — fails the build on any stale source-of-truth
> reference)."

The DoD already names the invariant (L1400); the Test Expectations block
just needed to pin the falsifiable signal so the Test phase can generate a
seeded regression.

## Codex naming convention

All 5 Codex chat-only returns were materialized to disk with canonical
filenames (`<reviewer-tag>.clean.md` / `<reviewer-tag>.finding-FNN.md`).
3 of the 5 returned only the literal token `CLEAN` (spec-codex,
quality-codex, gtx-codex); orchestrator materialized sentinels for each.

## v0.7.3 plugin-friction observations

1. **Scope-tagger em-dash line-range parser.** tc-codex.F02 cited
   "L1407–L1413" (en-dash) in its Location block; the tagger fell back to
   `<full>` because it didn't extract the range. The protocol's "find a
   line range" parser should accept en-dash, em-dash, and ASCII hyphen.
   For this round, the conservative `<full>` fallback is harmless
   (round-08 broadens vs main anyway).

2. **Codex chat-only returns (recurrence of round-06 issue).** 3 of 7
   Codex reviewers returned only the literal token `CLEAN` to chat with
   no disk write. The dispatch prompts explicitly carried the canonical
   filename — Codex's failure mode is independent of prompt clarity at
   this point. Orchestrator-side materialization is the workaround;
   structural fix needs work upstream in the Codex shim or reviewer-protocol.

## Convergence trajectory
- R4 (1 fix) → R5 (3 fixes) → R6 (2 fixes) → R7 (1 surgical fix).
- 10/14 reviewers clean in r7. Dropped 4 of 5 codex findings as
  reviewer-disagreement or scope-extension; kept 1 surgical test-coverage gap.
- Round-08 will dispatch broaden-vs-main to verify the one-bullet
  addition doesn't regress and to converge to clean.

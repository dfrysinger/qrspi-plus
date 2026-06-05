# Structure Round 5 — Dispositions

round: 5
artifact: structure
kept_applied: 2
dropped: 3

---

## Applied findings

### quality-codex.R5-F01 (score 78, medium, correctness)

**Change:** Reverted §3 verifier-fanout invocation (line 212) from
`[--tier-override qrspi-finding-verifier=<tier>]` back to `[--tier-override <tier>]`
to match design.md CD-4 §H authority (line 470).

### scope-codex.R5-F01 (medium, scope)

**Change:** Added one clarifying sentence to §7 (after the BNF grammar block) stating
that the CSV `tag=tier` grammar applies to reviewer-fanout (CD-1) and that verifier-fanout
(CD-4 §H) takes a bare `<tier>` because `qrspi-finding-verifier` is a singleton agent
requiring no tag-prefix namespacing.

---

## Dropped findings

### quality-claude.R5-F01 (score 68, medium, correctness)

**Reason:** Score below 70 floor. Verified gap (implement/SKILL.md missing halt-response
responsibility per CD-4 §I.3), but threshold not met; may resurface in R6+ stitching-audit
as a dead-end-output signal.

### stitching-audit.R5-F01 (score 30, medium, correctness)

**Reason:** Score 30, well below threshold. Diagram convention is source-files-only; other
audit artifacts (§11, §13, manifest) are also absent as nodes, so adding `.orchestrator-fixes.json`
would break convention; §17 prose already binds the consumer obligation.

### stitching-audit.R5-F02 (score 55, low, clarity)

**Reason:** Score 55, below 80 floor for clarity-only findings. Real §11-vs-§17 asymmetry
confirmed but no functional impact; not actionable at this round.

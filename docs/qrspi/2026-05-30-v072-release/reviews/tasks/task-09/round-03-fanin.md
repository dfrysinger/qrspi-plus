---
task: 9
round: 3
status: fan-in-complete
budget: 3 of 3 (last fix-cycle)
---

# T09 R3 Fan-In Disposition

## Reviewers

| Reviewer | Verdict | Findings |
|---|---|---|
| spec-claude | CLEAN | — |
| spec-codex | CLEAN | — |
| sec-claude | CLEAN | (HIGH JSON-injection from R2 fully closed) |
| sec-codex | CLEAN | (HIGH JSON-injection from R2 fully closed) |
| sf-claude | 1 finding | F01 MED jq exit code unchecked |
| sf-codex | 1 finding | F01 MED jq exit code unchecked |
| cq-claude | 3 findings | F01 LOW stale comment / F02 LOW DRY duplication / F03 MED AC11 grep |
| cq-codex | 2 findings | F01 LOW stale comment / F02 LOW DRY duplication |

## Cross-reviewer convergence

- **sf-claude F01 ⇄ sf-codex F01**: convergent MEDIUM, jq command-sub failure produces silently malformed audit manifest. Both reviewers independently. Strong signal.
- **cq-claude F01 ⇄ cq-codex F01**: convergent LOW, stale "Hand-built JSON object" comment contradicts jq implementation.
- **cq-claude F02 ⇄ cq-codex F02**: convergent LOW, DRY duplication across AC9/10/11 setup blocks.
- **cq-claude F03**: NOVEL MEDIUM, AC11 grep pattern `model` is asymmetrically looser than AC10's `reviewer-tag` — could silently pass on unrelated errors containing the word "model".

## Disposition (R3 fix-cycle — last in 3-round budget)

### Issue A (MED, convergent sf): Add jq exit-code guard in emit_dispatch_manifest_entry
Add `|| { echo "error: jq failed building dispatch-manifest entry (jq exit $?)" >&2; exit 1; }` after the `entry="$(jq -nc ...)"` command substitution. This is fail-loud at the call site. Optionally add a top-of-script `command -v jq` check at argument-validation (296-338), but the call-site guard is sufficient and minimal. Add an AC12 acceptance test that simulates jq failure (e.g., PATH-strip jq) and asserts non-zero exit + no manifest write.

### Issue B (MED, novel cq-claude F03): Tighten AC11 grep pattern
Change line 1702 from `grep -qiE 'model'` to `grep -qiE '\-\-model'` (matching the actual diagnostic `error: --model must match ...`). Brings AC11 symmetric with AC10's `reviewer-tag` pattern.

### Issue C (LOW, convergent cq F01): Rewrite stale "Hand-built JSON object" comment
Replace lines 589-590 of run-codex-review.sh with a comment describing the jq approach. Trivial; included in this fix-cycle to keep the source consistent.

### Defer to v0.7.3 backlog
- **Issue D (LOW, convergent cq F02): DRY duplication across AC5/9/10/11 setup blocks** — convergent with existing v0.7.3 test-file modularization backlog item. Extracting `_setup_t09_dispatch_stub_env()` now would touch AC5 which is outside the R3 scope and grow the diff; defer to a focused refactor pass.

## Budget tracking

R3 = 3 of 3 (last fix-cycle). If R4 spec gate finds new defects, escalate or accept-with-issues at task batch gate.

---
round: 08
artifact: design
status: fixing
---

# Round 08 dispositions

## Findings inventory

- quality-claude: 3 findings (medium=1, low=2)
- scope-claude: 0 findings (clean — 7th consecutive)
- quality-codex: 1 finding (medium=1)
- scope-codex: 0 findings (clean — 5th consecutive)

Total: 4 findings. No HIGH this round. All accept.

Trend: 10 → 3 → 5 → 4 → 2 → 4 → 3 → 4 net findings. Severity weight dropping (round 7 had 1 HIGH; round 8 has 0). Scope topology stable clean.

## Per-finding dispositions

### R8-F01 quality-claude (medium) — accept. G2 --prompt-file contradicts broker stdin-only contract

G2 currently says the new third-party LLM dispatcher uses `--prompt-file`, in the same paragraph where it says "reuse the Codex companion broker pattern". Research summary Q3 documents that the broker explicitly retired `--prompt-file` and rejects it with exit 1 — the contract is stdin-only.

**Fix:** Align G2 to stdin-only. Replace `--prompt-file` flag with stdin-via-pipe input. The dispatcher reads the prompt from stdin per the broker's contract. Keep `--output-file` for the response path. Update G2's parameter enumeration accordingly.

### R8-F02 quality-claude (low) — accept. G5 test-writer matrix row conditional is stale

G5's initial routing matrix for `qrspi-test-writer` currently reads "Cheap-model eligible only if G6 splits test writing into its own dispatch." Decision 3 + G6's Recommendation have already resolved the conditional to a universal split.

**Fix:** Update the matrix row to "Cheap-model eligible (Implement-phase mode)" with reasoning noting "Standalone test-writer dispatches in Implement-phase mode (signal: `task_definition` present) are bounded enough to tolerate cheap models. Test-phase mode (signal: `task_definition` absent) retains the same eligibility." Drop the "only if" conditional language.

### R8-F03 quality-claude (low) — accept. System diagram edge reads backwards

The Mermaid system diagram has `BatsBackstop --> CI` but the prose (Decision 8) says CI hosts the BATS backstop, so the dependency is `CI provides venue for BatsBackstop` — the edge should be `CI --> BatsBackstop` (CI hosts the backstop) or relabeled with an edge label clarifying the direction.

**Fix:** Reverse the edge. Change `BatsBackstop --> CI` to `CI --> BatsBackstop`. Matches prose semantics.

### R8-F01 quality-codex (medium) — accept. Bash 3.2 example wrong

The G17 bash 3.2 compatibility fix (round 6) listed `[[`-only constructs as bash-4/5-only syntax. `[[ ... ]]` is bash 3.2+. The wrong example would mislead Plan/Implement into rejecting valid bash 3.2 code.

**Fix:** Replace the `[[`-only example with truly bash-4/5-only constructs:
- Associative arrays (`declare -A`)
- `mapfile` / `readarray`
- `globstar` (`shopt -s globstar`)
- `${var,,}` and `${var^^}` case conversion
- `coproc`

Update the bash-3.2-compatibility test bullet wording to reflect the correct examples.

## Fix dispatch plan

Single fix subagent. 4 small accepts.

## Convergence assessment after round 8

After round 8:
- 8 review rounds × 4 reviewers = 32 reviewer dispatches.
- 33 findings closed (rounds 1-7) + 4 round-8 candidates = 37 total findings touched.
- Scope topology clean for 7 consecutive rounds (scope-claude) / 5 consecutive (scope-codex).
- Severity has dropped: round 1 had 1 HIGH + 2 high (scope) + several mediums; round 8 has 0 HIGH and a mix of mediums + lows.

Recommendation if round 9 produces only LOW findings or 0 findings: declare convergence and present design.md to user for human gate.
If round 9 produces another HIGH or scope finding: continue loop.

## Status

draft → fixing → (post-fix) → re-review round 09.

---
round: 17
artifact: design
status: fixing
---

# Round 17 dispositions

## Findings inventory

- quality-claude: 1 finding (high=1)
- scope-claude: 0 (clean — 15th consecutive)
- quality-codex: 3 findings (high=2, medium=1)
- scope-codex: 1 finding (medium=1)

Total: 5 findings → 4 distinct (quality-claude F01 + quality-codex F02 both flag the same G6 cross-cutting summary drift). All accept.

Trend: 10 → 3 → 5 → 4 → 2 → 4 → 3 → 4 → 6 → 1 → 2 → 3 → 6 → 7 → 5 → 4 → 5. HIGH count by round: 0,0,0,0,0,0,0,0,0,0,0,0,2,2,0,3,3. The R16/R17 HIGHs are revealing real design correctness gaps each round — they are not iteration churn. R17's HIGHs partly say "R16's fix was incomplete" (Option A bash -n parse-only is not a runtime check; cross-cutting summary not updated alongside G6). This round's fixes are tighter and the dispatch subagent will be told to update ALL impacted locations.

## Cross-reviewer match

- quality-claude R17-F01 + quality-codex R17-F02 both flag the cross-cutting test strategy summary contradicting G6's two-condition gate (and Decision 3's older wording). Fix once.

## R17-F01 quality-claude + R17-F02 quality-codex (HIGH, double-flag) — accept. Cross-cutting summary + Decision 3 not updated alongside G6 gate fix

R16 fix updated G6's RED-gate criterion to two-part (vacuous-RED OR infrastructure failure) but failed to propagate to (a) the cross-cutting test-strategy summary line and (b) Decision 3's restatement. Plan/Implement reading either summary would build a different gate.

**Fix:** Update BOTH locations to match G6 detail.
- Cross-cutting test strategy summary line: rewrite to "Orchestrator pauses at the pre-implementer RED-verification gate when (i) no assertion fails on the targeted behavior (vacuous-RED), or (ii) any test fails for an infrastructure reason (syntax error, import error, fixture setup). Pre-passing assertions covering behavior the task does NOT change do not trigger the pause."
- Decision 3's RED-gate restatement: update to the same two-condition wording. If Decision 3 carries a one-line summary, use: "Pause on vacuous-RED (no targeted-behavior failure) OR infrastructure failure; mixed-result suites where some assertions pre-pass on unchanged behavior are permitted."

## R17-F03 quality-codex (HIGH, correctness) — accept. G17 Option A `bash -n` parse-only doesn't catch runtime-only constructs

`bash --posix -n` is a parser check only. `declare -A` PARSES in bash 3.2 — the failure is at runtime, not parse time. So Option A as currently framed cannot catch `declare -A` or other runtime-only bash-4 builtins. R16 fix overstated Option A's coverage.

**Fix:** Replace Option A with a real bash-3.2 EXECUTION check. Two design-level alternatives; recommend the docker option:

**Recommended: Option A' — bash 3.2 docker image execution check.** Run the BATS suites under `docker run --rm bash:3.2 bats tests/` (or equivalent — the `bash` Docker image with tag `3.2` provides a real bash 3.2 runtime). This catches both parse-time AND runtime incompatibilities. CI requires Docker on `ubuntu-latest` (already available). The macos-latest separate job is no longer needed; reorganize G17 CI to two jobs: `lint` (ubuntu-latest, shellcheck + Option B grep ban-list as supplemental fast-fail) and `bash32` (ubuntu-latest, `bash:3.2` docker image runs all BATS suites).

**Alternative if Docker is undesired: Option A'' — macos-latest job with full BATS execution under system bash 3.2.57 (not just `bash -n`).** Runs `bash /usr/bin/bash -c 'bats tests/'` to execute under bash 3.2. Same coverage as Option A' but on macos-latest runner instead of docker. Disadvantage: macos runners are 10x more expensive in GitHub Actions minutes.

Update G17 design-level test bullets:
- Replace the existing `${!array[@]}` Option-A test bullet with: "A file using `declare -A` (a runtime-only bash-4 builtin that parses fine in 3.2) is REJECTED by the bash-3.2 execution gate (Option A' docker job), demonstrating runtime coverage beyond parse-time."
- Keep the Option B fast-fail test bullet.
- Add: "Option B alone is not a 3.2 gate (does not catch runtime-only constructs not on the ban-list); Option A' is load-bearing."

## R17-F01 quality-codex (medium, correctness) — accept. G1 `condition:` vs `when:` field name ambiguity

G1 routing schema example uses one key (`condition:` or `when:`), prose alternates between both names. Structure/Plan could implement different shapes.

**Fix:** Choose canonical key `condition:` (matches the existing schema-example block). Find every prose mention of `when:` in G1 and replace with `condition:`. Ensure schema-example, prose, and test bullets all use the same name.

## R17-F01 scope-codex (medium, scope) — accept. G12 commit sequence still has command-level detail

R15-F03 fix added an explicit 3-step list inside the G12 invariant: `(1) git add -A`, `(2) Write the scratch commit-message file`, `(3) git commit -F .qrspi-commit-msg.txt` plus cleanup. That's line-by-line procedural detail Design DEFERS to Plan/Implement, even though the surrounding prose explicitly delegates to `skills/implementer-protocol/SKILL.md`. Round-13 fixed this once before; round-15 reintroduced it via the "step-3 split" clarification.

**Fix:** Rewrite the G12 commit-hygiene invariants in pure prose form. Three architectural invariants, no command sequences:
1. **Staging-before-scratch invariant:** the staging operation completes before the commit-message scratch file is written to the worktree. Implication: the scratch file does not exist when staging runs and therefore cannot be accidentally included.
2. **Cleanup-after-commit invariant:** the scratch file is removed after the commit completes and before any subsequent staging cycle. Implication: subsequent commits do not see stale scratch files.
3. **Worktree-local-exclude invariant:** the scratch file path is excluded via worktree-local `.git/info/exclude` so `git status` reports remain deterministic and do not show the scratch file as untracked between write and removal.

Drop any reference to `git add -A`, `git commit -F`, or the numbered step ordering. The implementation belongs in `skills/implementer-protocol/SKILL.md` (Plan/Implement own).

Carefully review R15-F03's test bullets too — if any bullet asserts the literal command sequence, rewrite the assertion at the invariant level (e.g., "scratch file does not appear in any commit").

## Fix dispatch plan

Single fix subagent. 4 distinct accepts. All in design.md.

## Status

draft → fixing → re-review round 18.

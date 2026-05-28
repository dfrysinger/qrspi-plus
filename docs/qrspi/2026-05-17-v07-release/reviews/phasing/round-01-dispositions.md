---
round: 1
artifact: phasing
status: fixing
---

# Phasing Round 1 dispositions

## Findings inventory

- quality-claude: 1 finding (medium=1)
- scope-claude: 4 findings (medium=3, low=1)
- quality-codex: 2 findings (high=2)
- scope-codex: 2 findings (medium=2)

Total: 9 findings → 4 distinct accepts + 3 rejected as false claims + 1 meta-issue noted for next round.

## ACCEPT (4 distinct, fix in this round)

### R1-F01 quality-codex (HIGH, correctness) — accept. Slice 6 grab-bag violates Iron Law 1

Slice 6's own description admits the goals are "independent fixes verifiable on their own" — that's a batch of N delivery units, not ONE end-to-end slice. Iron Law 1 requires each slice to be one cross-layer feature.

**Fix:** Split Slice 6 into 5 separate vertical slices, one per goal:
- Slice 6 — Plan post-approval split (G3): main-chat dispatches sub-subagent for N≥3 task plans; ships separate task files.
- Slice 7 — Caching spike + verify (G4): spike report exists; cache_read_input_tokens behavior measured.
- Slice 8 — Commit-message scratch staging (G12): scratch file never appears in any commit (BATS pin).
- Slice 9 — u14-lint worktree (G13): lint passes in worktree context, no false positive.
- Slice 10 — Replan ↔ Goals coordination (G15): Replan promotes only Formal goals; Idea-skip test passes.

Update roadmap.md to reflect 10 slices in Phase 1 (was 6). Update phasing.md's slice list, PoC justification, and replan-gate criteria sections.

### R1-F01 quality-claude (medium, correctness) — accept. G17 bash-3.2 fixture wrong

Replan-gate criterion uses `${!array[@]}` as "bash-4-only construct not on Option B's ban-list." `${!array[@]}` is valid in bash 3.2+. Same defect as future-design FD-02; carried into phasing.md replan-gate criteria.

**Fix:** Rewrite the Slice 3 / G17 replan-gate bullet to use a real bash-4-only construct OR pivot to the contrapositive assertion: "Option B's ban-list is the load-bearing list of forbidden constructs; the bash32 docker job is a backstop that re-validates the ban-list is current by execution test against new bash-4 constructs as authors add them." The future-design FD-02 entry already captures the full resolution context.

### R1-F03 scope-claude + R1-F02 scope-codex (medium, scope — double-flag) — accept. Replan-gate criteria boundary drift

Both reviewers flagged the same: replan-gate criteria contain CLI command invocations (`scripts/run-third-party-llm.sh --provider deepseek ...`), exact fixture names, task-spec field names, test file paths, expected test classifications, generated task-file counts. Plan/Implement own those; Phasing owns phase-level outcomes.

**Fix:** Rewrite all replan-gate criteria at the phase-level outcome layer. Examples:
- BAD: "`scripts/run-third-party-llm.sh --provider deepseek` returns exit 0 with response in --output-file for a smoke prompt."
- GOOD: "A reviewer dispatch can complete on a non-Anthropic OpenAI-compatible provider via the universal dispatcher; cost reduction is measurable in the run's cost telemetry."

Rewrite every gate bullet to assert a phase-level outcome ("X capability works end-to-end and is observable"), NOT a specific command or test name. Plan/Implement/Test will turn these outcomes into concrete acceptance criteria with exact commands, fixtures, and file paths.

### R1-F04 scope-claude + R1-F01 scope-codex (low/medium, scope — double-flag) — accept. Slice descriptions name files

Slice descriptions enumerate `scripts/run-third-party-llm.sh`, `config.md`, `agents/qrspi-test-writer.md`, `.github/workflows/ci.yml`, BATS file names, glob patterns. Structure owns the file map; Phasing owns capability/layer-level deliverables.

**Fix:** Rewrite slice descriptions at the capability/layer level. Examples:
- BAD: "Touches: config.md schema, scripts/run-third-party-llm.sh, dispatch sites in skills."
- GOOD: "Touches: config schema layer, dispatcher script layer, skill-side dispatch sites."

Keep the demonstration sentence (which is the load-bearing "what this slice proves end-to-end") but strip exact file paths from the slice body. Structure will map capabilities to files.

## REJECT (3 — false claims or meta-issues, no edit needed)

### R1-F01 scope-claude — reject. roadmap.md exists on disk

`ls` confirms `/Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/agent-bravo/docs/qrspi/2026-05-17-v07-release/roadmap.md` (687 bytes, written by the synthesis subagent). The scope-claude reviewer's dispatch only carries `artifact_body` (phasing.md), so it cannot independently verify on-disk files; it inferred absence from phasing.md's lack of a roadmap table. This is the scope-claude dispatch contract limitation, not a phasing.md defect.

### R1-F02 scope-claude — reject. All 8 pruning files exist on disk

`ls` confirms: goals.md, future-goals.md, questions.md, future-questions.md, research/summary.md, future-research-summary.md, design.md, future-design.md — all present with reasonable sizes. Same dispatch limitation as F01.

### R1-F02 quality-codex — reject as artifact-fix, address as dispatch fix for round 2

quality-codex correctly noted that the review dispatch only surfaced 2 of 4 pruning artifact pairs (goals.md + design.md but not questions.md or research/summary.md). This is the orchestrator's dispatch contract — round 2 will include all 8 pruned + future-* artifacts in `companion_pruned_pairs`.

## Meta-issue carried forward

**Round 2 dispatch contract:** include companion_pruned_pairs covering all 8 files explicitly (already done — re-verify), AND consider passing the on-disk artifact list to scope-claude in some form so it doesn't false-positive on missing-deliverable claims for files that exist. For now, the simplest mitigation: include the round-1 disposition list in the round-2 dispatch context so the reviewer knows F01/F02 were already adjudicated.

## Fix dispatch plan

Single fix subagent. 4 accepts (1 HIGH split slices, 1 medium fixture, 2 medium boundary). All in phasing.md + roadmap.md.

## Status

draft → fixing → re-review round 2.

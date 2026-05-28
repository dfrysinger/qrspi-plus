---
round: 14
artifact: design
status: fixing
---

# Round 14 dispositions

## Findings inventory

- quality-claude: 4 findings (medium=2, low=2)
- scope-claude: 0 findings (clean — 12th consecutive)
- quality-codex: 3 findings (high=2, medium=1)
- scope-codex: 0 findings (clean — 11th consecutive)

Total: 7 findings. 1 intent-class surfaced to user; 6 correctness/clarity auto-applied. All accept.

Convergence trend: 10 → 3 → 5 → 4 → 2 → 4 → 3 → 4 → 6 → 1 → 2 → 3 → 6 → 7. Count uptick is dominated by new HIGH that refined prior fixes (G1 precedence summary line not updated when chain was expanded; G17 Option A added without checking against the CI runner contract). No scope drift.

## Intent-class (user-resolved)

### R14-F02 quality-codex (high, INTENT) — user chose: KEEP DEFERRED (acknowledge)

Codex flagged the G16 deferral as a unilateral intent change. User answered round-14 disposition question: "Keep deferred (acknowledge)." The deferral is now user-approved; the only required edit is anchoring the deferral text to that user approval so reviewers can trace it.

**Fix:** In design.md's G16 entry, replace "Deferred from v0.7" with "Deferred from v0.7 (user-approved at round-14 disposition gate)." Keep the existing rationale and the "Record this in future goals for a later release" sentence as-is.

## Correctness/clarity (auto-applied)

### R14-F01 quality-codex (HIGH, correctness) — accept. G1 precedence summary line out of sync

G1's detailed resolution chain (round-12+13 work) splits layer 1 into 1a (per-task `model:`) + 1b (hardcoded dispatch-site default). Summary line elsewhere in G1 collapses to "per-task > per-run > per-agent > built-in default," omitting layer 1b. Plan/Implement can derive two contradictory precedence orders.

**Fix:** Locate the summary line and rewrite to: "per-task `model:` > hardcoded dispatch-site `model:` > per-run `model_routing:` > per-agent `model:` > built-in default." Use the same terminology as the detailed chain. If the summary appears in multiple places (e.g., G1 prose + Decision section), update every instance.

### R14-F03 quality-codex (medium, correctness) — accept. G17 Option A bash 3.2.57 not on ubuntu-latest

G17 declares CI runs on `ubuntu-latest`; Option A requires macOS system bash (3.2.57). The two contradict. Plan could interpret Option A as valid on Ubuntu and silently miss the version gate.

**Fix:** In G17, split the CI surface contract:
- Main CI job runs on `ubuntu-latest` (BATS, shellcheck lint layer, version-compat Option B ban-list grep).
- Separate `macos-latest` job runs Option A (`bash --posix -n` on system bash 3.2.57) for the bash-3.2 parse check. The macos job is the load-bearing 3.2 gate.

Alternative if multi-runner CI is undesired: drop Option A and rely on Option B (ban-list grep) as the sole version-compat layer, all on `ubuntu-latest`. Recommendation: split-runner approach (separate macos job) is the better signal — Option B alone can miss novel bash-4+ constructs the ban-list does not enumerate.

### R14-F01 quality-claude (medium, clarity) — accept. G5 "the conditional is closed" misleading

G5 test-writer matrix row says "the conditional is closed" but the row body still expresses dual-mode routing. The phrase implies the dual-mode contract was REMOVED when it actually means both modes happen to share the same cheap-eligible outcome.

**Fix:** Replace "the conditional is closed" with explicit prose: "both modes (Test-phase and Implement-phase) route to cheap-eligible models under the same conditional — the modes are preserved (per the G6 dual-mode contract), but no model-routing split exists between them." Keep the routing cell content as-is.

### R14-F02 quality-claude (medium, correctness) — accept. G11 ui_producing deprecation contradicts Decision 10

G11 reconciliation says `ui: true` REPLACES `visual_fidelity_check.ui_producing` (schema deprecation), but Decision 10 claims all new task-spec fields are additive-with-safe-default. Plan/Implement may miss the migration step.

**Fix:** In Decision 10, add a note: "Exception: G11 `ui: true` replaces `visual_fidelity_check.ui_producing` (not purely additive). Migration: Plan authors a one-time migration task that rewrites existing `visual_fidelity_check: {ui_producing: true}` entries to top-level `ui: true`. After migration, `ui_producing` is removed from the schema." Update G11's reconciliation paragraph to cross-reference Decision 10's migration note.

### R14-F03 quality-claude (low, clarity) — accept. G3 N=2 vs goals' N=1 carve-out

G3 sets small-plan carve-out at "2 tasks or fewer" but goals.md described a "one-task" candidate. The threshold widening is unexplained.

**Fix:** In G3's Recommendation, add a one-sentence rationale for N=2: "Threshold widened from goals.md's N=1 to N=2 because a plan with exactly 2 tasks still fits in main chat context comfortably (combined LOC + task spec < 600 lines based on Q3 token budgets); the subagent overhead exceeds the context saving below N=3."

### R14-F04 quality-claude (low, clarity) — accept. G4 spike contract underspecified

G4 references "a Plan-time spike" to determine whether Claude Code Agent dispatches auto-cache, but does not specify deliverable, success/failure criteria, or what tasks are blocked on the spike outcome.

**Fix:** In G4's spike bullet, add a "Spike contract" sub-bullet:
- **Deliverable:** a one-page report at `docs/qrspi/2026-05-17-v07-release/spikes/g4-cache-probe.md` showing (a) whether `Agent({})` dispatch responses include Anthropic cache-hit metadata (cache_creation_input_tokens / cache_read_input_tokens), (b) hit rate on stable system-prompt prefixes across 3 reviewer dispatches.
- **Success criterion:** measurable cache_read_input_tokens > 0 on second-and-later dispatches with identical system prefix.
- **Failure path:** if no cache metadata exposed, G4 scope expands to include adding `cache_control` markers at the Anthropic SDK boundary (Plan authors that as a separate task).
- **Blocking:** G4 implementation tasks are blocked on spike completion. Other goals are not blocked.

## Fix dispatch plan

Single fix subagent. 7 accepts (1 user-resolved, 6 auto). All in design.md.

## Status

draft → fixing → re-review round 15.

# v0.5 Sequencing Plan

**Date:** 2026-05-03
**Status:** Approved for implementation
**Scope:** Order of execution for the 11 open issues in the v0.5 milestone

## Summary

v0.5 ships as **9 work units** (2 bundled pairs + 7 solos) across 4 tiers, organized **infra-first**: foundations that downstream work depends on land first, the experiment that needs review-worthy work to evaluate lands last.

## Decisions

| Decision | Choice | Why |
|---|---|---|
| Bundling policy | Bundle tightly-coupled pairs only (Option B) | Avoids redundant edits to shared schema/files; matches v0.4 PR #97 pattern |
| Ordering philosophy | Infra-first (Option 2) | #110 unblocks #109/#112; frontmatter unblocks any future task spec |
| #118 pair partner | #99 (auto-mode), not #115 | Substantive shared concern (auto-mode policy) vs surface similarity |
| #110 scope | **Widened** — all subagents defined in agent files, not just reviewers | Standardize the pattern; document any subagent that can't fit as an explicit exception |
| #109 implementation | **Copy `/code-review` skill pattern** | Don't reinvent; research that skill thoroughly first |
| #114 priority | Tier 3 (annoying not blocking) | Exit-12 bug isn't hitting day-to-day work |

## Bundles

- **#94 + #117** — both edit `tasks/task-NN.md` frontmatter (`task_type` + `model`). Schema work shipped once.
- **#99 + #118** — coherent auto-mode policy: imperative compaction prompts + Goals/Design auto-mode detection that suggests disabling for collaborative phases.

## Sequence

### Tier 1 — Foundations

1. **#110 — All subagents in agent files (broadened)**
   Keystone for the tier 2 work. Original scope was "custom subagent type for Claude reviewers"; widened to *all* subagents. Document any subagent that can't be expressed as an agent file as an explicit exception in the issue.

2. **#94 + #117 — Frontmatter bundle (`task_type` + `model`)**
   Codifies fields read by lightweight non-TDD path detection (#94) and Plan-skill-set implementer model selection (#117). Any task spec written from this point forward picks up both fields.

### Tier 2 — Built on the foundation

3. **#109 — Sonnet→Haiku confidence verifier**
   Validates the #110 pattern with a concrete second instance. **Implementation copies the `/code-review` skill pattern** — the research phase must inspect that skill closely so the copy is faithful, not approximate.

4. **#112 — Cluster detection / `scope_tag` derivation**
   Resolves the open B-vs-C design (orchestrator-derived vs dedicated `scope-tagger` subagent) with #109 as a real-world reference for how the subagent pattern feels in production. **Constraint:** `scope_tag` must not be reviewer-set (normalization drift + perspective leak).

### Tier 3 — Independent improvements

5. **#114 — Codex audit-write fix + audit surface inventory**
   Bug fix (exit 12) plus inventory of which audits still fire post-hooks-removal; prune vestigial.

6. **#99 + #118 — Auto-mode bundle**
   Imperative compaction prompts + Goals/Design auto-mode detection. Defaults: interactive skills auto-mode-off, pipeline stages auto-mode-on.

7. **#115 — Per-researcher dispatch prompt refinements**
   G13 direct-write reinforcement + summary-block-authored-last.

8. **#113 — Rename `round-NN-fixes.md` → `round-NN-dispositions.md`**
   Trivial. Slotted late so filename churn doesn't collide with heavier work in flight.

### Tier 4 — Experiment

9. **#116 — Serial vs parallel review experiment**
   Runs once on a v0.5 review round, measures `$` and wall time, decides on default. Last by necessity — needs review-worthy work shipped above it.

## Dependency rationale

- **#110 → #109 + #112** (real). Both can be implemented as instances of the agent-file subagent pattern. Shipping #110 first means they ship as instances, not retrofits.
- **#94 + #117 → all future task specs** (soft). Anything written in the Plan stage from this point picks up both fields automatically.
- **#116 → everything else above it** (hard). The experiment needs at least one v0.5 review round to evaluate.

## Out of scope for v0.5

- v0.6 issues: #91, #98, #24, #119
- Dead hook code cleanup (deliberately retained — Daniel may want it back for security work)
- 7-Apps auth setup for parallel CC session identity tracking (deferred to its own session)

## Pre-implementation actions

Before starting #110:

1. Comment on #110 widening its scope to "all subagents in agent files unless blocker."
2. Comment on #109 specifying `/code-review` skill as the pattern source.
3. Comment on #112 reaffirming `scope_tag` is not reviewer-set, and that #109 is the reference instance for the subagent option.

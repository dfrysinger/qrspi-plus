---
finding_id: R1-F03
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/plan.md
artifact: plan.md
round: 1
reviewer: quality-claude
---

# T13 references post-rename `dispatch-agent.sh --implementer-commit` without depending on T20, and no task owns the new subcommand

## What's wrong

T13 (G9 per-task review orchestration, around plan.md line 815) modifies `skills/implement/SKILL.md` to install a between-round checklist invoking the renamed dispatcher under a new subcommand:

> **Scope > In:** ... "Insert the G9 between-round checklist into `skills/implement/SKILL.md` at the per-task reviewer fan-out site, covering scope-tagger dispatch, implementer `commit_sha:` extraction, **`dispatch-agent.sh --implementer-commit` invocation**, and exit-code branches for success, orchestrator bug, worktree integrity break, and implementer re-dispatch."
>
> **Test expectations:** ... "Grep audit on `skills/implement/SKILL.md`: the per-task reviewer fan-out section contains the checklist items for ... `dispatch-agent.sh --implementer-commit`, and exit-code branches 0/10/11/12."
>
> **Dependencies:** Task 12

Two interlocking gaps with this:

### Gap A — Rename ordering

The script name `dispatch-agent.sh` does not exist until T20 (G3, plan.md line 1229) lands the hard rename of `scripts/run-codex-review.sh` → `scripts/dispatch-agent.sh`. T20's bullet list confirms: "rename `scripts/run-codex-review.sh` → `scripts/dispatch-agent.sh`". T13's only declared dependency is T12.

The overview's Dependency Graph section enumerates three cross-slice chains and explicitly omits T13 from the G3 rename chain ("G3 splitter rename (Slice 1.4) → G16 dispatch-agent path-filter (Slice 1.4) → G32 build pipeline (Slice 1.7)"). If T13 lands before T20 (legitimate under the declared deps), implement/SKILL.md will contain a grep-audited instruction to invoke a script that does not yet exist under that name.

### Gap B — Missing subcommand owner

Even granting that T20 introduces the renamed binary, neither T20's spec nor T13's Target-files list adds an `--implementer-commit` subcommand to `dispatch-agent.sh`. T13 modifies `scripts/round-prepare.sh` (the per-task SHA / commit-anchor work belongs there), and the recovery codes 10/11/12 T13 names match the exit codes T12 already documented on `round-prepare.sh`. T20's scope is the dispatcher rename + per-skill prose migration, with no new subcommand mentioned.

So the orchestrator instruction `dispatch-agent.sh --implementer-commit <sha>` references a CLI subcommand that no task in this plan creates. Either (a) the instruction should call `scripts/round-prepare.sh` directly (which matches the per-task target-file work T13 actually does), or (b) some task must add a thin `--implementer-commit` subcommand wrapper to `dispatch-agent.sh` and that work needs an owner with the right deps.

## Why it matters

This is the same v0.7.1 failure-mode class the release is trying to close — Plan-phase under-scoping cross-task consumer surface (G18). T13 names a contract surface (a wrapper subcommand) without enumerating which task creates it. Compounded with the rename-ordering gap, an Implement-phase orchestrator dispatching T13 ahead of T20 will produce a green per-task gate (T13's grep audits pass against the prose T13 itself authored) while the actual instruction is unrunnable, and the breakage surfaces only at the next per-task review round on a different task.

## Suggested fix

Pick one of:

1. **Drop the subcommand wrapper.** Rewrite T13's `dispatch-agent.sh --implementer-commit` references to call `scripts/round-prepare.sh` directly. T13 already owns round-prepare.sh modifications and the recovery-code wiring is self-contained there. Then add T20 to T13's Dependencies only if implement/SKILL.md's per-task checklist also references the renamed dispatcher for other reasons (it may; if so, the prose still needs T20 ahead of T13).

2. **Give the subcommand an owner.** Add `scripts/dispatch-agent.sh (modify)` to T13's Target files plus an In-scope deliverable defining the `--implementer-commit <sha>` subcommand semantics (or assign that work to T20's already-large rename task), AND add T20 to T13's Dependencies so the rename precedes T13's grep-audited prose.

Either resolution should also be reflected in the Dependency Graph commentary so the third bullet's chain reads ".../G3 splitter rename (Slice 1.4) → {G9 per-task orchestration (Slice 1.3), G16 dispatch-agent path-filter (Slice 1.4), G32 build pipeline (Slice 1.7)}." if option 2 is chosen.

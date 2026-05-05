# Prose-Sweep Bundle: #99 Compaction-Prompt Imperative + #40 LOC-Ceiling Clarification

**Status:** Design
**Issues:** [#99](https://github.com/dfrysinger/qrspi-plus/issues/99), [#40](https://github.com/dfrysinger/qrspi-plus/issues/40)
**Milestone:** v0.5
**Date:** 2026-05-05

## 1. Bundle Rationale

Both issues are cross-cutting prose clarifications with no schema, routing, or runtime impact. Both target SKILL.md prose surfaces. Bundling into one PR avoids reviewing two near-identical "audit and edit prose" PRs back-to-back; neither is large enough to warrant its own spec round.

Per the qrspi-plus prose-handling preference: skip full reviewer suite, decide test handling per change, no TDD ceremony.

## 2. #99: Compaction-Prompt Imperative Sweep

### 2.1 Problem

QRSPI SKILLs carry "compaction recommended" notes scattered across ~12 SKILL.md files at four overlapping transition points (pre-large-subagent-dispatch, pre-review-loop, terminal-state, cross-skill-transition). In a real v0.4-bundle session (2026-04-29), the orchestrator skipped every applicable trigger across the Research stage. Four reasons the current shape fails:

1. **Conditional + no instrument.** The notes say "if context utilization may exceed ~50%" but the agent has no telemetry for current utilization. Soft conditional + no signal → "probably fine, keep going."
2. **Blockquote reads as advisory.** `> **IMPORTANT — Compaction recommended.** ...` reads as a side-note. Compare to `<HARD-GATE>` blocks at the top of skill files — those have teeth.
3. **Auto-mode pressure.** Auto-mode rules tell the agent to "minimize interruptions, prefer action." Recommending /compact is exactly the pause auto-mode is told to skip.
4. **Duplicated prose, drift risk.** The same Iron Rule shape ("do not skip this check") is repeated inconsistently across SKILLs. The pre-review-loop site in Plan has it; the pre-fanout site in Research doesn't. The drift is invisible at edit time.

The fix shape changes both the prose form (imperative + Iron Rule) **and** the layout (DRY canonical contract + per-site labels).

### 2.2 Transition-type taxonomy (canonical map)

The four overlapping transition points collapse to **two named checkpoint types** plus a **piggyback rule**:

| Mechanism | Trigger condition | TaskCreate? |
|---|---|---|
| `pre-fanout` checkpoint | Before any parallel subagent dispatch (research specialists, plan per-task spec generators, parallel reviewers, parallel implementers, integration sub-stages). Replaces the previous "pre-large-subagent-dispatch" + "pre-review-loop" framings — both are fan-outs at runtime. | **Yes.** |
| `pre-handoff` checkpoint | At end-of-skill, after artifact committed, before invoking the next skill in the route. Collapses the previous "terminal-state" + "cross-skill-transition" — they fired back-to-back today and the distinction was artificial. | **Yes.** |
| **Piggyback rule** (not a separate checkpoint) | At every existing user-input pause anywhere in any QRSPI skill — review-loop pause-gate menus, verifier-uncertain surfacing, max-rounds-reached prompts, artifact-approval gates (Goals, Design, plan-final), replan-gate decisions, etc. The compact recommendation is surfaced alongside whatever question or content the SKILL is already showing the user. | **No** — the existing user-input prompt is itself the visibility surface. |

**Key principle for the piggyback rule.** This rule does **not** introduce new pauses. It piggybacks on whatever pauses the SKILLs already create. If a review round loops clean and never pauses, no compact reminder fires. If a SKILL already pauses for any user-input reason, the compact recommendation rides along with the existing prompt.

**Net change vs today's map.** Same coverage of context-bloat surfaces. The piggyback rule replaces the previous "post-review-round" idea — finer-grained (every existing pause, not just end-of-loop), no new pauses introduced, applies broadly across all SKILLs not just review. Two artificial pairs (terminal+cross-skill, pre-fanout+pre-review-loop) collapsed. One TaskCreate per skill run (at `pre-handoff`).

### 2.3 Canonical contract — `using-qrspi/SKILL.md` § Compaction Checkpoints

The Iron Rule contract lives in **one place** rather than duplicated across 12 SKILLs. New section in `skills/using-qrspi/SKILL.md` (the umbrella that every QRSPI skill invokes at start, so the contract is loaded once per run):

```markdown
## Compaction Checkpoints

QRSPI skills mark transition points where main-chat context bloat degrades downstream quality. At every checkpoint and at every user-input pause, the orchestrator follows the Iron Rule below — regardless of perceived utilization, regardless of auto-mode.

**Iron Rule.** Pause and recommend `/compact` to the user before continuing. The user can decline; do not skip the recommendation.

**Auto-mode interaction.** Compaction recommendations are exempt from the auto-mode "minimize interruptions, prefer action" guidance. They exist precisely because mid-flight context bloat is the failure mode auto-mode runs into; honoring the recommendation is honoring the user's broader intent (deep, coherent execution), not interrupting it.

**Two named checkpoints + a piggyback rule.**

| Mechanism | Trigger | TaskCreate? |
|---|---|---|
| `pre-fanout` checkpoint | Before any parallel subagent dispatch. | **Yes.** |
| `pre-handoff` checkpoint | At end-of-skill, after artifact committed, before invoking the next skill. | **Yes.** |
| Piggyback rule | At every existing user-input pause (review pause-gate menus, verifier-uncertain prompts, max-rounds-reached prompts, artifact-approval gates, replan-gate decisions, any other "wait for user response" moment). Surface the compact recommendation **alongside** whatever the SKILL is already asking. Do **not** introduce new pauses. | No. |

**TaskCreate at named checkpoints.** When the orchestrator reaches either named checkpoint (`pre-fanout` or `pre-handoff`), in addition to surfacing the imperative pause, call:

`TaskCreate({ subject: "Recommend /compact ({checkpoint-type}) — {current-skill-name}", description: "{checkpoint-type}: {one-line stage-specific reason}. User decides whether to /compact." })`

Mark the task `completed` once the user responds either way. The TaskCreate makes the recommendation visible in the user's task list. Piggyback pauses do **not** call TaskCreate — the existing user-input prompt at that site is itself the visibility surface, and a task entry would double-surface the same recommendation.

**Per-checkpoint label format.** Every named checkpoint (`pre-fanout` / `pre-handoff`) in any SKILL.md uses this one-line shape:

`**Compaction checkpoint: {type}.** {Stage-specific reason — one sentence.} See using-qrspi `## Compaction Checkpoints` for the iron-rule contract.`

**Piggyback-pause format.** Existing user-input prompts gain a one-line addition (typically the last bullet or last sentence of the prompt):

`Before responding, consider running `/compact` — context may be saturated. (You can decline; this is a reminder, not a gate.) See using-qrspi `## Compaction Checkpoints`.`

The Iron Rule itself is NOT restated at per-site labels or piggyback-pause additions — the canonical contract above is the single source of truth. Per-site rationale stays specific to the moment (e.g., "Reviewer fan-out reads synthesis state; saturated context produces truncated findings"), the Iron Rule stays shared.
```

### 2.4 Per-site sweep

For each SKILL.md compaction site (audited via `grep -rE 'Compaction recommended' skills/`), replace the existing blockquote with a one-line label per the canonical format:

**Before (e.g., `skills/plan/SKILL.md:238`):**
```
> **IMPORTANT — Compaction recommended (pre-review-loop).** The merged `plan.md` plus `goals.md` + `research/summary.md` + `design.md` + `structure.md` are about to be handed to the review-round dispatch. Reviewer findings only land cleanly on a context that still holds the synthesis decisions; if utilization may exceed ~50%, run `/compact` now — before reviewers dispatch — so the upcoming cross-file consistency checks have headroom. **Iron Rule:** review-round dispatch is the highest-leverage compaction moment in Plan; do not skip this check.
```

**After:**
```
**Compaction checkpoint: pre-fanout.** Reviewer fan-out reads synthesis state; saturated context produces truncated findings on the cross-file consistency checks. See using-qrspi `## Compaction Checkpoints` for the iron-rule contract.
```

The "highest-leverage compaction moment in Plan" framing isn't lost — the canonical contract codifies the Iron Rule, and the stage-specific reason carries the site-specific weight.

### 2.5 Sweep targets — two passes

The implementation proceeds in two passes, since the sweep covers both named checkpoints (replacing existing blockquote sites) and piggyback additions (touching existing user-input prompts that don't currently mention compaction at all).

**Pass 1 — named checkpoints.** Sites confirmed by `grep -rE 'Compaction recommended' skills/`. Each existing blockquote reclassifies to either `pre-fanout` or `pre-handoff`:

| File | Existing label | New checkpoint type |
|---|---|---|
| `research/SKILL.md` | pre-review-loop, terminal-state, cross-skill | `pre-fanout`, `pre-handoff` (last two collapse) |
| `design/SKILL.md` | pre-review-loop, others | `pre-fanout`, `pre-handoff` |
| `structure/SKILL.md` | (audit) | `pre-fanout`, `pre-handoff` |
| `plan/SKILL.md` | 6 sites: pre-large-subagent-dispatch (×2), pre-review-loop, others | Two `pre-fanout` (per-task fan-out + reviewer fan-out), one `pre-handoff` |
| `parallelize/SKILL.md` | (audit) | typically just `pre-handoff` |
| `implement/SKILL.md` | (audit) | `pre-fanout`, `pre-handoff` |
| `integrate/SKILL.md` | (audit) | `pre-fanout`, `pre-handoff` |
| `test/SKILL.md` | (audit) | `pre-handoff` |
| `replan/SKILL.md` | (audit) | `pre-fanout`, `pre-handoff` |
| `phasing/SKILL.md` | (audit) | `pre-handoff` |
| `questions/SKILL.md` | (audit) | `pre-handoff` |
| `using-qrspi/SKILL.md` | (umbrella; carries the canonical contract per §2.3) | N/A — host of the contract |

**Pass 2 — piggyback additions at existing user-input pauses.** Sites identified by greping for existing user-input prompt patterns. Each gets the one-line piggyback-pause format from §2.3 added to the existing prompt body (typically as the last bullet or sentence). Audit candidates:

- **Review-loop pause-gate menus** — wherever a SKILL surfaces the 3-option pause menu (apply / skip / loop back to upstream artifact) for `scope`/`intent` findings or `uncertain` verifier returns. Likely centralized in `using-qrspi/SKILL.md` `## Review Output Handling` and per-skill review-round sections.
- **Artifact-approval gates** — Goals approval, Design approval, plan-final approval, structure approval, etc. Each SKILL has a "present to user, await approval" prompt at the end of synthesis (typically before the named `pre-handoff` checkpoint).
- **Replan-gate decisions** — `replan/SKILL.md` surfaces phase-boundary decisions to the user.
- **Max-rounds-reached prompts** — the review-loop ceiling triggers a user-input pause (likely in `using-qrspi/SKILL.md` or per-skill review-round logic).
- **Any other ad-hoc user-input pause** discovered via grep — implementer surfaces unexpected sites as a question rather than guessing.

**Implementer's audit step.** For each SKILL, two passes: (1) grep for `Compaction recommended` and reclassify the blockquote sites to named checkpoints; (2) grep for user-input pause patterns (e.g., "await approval", "ask the user", "surface to the user", pause-gate menu invocations) and add the piggyback-pause line. The exact pattern set is established during implementation — the spec's role is to define the rule, not enumerate every pause site.

**Site count change.** Old: ~25 scattered sites with duplicated Iron Rule prose. New: ~22 one-line named-checkpoint labels + an estimated ~15–25 piggyback-pause additions + 1 canonical contract. Net: more total reminder surfaces (the piggyback rule expands coverage), but each surface is one line citing a single canonical contract — drift cost stays low.

### 2.6 Test handling

One bats file: `tests/unit/test-compaction-checkpoints.bats`

```bash
@test "no compaction prompt remains in legacy blockquote form" {
  local offenders
  offenders=$(grep -rE '^> \*\*IMPORTANT — Compaction recommended' skills/ || true)
  if [ -n "$offenders" ]; then
    echo "legacy blockquote compaction prompts:"
    echo "$offenders"
    return 1
  fi
}

@test "no compaction prompt retains the may-exceed-50% conditional" {
  local offenders
  offenders=$(grep -rE 'if (context )?utilization may exceed' skills/ || true)
  if [ -n "$offenders" ]; then
    echo "compaction prompts retain conditional form:"
    echo "$offenders"
    return 1
  fi
}

@test "every checkpoint label uses one of the two canonical types" {
  local offenders
  offenders=$(grep -rE '\*\*Compaction checkpoint:' skills/ \
    | grep -vE '\*\*Compaction checkpoint: (pre-fanout|pre-handoff)\.\*\*' \
    || true)
  if [ -n "$offenders" ]; then
    echo "checkpoint labels with non-canonical type:"
    echo "$offenders"
    return 1
  fi
}

@test "every named checkpoint prescribes TaskCreate within 6 lines" {
  local skills offenders
  skills=$(grep -lE '\*\*Compaction checkpoint: (pre-fanout|pre-handoff)\.\*\*' skills/ -r || true)
  for f in $skills; do
    awk '/\*\*Compaction checkpoint: (pre-fanout|pre-handoff)\.\*\*/{flag=1; n=0; found=0} flag{n++; if (n>6) {flag=0; if (!found) print FILENAME": named-checkpoint site missing TaskCreate"; found=0} if (/TaskCreate/) found=1}' "$f" \
      || return 1
  done
}

@test "using-qrspi/SKILL.md carries the canonical Compaction Checkpoints section" {
  grep -qE '^## Compaction Checkpoints' skills/using-qrspi/SKILL.md \
    && grep -qE 'Iron Rule\..*Pause and recommend' skills/using-qrspi/SKILL.md
}
```

Five assertions: legacy blockquote regression, legacy conditional regression, canonical-type enforcement on per-site labels, TaskCreate presence at `pre-handoff` sites, and canonical contract presence in `using-qrspi`. ~50 lines of bats; the layered checks defend the DRY structure (per-site labels can't drift to non-canonical types; canonical contract can't be silently deleted).

### 2.7 Out of scope

- **Alternative (a) — hook-enforced compaction.** Real engineering: needs context-utilization estimator + Claude Code hook integration + per-stage thresholds. Deferred to a future v0.x; revisit if the imperative + canonical-contract + piggyback-rule + TaskCreate-at-checkpoints fix proves insufficient.
- **TaskCreate at piggyback pauses.** Piggyback sites stay prose-only — the existing user-input prompt at that site is itself the visibility surface, and a task entry would double-surface the same recommendation.
- **Adding new pauses anywhere.** The piggyback rule is strict: it rides on existing pauses only. If a SKILL has no user-input pause at a particular moment, this PR does not introduce one.
- **Adding a third checkpoint type** (e.g., "session-start" or "before-rejection-loop"). Two named types + the piggyback rule covers the load-bearing surface today.

## 3. #40: LOC Ceiling = Source-Only Clarification

### 3.1 Problem

`skills/plan/SKILL.md` § Task Sizing prescribes a 200-LOC ceiling per task without specifying whether tests count. F-21 (`docs/qrspi/2026-04-26-prompt-improvements/findings.md`) observed Phase 1 tasks running 89–133 src LOC but 290–420 LOC counting tests + fixtures. Reviewers will rationalize the ambiguity inconsistently across tasks.

### 3.2 Fix shape

One-line addition to `skills/plan/SKILL.md` in the Task Sizing section:

> **"LOC" = implementation source only** (counted across files in `Target files:` excluding `tests/`). Test code has no ceiling but should be roughly proportional to behaviors covered (rule of thumb: 1.5–2× impl LOC for full-behavior coverage). A task with 100 src LOC and 250 test LOC is fine; one with 250 src LOC needs a `sizing_exception` or split.

This pairs with the existing "one observable behavior per task" framing — sizing is impl-defined, not test-defined.

### 3.3 Test handling

No test surface. `tests/unit/` carries no plan-reviewer task-sizing fixture today (verified by listing). Adding one is out of scope for a one-line clarification; the reviewer agent files (`agents/qrspi-plan-reviewer.md`, `agents/qrspi-plan-scope-reviewer.md`) read the sizing rule from `plan/SKILL.md` directly.

If a future PR adds plan-reviewer fixtures, it should include a `150 src + 280 test` case classified as within-ceiling.

## 4. Sequence

Single PR. Three commits (group by atomicity unit):

1. **`docs(plan): #40 LOC ceiling = src-only clarification`** — the smaller, more isolated change lands first; independent of #99.
2. **`docs(using-qrspi): #99 add canonical Compaction Checkpoints contract`** — adds the new section in `using-qrspi/SKILL.md`. Lands before per-site sweep so sweep references resolve.
3. **`docs(skills): #99 sweep per-site compaction labels + tests`** — replaces every blockquote site with a one-line canonical label per the §2.5 reclassification table; adds `tests/unit/test-compaction-checkpoints.bats` (which now passes because both the contract and the swept sites are in place).

Test plan:
- `bats tests/unit/test-compaction-checkpoints.bats` — all five assertions pass.
- `bats tests/unit/` — full suite green.
- Manual scan: open `using-qrspi/SKILL.md` and confirm the canonical contract reads cleanly; open Plan SKILL (highest site count) and confirm each former site is now a one-line label pointing at the canonical contract.

## 5. Backwards compatibility

Pure prose. No agent file, schema, or routing impact. Skills consuming the swept SKILLs (i.e., the orchestrator's runtime path through them) read the imperative prose the same way they read the blockquote prose — the agent's behavior change is the point of the fix, not a breaking change.

## 6. Closes

- Closes #99
- Closes #40

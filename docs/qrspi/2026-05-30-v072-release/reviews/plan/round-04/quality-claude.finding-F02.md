---
finding_id: F02
severity: low
change_type: clarity
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/plan.md
artifact: docs/qrspi/2026-05-30-v072-release/plan.md
---

# Dep-graph item 4 and Task 13 `Blocks:` both misidentify the surface T20 consumes from T13

## What

Two adjacent rationale surfaces in the plan claim that Task 20's G3 splitter rename consumes Task 13's `scripts/round-prepare.sh` edits. T20 does not in fact modify or reference `scripts/round-prepare.sh`; the real shared edit surface forcing T13 → T20 is `skills/implement/SKILL.md`, which both tasks modify.

Evidence:

1. **Overview cross-slice chain (plan.md L17, chain (b)):**
   > T13's per-task round-prepare edits all land before T20's G3 splitter rename (T09/T11/T13 → T20), so the pre-rename dispatch surface is fully provisioned before the script hard-rename collapses it.

   And dep-graph item 4 (plan.md L112):
   > T09, T11, and T13 all modify the pre-rename dispatch surface (`scripts/run-codex-review.sh` for T09/T11; **`scripts/round-prepare.sh` for T13**)

2. **Task 13 `Blocks:` clause (plan.md L808):**
   > **Blocks:** T20 (G3 dispatch-script rename consumes this task's `scripts/round-prepare.sh` per-task scope-tagger + commit-anchor edits).

3. **What T20 actually modifies (plan.md L1176):** T20's target-files list renames `run-codex-review.sh` → `dispatch-agent.sh`, renames `run-third-party-llm.sh` → `dispatch-companion.sh`, renames `codex-finding-splitter.sh` → `third-party-finding-splitter.sh`, modifies `scripts/await-round.sh`, creates `skills/_shared/reviewer-dispatch-prose.md`, and modifies 12 SKILL.md consumers including `skills/implement/SKILL.md`. **It does not touch `scripts/round-prepare.sh`.**

4. **What T13 actually modifies (plan.md L807):** `scripts/round-prepare.sh`, `skills/implement/SKILL.md`, `tests/unit/test-scope-tagger-dispatch.bats`.

The overlap surface that forces T13 to land before T20 is `skills/implement/SKILL.md`: T13 inserts the G9 between-round checklist into the per-task reviewer fan-out section, and T20's 12-skill consumer migration replaces the per-skill dispatch block in the same file. If T20 lands first, T13's insertion-site language drifts; if T13 lands first, T20 migrates against the post-G9 surface.

(The neighboring claim in chain (b) that T09 and T11 modify `scripts/run-codex-review.sh` is correct — both edit the pre-rename file. The bug is specifically the `scripts/round-prepare.sh` citation for T13.)

## Why it matters

The dep is correct and load-bearing — T13 truly must precede T20. The rationale is what's wrong, in two places that mirror each other (Overview narrative + Task 13's `Blocks:` clause). At Plan altitude this matters because:

1. **A reader auditing the dep graph traces the wrong file.** Anyone validating the T13 → T20 dependency by grepping the round-prepare.sh diff between the two task commits will find no overlap and conclude the dep is spurious — potentially removing it and reintroducing the real `skills/implement/SKILL.md` merge conflict.
2. **The mis-citation undermines round-03's cross-slice-chain edit.** Round-03 added the T09/T11/T13 → T20 chain to the Overview specifically to make the pre-rename surface story explicit. Including a wrong file citation in that chain weakens the audit trail it exists to provide.

## Suggested fix

Two coupled edits:

**1. Plan Overview L17 chain (b)** — change the parenthetical for T13:

Before:
```
T09's `actual_model:` provenance edits and T13's per-task round-prepare edits all land before T20's G3 splitter rename
```

After:
```
T09's `actual_model:` provenance edits and T13's per-task `skills/implement/SKILL.md` between-round checklist edits all land before T20's G3 splitter rename
```

**2. Plan Dep-Graph item 4 (L112)** — correct the file citation:

Before:
```
T09, T11, and T13 all modify the pre-rename dispatch surface (`scripts/run-codex-review.sh` for T09/T11; `scripts/round-prepare.sh` for T13)
```

After:
```
T09 and T11 modify the pre-rename dispatch surface `scripts/run-codex-review.sh`; T13 modifies `skills/implement/SKILL.md` at the per-task reviewer fan-out site, which T20's 12-skill consumer migration also rewrites
```

**3. Task 13 `Blocks:` clause (L808)** — match the corrected rationale:

Before:
```
**Blocks:** T20 (G3 dispatch-script rename consumes this task's `scripts/round-prepare.sh` per-task scope-tagger + commit-anchor edits).
```

After:
```
**Blocks:** T20 (G3 dispatch-script rename and 12-skill consumer migration share the `skills/implement/SKILL.md` per-task reviewer fan-out edit surface this task inserts the G9 between-round checklist into).
```

No task target-file changes needed — the dep itself is right, only the explanation text drifts.

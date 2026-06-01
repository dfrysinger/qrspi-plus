---
finding_id: R5-F01
reviewer_tag: quality-claude
artifact: structure
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
  - docs/qrspi/2026-05-30-v072-release/design.md
---

# Halt-response protocol (CD-4 §I.3) missing from `implement/SKILL.md` and §17 consumer/writer attribution

## What the structure says

R4 extended Slice 1.2's `skills/using-qrspi/SKILL.md` responsibility cell to carry the orchestrator-side halt-response protocol (rescue layer + drift counting) and added Interface §17 `.orchestrator-fixes.json`:

> `skills/using-qrspi/SKILL.md` … Modify … "Define round instrumentation, sub-threshold observation logging, verifier-visible audit surfaces, and **orchestrator-side halt-response protocol (CD-4 §I.3): read `orchestrator_rescue` and `max_drift_per_round` from config.md to gate rescue-layer behavior and drift-count enforcement**." (Slice 1.2, line 36)

> "Path: `<round-dir>/.orchestrator-fixes.json`. **Writer: orchestrator rescue layer** … **Consumer: `using-qrspi/SKILL.md` round-summary prose surface**, which sources per-tier counts for `round-NN-dispositions.md`." (§17, line 480)

`skills/implement/SKILL.md` only appears in Slice 1.3 ("Require `round-prepare` outputs and scope-tagger/fan-in artifacts …", line 50) and Slice 1.4 ("Adopt shared reviewer dispatch and pass per-task tier overrides …", line 86). Neither row carries any halt-response, rescue-tier, or `.orchestrator-fixes.json`-write responsibility.

## Why this is a structural gap

Design CD-4 §F (line 458) is explicit that both consumers host the verifier-fan-in invocation at their respective apply-fix levels:

> - `using-qrspi/SKILL.md` — … Replace the per-finding verifier dispatch loop … with `scripts/dispatch-agent.sh --verifier-fanout …` … followed by `await-round.sh`.
> - `implement/SKILL.md` — … replace the per-finding verifier dispatch loop … with the same single `dispatch-agent.sh --verifier-fanout` + spec-line iteration + `await-round.sh` pattern; **add a precondition that `scripts/verifier-fan-in.sh` must have exited 0 for the round before apply-fix runs**.

Design CD-4 §I.3 (lines 519–541) frames the halt-response protocol generically — "Orchestrator-side rescue does NOT compute the kept set" / "Every halt cause escalates …" / `.orchestrator-fixes.json` written "after each successful tier 1/2/3 fix completes". The protocol fires whenever `scripts/verifier-fan-in.sh` halts non-zero. That can happen at *either* level — artifact-level apply-fix (using-qrspi rounds) and per-task apply-fix (implement rounds). The implement-side precondition ("verifier-fan-in.sh must have exited 0 before apply-fix runs") makes this concrete: if fan-in halts mid-task, the per-task orchestrator has to execute the same rescue→retry→escalate→drift-count→write-audit ladder, and write the per-tier breakdown into the per-task round's `round-NN-dispositions.md`.

As R4 currently locks structure:

1. **No row in any slice puts halt-response on `implement/SKILL.md`.** A planner reading the file map will not author rescue-layer prose into `implement/SKILL.md` because nothing in its Modify cells says to.
2. **§17 names only `using-qrspi/SKILL.md` as the round-summary consumer.** A planner reading §17 will not wire `.orchestrator-fixes.json` reads into `implement/SKILL.md`'s apply-fix surface.
3. **No shared snippet absorbs the protocol.** Slice 1.1's `skills/_shared/verifier-dispatch-prose.md` responsibility is scoped narrowly to "`dispatch-agent.sh --verifier-fanout` invocation + spec-line contract + `await-round.sh` follow-up" (line 20) — it does not carry the post-halt rescue layer. So there is no `!cat` path by which `implement/SKILL.md` would inherit the protocol implicitly.

The net effect: at structure altitude, the per-task apply-fix loop is shown invoking `verifier-fan-in.sh` (via Slice 1.3 + the shared dispatch snippet) but has no documented response when it halts. Either the per-task path silently has no rescue layer (contradicts design CD-4 §I.3's generic framing and §I.5 iron-rule preservation, which applies "under every interaction-mode × rescue-config combination"), or the responsibility is implicit and Plan/Implement will have to invent the placement.

## What to fix

Pick one of these three resolutions (all are structurally adequate; the first two are cheaper):

**Option A — Mirror the responsibility on `implement/SKILL.md`.** Add a Slice 1.2 row for `skills/implement/SKILL.md` with the same halt-response wording, e.g.: "Modify — Carry per-task orchestrator-side halt-response protocol (CD-4 §I.3): read `orchestrator_rescue` and `max_drift_per_round` from config.md to gate rescue-layer behavior at per-task apply-fix; write per-tier rescue breakdown into per-task `round-NN-dispositions.md` from `.orchestrator-fixes.json`." Then update §17's Writer/Consumer wording from "`using-qrspi/SKILL.md` round-summary prose surface" to "`using-qrspi/SKILL.md` (artifact-level) and `implement/SKILL.md` (per-task) round-summary prose surfaces".

**Option B — Lift the protocol into a shared snippet.** Add `skills/_shared/halt-response-protocol.md` (Create) to Slice 1.2 with responsibility "Hold the single CD-4 §I.3 halt-response protocol prose (rescue tiers, drift counting, dispositions write) consumed by `using-qrspi/SKILL.md` and `implement/SKILL.md`." Then both consumer SKILL.md rows just `!cat` it, matching the pattern already used for `verifier-dispatch-prose.md` (Slice 1.1 → both consumers). Update §17 Writer to "orchestrator rescue layer (prose lives in `skills/_shared/halt-response-protocol.md`, `!cat`-included into `using-qrspi/SKILL.md` and `implement/SKILL.md`)" and Consumer to name both surfaces. Add the new shared file to the Section Contracts table.

**Option C — Explicitly scope the protocol to artifact-level only.** Add a one-line note in Slice 1.2 / §17 saying the rescue layer intentionally does not fire at per-task apply-fix (e.g., per-task halts surface as a hard fail to the artifact-level orchestrator instead). This contradicts design CD-4 §I.3's framing, so it would also require a backward loop to design to record that scoping decision — making this the most expensive option and recommended only if there is a real reason per-task apply-fix should not rescue.

Option B is the strongest structural fit because it preserves the same DRY pattern already established for verifier-dispatch-prose; Option A is the simplest local edit if the planner prefers to keep the protocol out of `_shared/`.

---
finding_id: R1-F08
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L820-L831]
artifact: plan
round: 1
reviewer: silent-failure-claude
---

T27's description specifies: "Absence of `wave_context:` is legal (first-wave dispatches, single-UI-task plans) and is treated as 'no sibling history.'" This is an explicit silent fallback: when `wave_context:` is absent, the visual-fidelity reviewer proceeds without sibling context. The plan characterizes this as legal and non-failing.

However, there is a subset of cases where `wave_context:` absence in a later-wave dispatch is an error, not a legal "first-wave" condition. If wave 2 of a multi-wave release has multiple sibling UI tasks from wave 1 that produced visual-fidelity findings, but the `wave_context:` companion is absent from the wave-2 dispatch due to an orchestrator bug (T27's companion assembly code failing silently), the visual-fidelity reviewer proceeds as if it is a first-wave dispatch with no sibling history — and produces findings that contradict or ignore wave-1 reviewer findings.

The test expectations for T27 say "Absence of `wave_context:` on first-wave or single-UI-task dispatches is legal and dispatch proceeds" — but there is no test expectation that distinguishes the case where `wave_context:` is absent on a later-wave dispatch that SHOULD have sibling history, from the case where it is genuinely absent because it is a first-wave dispatch. The caller (the Implement orchestrator) cannot distinguish these cases: absence reads as "no sibling history" either way.

The fix is to add a test expectation in T27 or T30 specifying how the orchestrator signals the absence-is-expected case versus the absence-is-an-error case. One concrete option: the orchestrator passes an explicit `wave_number: 1` or `wave_number: 2` companion parameter, and the reviewer treats `wave_context:` absence as a load-bearing diagnostic when `wave_number > 1` with multiple sibling UI tasks in the plan. This prevents the silent-fallback from hiding an orchestrator bug in the wave_context assembly code.

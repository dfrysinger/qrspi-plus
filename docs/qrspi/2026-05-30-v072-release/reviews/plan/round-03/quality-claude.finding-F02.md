---
finding_id: F02
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/plan.md
  - docs/qrspi/2026-05-30-v072-release/phasing.md
artifact: docs/qrspi/2026-05-30-v072-release/plan.md
---

## Task 11 (now [G3]) listed under Slice 1.2 but G3 belongs to Slice 1.4 per phasing.md — unexplained slice/goal mismatch

**Location.** `plan.md` lines 45–50 (Slice 1.2 task listing) and L675–727 (Task 11 spec body).

The Slice 1.2 task list reads:

> ### Slice 1.2 — Verifier rubric calibration + instrumentation
>
> - **Task 08 — G19 verifier wholesale-hallucination rubric class** — goals: [G19] ...
> - **Task 09 — G20 reviewer-model calibration for task-tool-substituted Codex model** — goals: [G20] ...
> - **Task 10 — G28 verifier convergent-evidence exception and sub-threshold-observations instrumentation** — goals: [G28] ...
> - **Task 11 — G3 dispatch-manifest provenance fields (`subagent_type`/`host`/`vendor`/`model`/`prompt_file` in `.dispatch-manifest.json`)** — goals: [G3] ...

**Problem.** Per `phasing.md` (the authoritative slice decomposition):

- Slice 1.2 surface (phasing.md L58–67): "verifier scoring rubric (hallucination class detection, model calibration), and the dispositions + sub-threshold-observations instrumentation formalized in G28." Slice 1.2 goals are **G19, G20, G28, G29**.
- Slice 1.4 surface (phasing.md L78–92): "shell-pipeline splitter, canonical cumulative diff helper, path-filter exfil surface in the Codex review dispatch wrapper, unified dispatch-routing config schema, validation table cross-linking, top-level fail-loud invariant for the dispatch-routing section (G25), per-H4 prose redundancy consolidation..., and the Goals skill's Codex-availability helper." Slice 1.4 goals are **G3, G4, G16, G22, G23, G24 (F02, F04), G25, G27**.

T11's now-relabeled work — `G3 dispatch-manifest provenance fields in .dispatch-manifest.json` — is a CD-1 dispatch-infrastructure deliverable (Slice 1.4 surface), not verifier-rubric-or-instrumentation work (Slice 1.2 surface). The round-02 surgery relabeled T11 from `[G29]` to `[G3]` (per round-context: "T11 RE-LABELED from `[G29]` to `[G3]` (CD-1 dispatch-manifest provenance, full body rewrite)") but kept T11 in its original Slice 1.2 numbered position for task-number stability, without moving it to Slice 1.4 or annotating the mismatch.

The plan's own Dependency Graph item 4 (L106) confirms T11 is dispatch work, grouping it with T09 / T13 / T20 as the dispatch-surface pre-rename chain. T11's body Overview (L687–689) opens with "CD-1's universal dispatch architecture needs the `.dispatch-manifest.json` schema extended with resolved per-dispatch provenance" — pure Slice 1.4 framing.

**Why this matters.**

1. A maintainer reading "Task List by Slice" sees a [G3] task sitting under "Slice 1.2 — Verifier rubric calibration + instrumentation" and reasonably concludes either (a) the slice grouping is incoherent, (b) the task is mis-labeled, or (c) some hidden coupling between G3 and verifier rubric exists. None of these is true; the actual cause (round-02 relabel preserved numbering at the cost of slice coherence) is captured nowhere in the plan body.

2. The plan overview's "all 35 goals decomposed across seven vertical slices" claim implies a clean goal-to-slice mapping. With T11 in Slice 1.2 but its goal in Slice 1.4 per phasing, the mapping is not clean.

3. The Plan-quality "Phase alignment" check expects task slice/phase assignments to match phasing.md's slice definitions. This one violates that alignment without justification.

**Suggested fix (pick one).**

**Option A (preferred — move task):** Renumber the Slice 1.2 list to T08/T09/T10 only, and move T11's entry into the Slice 1.4 task list (immediately before T16, or wherever its dependency ordering with T09 places it cleanly). Update any "Task 11" cross-references in dep-graph item 4 and in T20's `Dependencies:` line (L1171) to track the new number — or keep T11's number and only move the *display position* between slices, leaving the number stable.

**Option B (minimal — annotate in place):** Keep T11 numerically in Slice 1.2, but add a one-line note under the Slice 1.2 heading or after T11's bullet that records the divergence, e.g.:

> *(Task 11's goal is [G3] dispatch-manifest provenance, which is Slice 1.4 surface per phasing.md. The task remains parked under Slice 1.2 by number for cross-reference stability after the round-02 relabel of T11 from `[G29]` (absorbed by CD-1) to `[G3]`; its dependency ordering with T09 also keeps the dispatch-surface pre-rename chain tight.)*

Option A produces the cleanest reader experience; Option B is the smaller diff. Either resolves the silent slice/goal mismatch.

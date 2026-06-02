---
finding_id: R9-F01
severity: low
change_type: clarity
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/plan.md L688, L699-L709, L711-L717, L719-L724, L726-L733
---

**T11 target-file `skills/using-qrspi/SKILL.md (modify)` has no corresponding Scope/DoD/Test-Expectation/Reference and is contradicted by Scope > Out.**

The Task 11 spec (G3 dispatch-manifest provenance fields) declares three target files on L688:

> **Target files:** skills/using-qrspi/SKILL.md (modify), scripts/run-codex-review.sh (modify), tests/acceptance/v07-phase1/test-phase1-acceptance.bats (modify)

For the other two listed target files, the spec carries matching authoring detail (`scripts/run-codex-review.sh` is named in DoD L713-L716 and the structure.md reference on L731; `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` is named in DoD L717, Test Expectation L724, and structure.md reference on L732). For `skills/using-qrspi/SKILL.md`, the spec contains **zero** corresponding edit instructions:

- Scope > In (L699-L703) — all four bullets describe `.dispatch-manifest.json` schema persistence inside the dispatch script; none mention `skills/using-qrspi/SKILL.md`.
- Definition of done (L711-L717) — five bullets, none reference `skills/using-qrspi/SKILL.md` or its prose surface.
- Test expectations (L719-L724) — four bullets, none reference `skills/using-qrspi/SKILL.md`.
- References (L726-L733) — six references; none cite a structure.md block for `skills/using-qrspi/SKILL.md` under T11/G3.

Worse, Scope > Out (L709) **explicitly excludes** the most plausible candidate edit:

> Adding cleanup or regression-prevention prose to `skills/using-qrspi/SKILL.md` for the absorbed G29 surface — explicit non-goal per design.md ## G29 ("no separate v0.7.2 task ships under the G29 ID").

So the Target files list and the Scope contract directly contradict each other for this third file: the file is named as an in-scope edit target, but the spec body forbids the only obvious reason to edit it and supplies no alternative reason.

Likely cause: round-02 repurposed T11 from G29 to G3 (CD-1 dispatch-manifest provenance) (per overview L17 and L56 note). The G29-era target list almost certainly listed `skills/using-qrspi/SKILL.md` for G29 cleanup/regression-prevention prose; when the scope was absorbed and only the CD-1 schema work remained, the target-file entry should have been removed alongside the Scope > Out exclusion that was added.

Operational impact: an implementer reading T11 cannot determine what to do in `skills/using-qrspi/SKILL.md` — there is no edit specified — but the target-file declaration suggests an edit is expected. The implementer will either (a) leave the file untouched (creating a target-file/diff mismatch under any reviewer audit that compares declared targets against actual diff), or (b) invent an edit that the spec has explicitly disclaimed.

Suggested fix: drop `skills/using-qrspi/SKILL.md (modify)` from T11's Target files line so the declared target set is the two files actually scoped (`scripts/run-codex-review.sh` and `tests/acceptance/v07-phase1/test-phase1-acceptance.bats`). The Scope > Out exclusion on L709 already documents the deliberate non-edit, so it can stay as-is for traceability of the round-02 absorption decision.

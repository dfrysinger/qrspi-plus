---
finding_id: R1-F05
severity: low
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L60-L62, docs/qrspi/2026-05-17-v07-release/structure.md:L63-L74]
artifact: plan
round: 1
reviewer: quality-claude
---

The task-ordering summary at plan.md lines 51-52 states: "Slice 4 depends on Slice 2's helper (T13)." In the task list, T22 and T23 are listed as the G14 consumer migration tasks in Slice 4 and both depend on T13. However, the summary at lines 51-52 also states: "Slice 3 lands before Slice 4 (parallelize hygiene + G14 consumer migration) because the shared BATS helper `tests/helpers/skill-markdown.bash` ships in Slice 2 and the CI workflow in Slice 3 must execute the new pins introduced by every later slice."

This contains a subtle misattribution: the text says the CI workflow in Slice 3 "must execute the new pins introduced by every later slice." But the Slice 3 CI workflow is a static `.github/workflows/ci.yml` file that runs BATS against whatever is present in the repo at that time. The workflow does not inherently "execute pins introduced by later slices" — it executes pins that exist when those later tasks land. The cross-slice dependency is that the Slice 4 pins WILL run under the Slice 3 CI workflow once they are committed, not that the CI workflow depends on the pins being authored first.

The concrete dependency ordering stated is still correct (Slice 3 before Slice 4 for the CI reason), but the rationale is imprecise: it conflates the "CI workflow must exist before it can validate pins" relationship with "CI must execute later pins." A reader who takes the stated reason literally might conclude there is a test-visibility dependency that does not actually exist at the file level (T14 has no `depends on: T22` edge, nor should it). This does not affect any task's dependency declaration but may mislead an implementer reasoning about cross-slice ordering.

Resolution: rewrite the cross-slice rationale in the ordering note to state the actual dependency direction more precisely: "Slice 3 lands before Slice 4 because the CI workflow introduced by T14 must exist before the new Slice 4 BATS pins it will execute can be committed to the feature branch and validated."

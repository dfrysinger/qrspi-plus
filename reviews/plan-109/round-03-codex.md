1. `finding_id`: `R3-F01`
   `severity`: `high`
   `change_type`: `correctness`
   `message`: `The plan never schedules the run-init/config-template changes needed to make fresh runs actually start with \`verifier_enabled: true\`, even though spec §1 makes that a runtime contract, not just documentation. Task 3 only documents the field, and Task 5 only adds Apply-fix read/backfill behavior. As written, a new run created after #109 could still omit the field and rely on backfill later, which is weaker than the spec and changes the on-disk contract for fresh runs. Add an explicit commit-4 task (and verification) to update the config-writing instructions/templates used when Goals creates \`config.md\` so new runs persist \`verifier_enabled: true\` immediately.`
   `referenced_files`: `["docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md", "skills/goals/SKILL.md", "skills/using-qrspi/SKILL.md"]`

2. `finding_id`: `R3-F02`
   `severity`: `high`
   `change_type`: `correctness`
   `message`: `Task 5 step 15 does not actually guarantee the “real review round” smoke runs the spec requires for cases (a)–(d). Each case copies an already-populated bundle, leaves the operative \`/qrspi resume ...\` command as a comment instead of an executable step, and then asserts against whatever round files already exist in the copied directory. That can pass on stale pre-cutover artifacts without exercising the new dispatch/tag/splitter/verifier flow at all. Replace these commented commands with concrete executable steps that create a fresh new round and assert against that new round’s outputs, or the smoke gate is not trustworthy.`
   `referenced_files`: `["docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md"]`

3. `finding_id`: `R3-F03`
   `severity`: `high`
   `change_type`: `scope`
   `message`: `The plan explicitly narrows spec §7’s 7-case smoke matrix by marking cases (e)/(f)/(g) as “PASS-via-unit” instead of real review rounds. The spec is stricter: it says “run a real review round per behavior class; all must pass before merging step 4,” and it names malformed-splitter, VERIFY_FAILED→skip, and VERIFY_FAILED→retry as smoke cases. Replacing those with unit-test equivalence changes the acceptance criteria and would let commit 4 merge without end-to-end evidence for three load-bearing failure paths. Either restore real executable smoke steps for those cases or amend the spec first; the plan cannot unilaterally weaken that gate.`
   `referenced_files`: `["docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md"]`

4. `finding_id`: `R3-F04`
   `severity`: `medium`
   `change_type`: `correctness`
   `message`: `Task 4 weakens the rollback topology contract by inventing an exception that commit 3 may modify \`skills/using-qrspi/SKILL.md\` while still calling steps 1–3 “purely additive.” Spec §7 is more rigid: pre-cutover commits are “purely additive,” and the rollback contract says steps 1–3 are individually revertible on that basis. If commit 3 is intentionally allowed to be the lone non-additive doc edit, that needs to be reconciled in the spec; as written, the plan contradicts the source-of-truth migration contract and could mislead the implementer about what commit shapes are permitted before the atomic cutover.`
   `referenced_files`: `["docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md", "skills/using-qrspi/SKILL.md"]`

5. `finding_id`: `R3-F05`
   `severity`: `medium`
   `change_type`: `completeness`
   `message`: `The cutover tasks require all 8 dispatching skills to replace the legacy \`output:\` single-file path with \`<round_subdir>\` and to pass the new role-distinct \`reviewer_tag\` values, but the verification steps do not pin those contracts comprehensively. The added tests grep for Codex prompt markers and splitter wiring, yet they do not assert that the Claude dispatch blocks stopped passing \`output:\`, that \`<round_subdir>\` is now supplied everywhere, or that the role-distinct tags are used in both Claude and Codex dispatch parameters. An implementer could leave parts of the legacy dispatch contract in place and still satisfy the proposed tests. Add explicit structural assertions for those parameter changes across all 8 skills.`
   `referenced_files`: `["docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md", "skills/goals/SKILL.md", "skills/questions/SKILL.md", "skills/research/SKILL.md", "skills/design/SKILL.md", "skills/phasing/SKILL.md", "skills/structure/SKILL.md", "skills/parallelize/SKILL.md", "skills/replan/SKILL.md"]`
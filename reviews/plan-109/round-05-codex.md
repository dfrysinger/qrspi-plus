1. `finding_id`: `R5-F01`
   `severity`: `high`
   `change_type`: `correctness`
   `message`: `Task 5 step 15 rewrites spec §7’s pre-merge gate: instead of seven real smoke rounds, it explicitly allows cases (e)/(f)/(g) to pass via unit-test equivalence and even files a second follow-up issue to defer true end-to-end coverage. The spec is stricter here: commit 4 may merge only after all seven behavior classes are exercised as real review rounds. Shipping from this plan would therefore violate the source-of-truth gate and could hide orchestration bugs that only appear in live reviewer/verifier dispatch. Fix by keeping cases (e)/(f)/(g) as real smoke runs in commit 4, or revise the design spec first; the plan should not authorize a weaker gate on its own.`
   `referenced_files`: `["docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md", "docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md"]`

2. `finding_id`: `R5-F02`
   `severity`: `high`
   `change_type`: `correctness`
   `message`: `Task 5 step 2 changes the verifier prompt contract in ways the spec does not permit. The spec defines <diff_file_path> as `reviews/{step}/round-NN.diff` for round 2+ and the empty string on round 1, but the plan tells the implementer to pass `reviews/{step}/round-(NN-1)-fixes.md` and to omit the parameter on round 1. It also changes <upstream_paths> from the spec’s newline-separated upstream-artifact + SKILL paths to a bracketed list of artifact paths, dropping the SKILL-path part entirely. An implementer following this plan would wire the verifier against the wrong inputs and could break both false-positive checks and traceability to upstream instructions. Fix by copying the spec §1 input contract verbatim into the plan’s dispatch step.`
   `referenced_files`: `["docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md", "docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md"]`

3. `finding_id`: `R5-F03`
   `severity`: `medium`
   `change_type`: `scope`
   `message`: `Task 0 requires filing a second “smoke-matrix end-to-end coverage” follow-up issue before any code commits. The design spec authorizes a single follow-up issue in §7 step 0: the deferred-reviewer migration that later collapses the bifurcated reviewer-protocol contract. Adding a second mandatory tracker is extra repo/process work not grounded in the spec, and it exists only to justify the plan’s smoke-matrix narrowing. That makes the execution scope larger and muddier than the converged design. Fix by removing the extra follow-up issue from the plan unless the spec is updated to require it.`
   `referenced_files`: `["docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md", "docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md"]`
1. `finding_id`: `R7-F01`
   `severity`: `high`
   `change_type`: `correctness`
   `message`: `Task 5 step 15 deliberately downgrades smoke-matrix cases (e)/(f)/(g) from real review rounds to "PASS-via-unit", but spec §7 makes the step-4 gate stricter: all seven behavior classes must be exercised as real rounds before the cutover commit is mergeable. A follow-up issue cannot relax that gate without changing the spec. As written, this plan would let an implementer ship commit 4 without satisfying the source-of-truth verification contract. Fix by either restoring real end-to-end executions for cases (e)/(f)/(g) in this plan or updating the spec first and then pointing the plan at the amended gate.`
   `referenced_files`: `["docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md","docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md"]`

2. `finding_id`: `R7-F02`
   `severity`: `medium`
   `change_type`: `correctness`
   `message`: `Task 5 step 5 says the scope-side tags "do NOT change names" because they were "already role-distinct", but the live dispatch skills still pass `reviewer_tag: claude` / `reviewer_tag: codex` to scope reviewers and rely on the output filename for disambiguation. After the cutover, that filename-based distinction disappears because all reviewers write into the same `round-NN/` directory, so leaving the scope dispatch params unchanged would misroute or collide exactly where the spec says the role-distinct rename is load-bearing. Fix the plan text to require an explicit `reviewer_tag` rename to `scope-claude` / `scope-codex` in every scope-reviewer dispatch, not just the quality-side rename.`
   `referenced_files`: `["docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md","skills/goals/SKILL.md","skills/design/SKILL.md","skills/phasing/SKILL.md","skills/structure/SKILL.md","skills/parallelize/SKILL.md","skills/replan/SKILL.md"]`

3. `finding_id`: `R7-F03`
   `severity`: `high`
   `change_type`: `completeness`
   `message`: `The plan creates `round-schema-violations/` fixtures twice and adds prose-grep checks for malformed YAML, missing required fields, bad `change_type`, unrouted tags, and trailing-newline normalization, but it never adds an executable test that actually runs the step-2 schema guard against those fixtures. Spec §5 test #10 says negative fixtures assert the failure path; prose greps only prove the contract is described, not that the runtime/parser behavior exists. An implementer following this plan could ship the cutover with those guard branches unimplemented or broken while all planned tests still pass. Fix by adding a concrete fixture-backed runtime test for each schema-guard branch, or remove the fixture inventory and explicitly narrow the spec first.`
   `referenced_files`: `["docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md","docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md","tests/unit/test-verifier-dispatch-contract.bats","tests/unit/test-clean-sentinel-and-schema-guard.bats"]`

4. `finding_id`: `R7-F04`
   `severity`: `medium`
   `change_type`: `scope`
   `message`: `Task 5 step 3 extends `round-NN-verifier-disabled.md` with an `abnormality_class` field even though spec §3 defines that audit file as only `timestamp + reason + finding count`. The plan even calls out that this field is "added by the plan", which is precisely the problem: it introduces a new persisted contract the spec did not authorize. That creates avoidable drift for downstream tooling and reviewers. Fix by removing `abnormality_class` from the plan, or update the spec first and then keep the field as a traced requirement.`
   `referenced_files`: `["docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md","docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md"]`

5. `finding_id`: `R7-F05`
   `severity`: `low`
   `change_type`: `clarity`
   `message`: `Task 4 step 1's rollback check is internally inconsistent: it tells the implementer to expect `git show --stat --format=` output where "every line ... starts with `create mode`", but `--stat` emits diffstat summaries, not `create mode` lines. The step later switches to `--name-status`, which is the command that can actually support the additive-only assertion. This is a plan-quality defect because it gives the implementer a false observable for a load-bearing rollback gate. Fix by deleting the incorrect `--stat` expectation and using only one precise verification command/output shape for the additive check.`
   `referenced_files`: `["docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md"]`

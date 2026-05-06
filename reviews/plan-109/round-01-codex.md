1. `finding_id`: `R1-F01`
   `severity`: `medium`
   `change_type`: `correctness`
   `message`: `Task 5 step 8 says it is pinning the spec’s “Read round-NN-verified.md exactly once” contract, but the actual assertion only checks count >= 1. That would let an implementation read the verified file multiple times and still pass, which weakens a load-bearing cache-control contract from spec §1/§5. Change the test to fail unless the count is exactly 1.`
   `referenced_files`: `["docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md","docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md"]`

2. `finding_id`: `R1-F02`
   `severity`: `medium`
   `change_type`: `scope`
   `message`: `The plan declares `tests/fixtures/issue-109/menu-cases/` in the file inventory and says it is used by test #5, but no task ever creates those fixtures and `test-failure-menu.bats` never consumes them. That leaves spec §5 test #5 partially unimplemented and will mislead an implementer about what artifacts are required. Either add a concrete fixture-creation step plus test usage, or remove the fixture directory from the plan and explicitly narrow the test.`
   `referenced_files`: `["docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md","docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md"]`

3. `finding_id`: `R1-F03`
   `severity`: `medium`
   `change_type`: `correctness`
   `message`: `Spec §5 test #3 requires an assertion that the splitter is NOT invoked when `scripts/codex-companion-bg.sh await` exits non-zero, but the plan never adds that check. The narrowed splitter test in Task 2 omits it, and the cutover expansion in Task 5 only checks malformed/stdout-contract cases. That gap could let the runtime violate the failure topology in spec §1 while the test suite still passes. Add an explicit post-cutover test that inspects the dispatch-site shell logic for the “await non-zero => no splitter call, zero files for tag” branch.`
   `referenced_files`: `["docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md","docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md"]`

4. `finding_id`: `R1-F04`
   `severity`: `medium`
   `change_type`: `traceability`
   `message`: `Task 5 step 10 says the verified-file-shape test “extracts the snippet from skills/using-qrspi/SKILL.md and runs it against a fixture round dir,” but the helper shown there re-implements the assembly logic inline instead of extracting anything from the documented protocol. That makes the test capable of passing even if the SKILL.md snippet drifts from the tested behavior, which defeats the spec-to-test traceability this step is supposed to provide. Fix by either actually extracting/sourcing the documented assembly block or rewriting the step description to admit it is a mirrored fixture test and adding a separate assertion that the SKILL.md snippet still matches the mirrored logic.`
   `referenced_files`: `["docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md","docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md"]`

5. `finding_id`: `R1-F05`
   `severity`: `medium`
   `change_type`: `clarity`
   `message`: `The largest runtime edits are still described as “replace with the spec’s 10-step sequence verbatim” and “body sourced verbatim from spec §1” rather than being shown in-plan as a precise diff or pasted section. For a load-bearing atomic cutover, that leaves too much reconstruction work to the implementer and increases the chance of subtle drift on exact strings and control-flow details such as the backfill warning text, header-field semantics, and schema-guard wording. Inline the exact replacement block for `skills/using-qrspi/SKILL.md` and the exact new `reviewer-protocol` section text, or provide a precise unified diff.`
   `referenced_files`: `["docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md","docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md"]`

6. `finding_id`: `R1-F06`
   `severity`: `low`
   `change_type`: `clarity`
   `message`: `Task 1 step 4 says the new verifier-agent bats file should produce 7 passing tests, but the file shown in step 3 contains 8 `@test` blocks. That is a small mismatch, but it will confuse an implementer using the plan as an execution checklist. Update the expected count to 8 or remove one test from the file body.`
   `referenced_files`: `["docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md"]`
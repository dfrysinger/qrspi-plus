1. `finding_id`: `R2-F01`
   `severity`: `high`
   `change_type`: `scope`
   `message`: `Task 5's smoke case (e) quietly expands the implementation beyond the spec by introducing a new \`QRSPI_CODEX_STDOUT_OVERRIDE\` hook in \`scripts/codex-companion-bg.sh\` "if no such hook exists yet". Spec §1 says \`codex-companion-bg.sh await\` is unchanged and the cutover file list for commit 4 does not include this wrapper, and Step 17 does not stage that file either. As written, an implementer either ships an unstaged/out-of-scope wrapper change or cannot execute the prescribed smoke test. Remove the new hook from the plan, or explicitly amend the cutover scope, staged file list, and tests to include the wrapper change.`
   `referenced_files`: `["docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md", "docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md", "scripts/codex-companion-bg.sh"]`

2. `finding_id`: `R2-F02`
   `severity`: `high`
   `change_type`: `correctness`
   `message`: `Task 5 weakens two load-bearing spec tests into prose greps. Spec §5 test #9 requires a fixture-backed mixed-\`change_type\` routing assertion, and test #10 requires negative fixtures for the "expected tag with zero finding/clean files" failure path. The plan's \`test-change-type-partition.bats\` and \`test-clean-sentinel-and-schema-guard.bats\` only grep documentation text, so an implementer could satisfy the plan without ever exercising the actual routing/failure behavior the spec requires. Add concrete fixtures and assertions for both tests, or explicitly point those tests at an executable harness that enforces the same behavior.`
   `referenced_files`: `["docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md", "docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md"]`

3. `finding_id`: `R2-F03`
   `severity`: `high`
   `change_type`: `correctness`
   `message`: `Task 5 Step 4 rewrites the reviewer-agent contract to say the schema guard catches "expected tag produced no output for some F-numbers" after partial writes. That is not the spec contract. Spec §1 explicitly says partial-write failures are accepted as-is and only the all-or-nothing "expected tag produced no output" case is caught by file presence. This new wording would mislead an implementer into adding gap-detection logic or treating missing intermediate F-numbers as a required failure mode. Replace that sentence with the spec's actual behavior: no special signaling for partial writes, and only zero-output-for-tag is guaranteed to trigger the menu.`
   `referenced_files`: `["docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md", "docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md"]`

4. `finding_id`: `R2-F04`
   `severity`: `medium`
   `change_type`: `correctness`
   `message`: `The concrete splitter implementation in Task 2 does not match the stated \`NO_FINDINGS\` contract. \`content=$(<"$stdout_path")\` uses command substitution, which strips all trailing newlines before the explicit trim runs, so input like \`NO_FINDINGS\\n\\n\` is accepted even though the plan says only a single trailing newline may be ignored. If the plan intends the spec's literal-sentinel behavior, rewrite the sample implementation to preserve bytes while checking for exactly \`NO_FINDINGS\` or \`NO_FINDINGS\\n\`.`
   `referenced_files`: `["docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md", "docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md"]`

5. `finding_id`: `R2-F05`
   `severity`: `medium`
   `change_type`: `correctness`
   `message`: `The concrete splitter code in Task 2 silently truncates reviewer output at 99 findings. It writes temp files as \`seg-%02d\` but later only iterates \`"$tmpdir"/seg-??\`, so \`seg-100\` and above are skipped. Spec §1 and the \`^R\\d+-F\\d+$\` finding-id form do not cap the number of findings, so this implementation detail is incorrect and would be easy for an implementer to copy verbatim. Change the temp-file naming/loop so it handles arbitrary finding counts.`
   `referenced_files`: `["docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md", "docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md"]`

6. `finding_id`: `R2-F06`
   `severity`: `medium`
   `change_type`: `clarity`
   `message`: `The smoke-matrix recipes for cases (f) and (g) do not provide a deterministic way to force a verifier \`VERIFY_FAILED\`. The suggested \`sed 's/^score: .../\u2026/'\` rewrite only edits markdown example text inside \`agents/qrspi-finding-verifier.md\`; it does not actually instruct the runtime verifier to unconditionally emit the failure form. An implementer following this literally could spend time debugging a flaky smoke test rather than the feature. Replace it with an explicit failure-injection mechanism that the verifier will definitely obey, or describe a reproducible manual edit that truly changes the Procedure section's runtime instructions.`
   `referenced_files`: `["docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md", "agents/qrspi-finding-verifier.md"]`

7. `finding_id`: `R2-F07`
   `severity`: `medium`
   `change_type`: `intent`
   `message`: `Task 5 dilutes the spec's pre-merge verification gate by allowing cases (e)/(f)/(g) to fall back to unit tests "if either path is unavailable". Spec §7 is stricter: those seven cases are a real-review-round smoke matrix that MUST pass before the cutover merges. Allowing substitution changes the acceptance criterion and could let the atomic cutover ship without ever exercising the runtime failure-menu paths end to end. If fallback is truly intended, the spec needs to say so; otherwise the plan should keep the smoke matrix mandatory and remove the substitution escape hatch.`
   `referenced_files`: `["docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md", "docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md"]`
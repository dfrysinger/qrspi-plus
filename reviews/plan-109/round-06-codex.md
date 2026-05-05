1. `finding_id`: `R6-F01`
   `severity`: `high`
   `change_type`: `correctness`
   `message`: `Task 5 step 15 rewrites spec §7’s smoke gate instead of translating it: the spec requires “a real review round per behavior class” for all 7 cases, but the plan explicitly downgrades cases (e)/(f)/(g) to “PASS-via-unit” and even files a follow-up issue to justify the narrowing. That violates the source-of-truth migration gate, and an implementer following the plan would ship without performing the required end-to-end checks. Fix by restoring real-round execution for cases (e)/(f)/(g), or by first updating the design spec so the narrowed gate is authorized before the plan relies on it.`
   `referenced_files`: `["docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md","docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md"]`

2. `finding_id`: `R6-F02`
   `severity`: `high`
   `change_type`: `correctness`
   `message`: `The verify-failed fixture in Task 5 step 9 uses the wrong sidecar schema: it writes ``score: VERIFY_FAILED:upstream-not-readable`` as a single scalar, but spec §1 requires the failure sidecar to remain two-field YAML (`score: VERIFY_FAILED` plus `reason: <sentence>`). This would pin the wrong file contract in the test suite and could push the implementation away from the spec’s documented parser shape. Fix the fixture and any matching test language to use the exact two-line YAML form from the spec.`
   `referenced_files`: `["docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md","docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md"]`

3. `finding_id`: `R6-F03`
   `severity`: `medium`
   `change_type`: `correctness`
   `message`: `The plan’s shell commands are hardcoded to `/Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus`, but the live checkout in this repo session resolves elsewhere. Because many steps invoke `git`, `bats`, `sed`, and `gh` against that literal path, an implementer with zero context can end up running commands against a nonexistent or wrong tree even though the repo itself is present. Fix by rewriting the command blocks to derive the repo root once (`git rev-parse --show-toplevel`) and use that variable consistently, rather than documenting a path override that dozens of later commands still paste literally.`
   `referenced_files`: `["docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md"]`

4. `finding_id`: `R6-F04`
   `severity`: `medium`
   `change_type`: `correctness`
   `message`: `Task 5 step 16 promises to exclude the plan/spec/audit files from `${FOLLOWUP_ISSUE}` substitution, but the concrete `grep --exclude='*/docs/...` commands are path-shaped excludes that GNU/BSD `grep` do not interpret the way this step assumes. In practice, that makes it plausible for the substitution sweep to rewrite the plan/spec themselves or miss the intended exclusions, which is exactly the audit-corruption hazard the step says it is preventing. Fix by switching to a file enumerator with real path filtering (`find ... -not -path ...`, or `rg -l` with glob filters) and keep the exclusion contract executable rather than aspirational.`
   `referenced_files`: `["docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md"]`

5. `finding_id`: `R6-F05`
   `severity`: `high`
   `change_type`: `completeness`
   `message`: `The step-2 schema guard is underspecified in the plan relative to spec §1. The spec says the guard must fail loud on malformed YAML, missing required fields, malformed `change_type`, and unrouted `(step, tag)` pairs, while normalizing trailing-newline malformations with an audit warning. The plan mostly tests only the “expected tag produced no output” branch, plus a prose grep for out-of-enum `change_type`; it never assigns fixture-backed work for malformed YAML, missing fields, unrouted tags, or newline normalization. An implementer could therefore satisfy the plan while omitting several load-bearing guard branches. Fix by adding explicit cutover steps and negative fixtures that exercise each schema-guard failure/normalization path called out in spec §1 step 2.`
   `referenced_files`: `["docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md","docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md"]`
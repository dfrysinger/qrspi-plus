1. `finding_id`: `R4-F01`
   `severity`: `high`
   `change_type`: `correctness`
   `message`: `Task 5 step 15 changes the spec’s pre-merge gate instead of translating it. Spec §7 requires seven real smoke cases before the atomic cutover can merge, including malformed-splitter, VERIFY_FAILED→skip, and VERIFY_FAILED→retry. The plan explicitly downgrades cases (e)/(f)/(g) to “PASS-via-unit” and files a follow-up to defer them. That violates the load-bearing cutover contract the implementer is supposed to preserve, and it would let commit 4 merge without satisfying the spec’s required verification. Fix by restoring real end-to-end smoke steps for all seven cases, or by first amending the spec; the plan cannot unilaterally narrow the gate.`
   `referenced_files`: `["docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md","docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md"]`

2. `finding_id`: `R4-F02`
   `severity`: `high`
   `change_type`: `correctness`
   `message`: `The smoke-matrix procedure is not executable as written. Task 5 step 15 clones run directories under `/tmp/issue-109-smoke/` and then tells the implementing agent to run `/qrspi resume <step>`, but `using-qrspi` currently discovers resumable runs under `docs/qrspi/*/goals.md` in the workspace. The plan never adds a path override, symlink step, or “run from cloned bundle” mechanism, so the slash-command will not target the `/tmp` bundles the assertions inspect. An implementer with zero context would be unable to run the required smoke cases. Fix by keeping the smoke bundles under the path the skill actually scans, or by adding a concrete temporary override mechanism to the plan.`
   `referenced_files`: `["docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md","skills/using-qrspi/SKILL.md"]`

3. `finding_id`: `R4-F03`
   `severity`: `high`
   `change_type`: `scope`
   `message`: `The plan never gives a concrete task for the verifier dispatch payload, even though spec §1 makes that input contract load-bearing. Task 5 step 2 says to replace Apply-fix with the 10-step sequence, but the spec’s sequence only says “dispatch one `qrspi-finding-verifier` per finding-file” and does not show how to construct or pass `<finding_file_path>`, `<sidecar_path>`, `<artifact_path>`, `<diff_file_path>`, `<upstream_paths>`, or the reviewer tag used in the return shape. That leaves the implementer to invent the core runtime interface for the new agent, which is exactly the kind of untracked guess this review is supposed to prevent. Fix by adding the exact dispatch block or precise diff for `skills/using-qrspi/SKILL.md`, including how each parameter is derived for round 1 vs round 2+, and how upstream paths are assembled.`
   `referenced_files`: `["docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md","docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md","skills/using-qrspi/SKILL.md"]`

4. `finding_id`: `R4-F04`
   `severity`: `medium`
   `change_type`: `correctness`
   `message`: `Task 5 step 11’s new test `fresh-run config init writes verifier_enabled: true to config.md` is broken against the current file shape. Its awk start condition is `/codex_reviews:.*route:|route:.*codex_reviews:/`, which only matches if `codex_reviews:` and `route:` appear on the same line; in `skills/using-qrspi/SKILL.md` they are on separate lines in the config example. As written, the test will never find the intended block unless the implementer changes unrelated formatting to satisfy the heuristic. Fix by anchoring the test to the actual config code fence or a stable section boundary, not to an impossible same-line regex.`
   `referenced_files`: `["docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md","skills/using-qrspi/SKILL.md"]`

5. `finding_id`: `R4-F05`
   `severity`: `medium`
   `change_type`: `correctness`
   `message`: `Task 5 step 9 gives inconsistent fixture paths for `cited-diagnostic.txt`. The prose says to create `tests/fixtures/issue-109/menu-cases/<case>/round-03/` and then lists `cited-diagnostic.txt` alongside the round files, which implies the file lives inside `round-03/`. But the test reads `cat \"${case_dir}cited-diagnostic.txt\"` while iterating `tests/fixtures/issue-109/menu-cases/*/`, so it expects the file one directory higher at `tests/fixtures/issue-109/menu-cases/<case>/cited-diagnostic.txt`. If the implementer follows the creation instructions literally, the test cannot pass. Fix the plan to name one canonical location and align the fixture-creation bullets with the test code.`
   `referenced_files`: `["docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md"]`

6. `finding_id`: `R4-F06`
   `severity`: `medium`
   `change_type`: `clarity`
   `message`: `The plan hardcodes the repo root as `/Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus` throughout the commit and verification commands, but the current workspace resolves elsewhere. That makes many copy-pasted commands fail even before any code-specific work starts, which is a file-path accuracy defect under this review rubric. Fix by using repo-relative commands, `$PWD`, or a single `<REPO_ROOT>` placeholder defined once at the top instead of embedding a stale absolute path in dozens of steps.`
   `referenced_files`: `["docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md"]`
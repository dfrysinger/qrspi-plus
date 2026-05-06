1. `finding_id`: `R1-F01`
   `severity`: `high`
   `change_type`: `correctness`
   `message`: `Task 5 Step 5 (8 dispatching-skill amendments) does not provide the worked one-finding example, the worked zero-findings example, or the no-prose-outside-finding-blocks constraint text verbatim. The plan only paraphrases ("include worked one-finding example…", "the constraint:") and leaves the actual prompt-block text for the implementer to invent. Spec §1 ("Dispatch-site amendments") makes the worked examples a load-bearing part of the Codex prompt contract, and the splitter's malformed-input branch is what catches deviations — meaning subtly different prompt wording across the 8 skills could produce inconsistent reviewer behavior that step 2's schema guard cannot diagnose. Fix: paste the worked one-finding block (a concrete fixture-style example with a real frontmatter + body) and the literal zero-findings line ("NO_FINDINGS\n") into Step 5(c), plus the verbatim constraint sentence; tell the implementer to inject those exact strings into each of the 8 SKILL.md files.`
   `referenced_files`: `["docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md"]`

2. `finding_id`: `R1-F02`
   `severity`: `high`
   `change_type`: `correctness`
   `message`: `Task 5 Step 4 (14 reviewer agent file migrations) does not include the new procedure-step text verbatim or as a precise diff. The plan instructs the implementer to "locate the procedure step that today writes reviews/{step}/round-NN-{reviewer}.md" and "replace it with" a paraphrased per-finding emission contract, clean-sentinel emission rule, and five-line brief-return shape — but does not show the actual replacement paragraph(s). Sub-bullet (c) lists the brief-return field names ("Step / Round / Reviewer / Findings / Written to") without showing the full template (e.g. exact label punctuation, the "Findings: N (high=X, medium=Y, low=Z)" decomposition the legacy contract uses). Two implementers reading this section would produce 14 subtly different agent files, and the reviewer-protocol Per-Finding contract test only asserts presence of substrings, not exact wording. Fix: paste the verbatim replacement block once at the top of Step 4 and reference it by name from each agent-file bullet; show the exact brief-return five-line template.`
   `referenced_files`: `["docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md"]`

3. `finding_id`: `R1-F03`
   `severity`: `medium`
   `change_type`: `correctness`
   `message`: `The fixture path "tests/fixtures/issue-109/menu-cases/" is declared in the File-Structure inventory (plan line 45) and staged in Step 16 (line 1482), but no plan step ever creates it or describes its contents. The corresponding test (test-failure-menu.bats, Task 5 Step 9) does not reference any menu-cases fixture path — it only greps the SKILL.md menu prose. Either the fixture is needed (in which case Step 9 lacks the creation step, and the test lacks the use-fixture assertions spec §5 test #5 requires for "Fixture covers each abnormality the menu handles") or it is dead inventory (in which case it should be removed from the file list and the staging command). Fix: either add a Step 9.5 that creates the four menu-render fixtures (VERIFY_FAILED, missing reviewer Codex output, missing reviewer Claude output, missing sidecar) and extend the bats test to verify the menu prose can render against each, OR strike the fixture path from lines 45 and 1482.`
   `referenced_files`: `["docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md"]`

4. `finding_id`: `R1-F04`
   `severity`: `medium`
   `change_type`: `correctness`
   `message`: `The "${FOLLOWUP_ISSUE}" placeholder appears in three commit-4 artifacts — the Routing Table prose body (Step 1(a)), the test-per-finding-file-emission.bats body comment (Step 7), and the test-clean-sentinel-and-schema-guard.bats embedded in Step 13 (it does not actually appear in the bats body but the surrounding comment does in Step 7) — but the plan only flags substitution as a parenthetical aside ("(Substitute ${FOLLOWUP_ISSUE} with the integer captured…)"). There is no explicit step that performs the substitution before staging, so an implementer following the checklist mechanically could commit the literal string "${FOLLOWUP_ISSUE}" into shipped files. Fix: add an explicit step before Task 5 Step 16 that runs sed (or equivalent) substituting "${FOLLOWUP_ISSUE}" with the contents of /tmp/issue-109-followup-num.txt across the cutover working tree, and a verification grep that no remaining literal "${FOLLOWUP_ISSUE}" survives.`
   `referenced_files`: `["docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md"]`

5. `finding_id`: `R1-F05`
   `severity`: `medium`
   `change_type`: `correctness`
   `message`: `Task 5 Step 2 says "Step 7 (filter and dispatch) handles four routing branches per spec §1" and enumerates: scope/intent → pause; ≥80 keep; <80 drop; out-of-enum → loud failure. This omits the "(or sidecar VERIFY_FAILED OR sidecar absent OR verifier_enabled=false → keep)" branch as a distinct case. Spec §1 step 7 explicitly enumerates four "keep" sub-cases under the style/clarity/correctness branch (≥80, sidecar absent, sidecar VERIFY_FAILED, verifier-disabled). The plan collapses three of those into the second branch's parenthetical ("OR no sidecar OR sidecar VERIFY_FAILED OR verifier_enabled=false") which is correct in substance, but the bats test test-disabled-mode-fallthrough.bats (Step 12) only checks for "no sidecar.*keep" / "sidecar absent.*keep" / "keep-all" — it does NOT assert that VERIFY_FAILED sidecars are kept (only that disabled mode is kept). Fix: extend test-disabled-mode-fallthrough.bats (or test-change-type-partition.bats) to assert that the Apply-fix protocol body explicitly states VERIFY_FAILED sidecars route to keep (not drop), which is a load-bearing semantic the spec §3 retry-skip flow depends on.`
   `referenced_files`: `["docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md"]`

6. `finding_id`: `R1-F06`
   `severity`: `medium`
   `change_type`: `correctness`
   `message`: `The CHANGELOG creation step (Task 6 Step 1) says "If the CHANGELOG file does not exist, create it with the standard QRSPI CHANGELOG header (mirror the format of docs/qrspi/ neighbors)." docs/qrspi/ today contains exactly one entry — "2026-04-29-v0.4-bundle" — which is a directory, not a CHANGELOG file. There is no neighbor format to mirror. The implementer would invent a header, which is exactly the kind of guess the plan should foreclose. Fix: either (a) provide the verbatim CHANGELOG header (e.g. "# QRSPI Changelog\n\nReverse-chronological list of notable changes."), or (b) confirm the file already exists somewhere the plan failed to find, or (c) decide CHANGELOG.md is out of scope and remove this step (spec §7 step 5 calls it "Documentation update" without specifying a format).`
   `referenced_files`: `["docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md", "docs/qrspi/"]`

7. `finding_id`: `R1-F07`
   `severity`: `medium`
   `change_type`: `clarity`
   `message`: `Task 5 Step 3 instructs the implementer to add a "### Verifier-round failure menu" subsection "directly under the Apply-fix protocol you just rewrote in step 2." However, the existing surrounding structure in skills/using-qrspi/SKILL.md uses **bold-paragraph headers** (e.g. "**Apply-fix protocol.**", "**Diff handling between rounds (round 2+).**") inside the H2 "## Review Output Handling" section — there are no H3/### subheaders inside this region. Inserting a "### Verifier-round failure menu" mid-section would produce inconsistent heading levels and could break the Step 9 setup() awk that scans for "/^### Verifier-round failure menu/" if a different real header ("### Fix-altitude rule" appears earlier at line 458 inside a different H2). Fix: either change the header to "**Verifier-round failure menu.**" to match the surrounding bold-paragraph style (and update Step 9's awk pattern), or place the new H3 outside the Review Output Handling H2 boundary so it doesn't dangle.`
   `referenced_files`: `["docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md", "skills/using-qrspi/SKILL.md"]`

8. `finding_id`: `R1-F08`
   `severity`: `medium`
   `change_type`: `correctness`
   `message`: `Task 5 Step 7 (test-per-finding-file-emission.bats) sources its scope-files via shell brace expansion: \`agents/qrspi-{goals,questions,research,design,phasing,structure,parallelize,replan}-reviewer.md\` plus \`agents/qrspi-{goals,design,phasing,structure,parallelize,replan}-scope-reviewer.md\`. This works in bash but bats test files run under bash by default, so it should be fine — but the test then iterates over "scope_files[@]" without quoting in the for-loop pattern, and passes paths into awk reads. If any path fails to expand (e.g. an agent file is renamed by #110), the test prints a misleading "per-finding pattern missing in agents/qrspi-NAME-reviewer.md" error rather than "file not found". This makes failure diagnosis on a stale agent-file inventory ambiguous. Fix: add a "[[ -f $f ]] || { echo \"missing agent file: $f\"; return 1; }" guard at the top of each loop iteration, mirroring the deferred-files guard pattern at line 1028.`
   `referenced_files`: `["docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md"]`

9. `finding_id`: `R1-F09`
   `severity`: `medium`
   `change_type`: `correctness`
   `message`: `The splitter implementation in Task 2 Step 1 uses "content=$(<\"$stdout_path\")" which both is a command substitution (the user's global CLAUDE.md forbids "$()" or backticks for the agent's own bash invocations) AND, more substantively, will fail with a shell error if the file is empty (the assignment is fine but the subsequent "trimmed=${content%$'\\n'}" then tests against "NO_FINDINGS" — that test is fine). The genuine concern: when the awk segment-emitter sees "started" but the very last segment ends without a trailing newline, the post-awk loop's "tail -c1" + appended "\\n" works, but the awk's "if (started) close(f); n++; f=...; started=1; next" logic only closes the previous f when seeing the next boundary — it does NOT close the final f when the file ends. Awk closes file handles on exit, so this is benign in practice, but the splitter-idempotency test relies on byte-identical re-runs. Fix: add an "END { if (started) close(f) }" awk action to make the close explicit and the byte output deterministic across awk implementations (gawk vs BSD awk, which qrspi-plus's CI may run differently than darwin local).`
   `referenced_files`: `["docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md"]`

10. `finding_id`: `R1-F10`
    `severity`: `medium`
    `change_type`: `correctness`
    `message`: `The splitter's NO_FINDINGS branch (Task 2 Step 1) extracts the round number with "round: $(basename \"$round_subdir\" | sed 's/round-//')" inside a heredoc. This assumes the round subdir's basename is exactly "round-NN" (zero-padded NN), but: (a) the test fixture passes "$ROUND_DIR" which is mktemp -d output (e.g. "/tmp/tmp.abc123"), so basename is "tmp.abc123" and the sed yields "tmp.abc123" — yet the test only greps for "ROUND_DIR/${TAG}.clean.md" presence and never validates the round field's value. (b) Real production callers pass "reviews/{step}/round-NN/" so the substitution works. The failure mode is silent: a misconfigured caller writes a clean.md with round: <garbage> and the schema guard at apply-fix step 2 — which according to plan Task 5 Step 2 normalizes trailing-newline malformations but reads YAML — would not catch a non-numeric round. Fix: add an early check in the splitter that the round-subdir basename matches "^round-[0-9]+$" before extracting; or accept the round number as an explicit fourth argument; or update the unit test to verify the round field value matches the extraction rule.`
    `referenced_files`: `["docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md"]`

11. `finding_id`: `R1-F11`
    `severity`: `medium`
    `change_type`: `correctness`
    `message`: `Task 5 Step 15 ("Pre-merge smoke matrix") describes 7 cases that must run as "real review rounds" but provides no concrete fixture artifact, no concrete config.md to start from, and no command to drive a real QRSPI round. Steps say "Set up the run directory with a representative artifact (a small fixture goals.md or design.md is sufficient)" and "Trigger an artifact-level review round and observe the apply-fix protocol's behavior" — these are placeholders, not 2–5-minute atomic actions. Spec §7 step 4 ("the smoke matrix is part of step-4 verification, not a separately-shippable step") makes this matrix the load-bearing pre-merge gate, but the plan does not give the implementer enough detail to actually run any of the 7 cases. Fix: for each case, provide (a) a starting fixture path, (b) the exact /qrspi command sequence to invoke (or the explicit Skill name), (c) the success-criterion regex to match in the resulting round-NN-verified.md or transcript, and (d) the expected /tmp/issue-109-smoke-results.txt line.`
    `referenced_files`: `["docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md"]`

12. `finding_id`: `R1-F12`
    `severity`: `low`
    `change_type`: `correctness`
    `message`: `Final integration Step 2 (line 1689) refers to "#110's PR (#124)". This is a bare assertion — the plan does not say where #124 was determined from, and a quick "gh pr list" today is not in the plan. If the PR number is wrong (a real risk for a fast-moving repo), the implementer might wait on the wrong PR or merge prematurely. Fix: replace "(#124)" with "(track via \`gh pr list --search 'issue-110'\` or check #110's body for the PR link)" so the implementer rederives the correct number at execution time.`
    `referenced_files`: `["docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md"]`

13. `finding_id`: `R1-F13`
    `severity`: `low`
    `change_type`: `clarity`
    `message`: `Task 1 Step 1 instructs the implementer to "cat ~/.claude/plugins/cache/claude-plugins-official/code-review/unknown/commands/code-review.md" and locate the rubric anchor block for verbatim copy. The user's global CLAUDE.md (auto-attached) forbids the agent from running cat as a Bash invocation; the plan should prefer the Read tool here. The path also depends on a plugin cache that may not exist on every workstation. Fix: switch the instruction to "Read ~/.claude/plugins/cache/claude-plugins-official/code-review/unknown/commands/code-review.md" with a fallback note ("if absent, run \`gh repo view anthropics/claude-plugins-official\` or fetch the file from the plugin's GitHub source").`
    `referenced_files`: `["docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md"]`

14. `finding_id`: `R1-F14`
    `severity`: `low`
    `change_type`: `correctness`
    `message`: `Task 4 ("Pre-cutover verification") uses "git revert --no-commit HEAD" + bats + "git reset --hard $HEAD_SHA" to verify each of commits 1–3 is independently revertible. This is destructive: the working tree is mutated during each iteration, and a bats failure mid-iteration leaves the worktree in a reverted state with no commit recovery (the next "git reset --hard $HEAD_SHA" restores it, but only if the reset itself succeeds). If commits 1–3 are clean by construction (purely additive, only-add-files), the revert verification adds risk without commensurate value. Fix: replace the destructive revert pattern with a non-destructive check — confirm commits 1–3 only add new files (no Modify entries) by running "git show --stat <commit> | grep -E '^\\s+create'" and asserting no "modify" lines.`
    `referenced_files`: `["docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md"]`

15. `finding_id`: `R1-F15`
    `severity`: `low`
    `change_type`: `clarity`
    `message`: `Task 5 Step 2 says the runtime-backfill code should "append \`verifier_enabled: true\` to config.md" via "printf '\\nverifier_enabled: true\\n' >> \"$cfg\"". The leading "\\n" guards against the file lacking a trailing newline, but a config.md authored as YAML (the typical shape) does end with a newline, in which case the backfill produces a blank line before the field. This is cosmetic and YAML-parser-tolerant, but the plan should note the carve-out documentation example field-format will not match the post-backfill on-disk shape. Fix: drop the leading \\n (rely on config.md's trailing newline invariant) or add a preflight "tail -c1 \"$cfg\" == \\n" check.`
    `referenced_files`: `["docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md"]`

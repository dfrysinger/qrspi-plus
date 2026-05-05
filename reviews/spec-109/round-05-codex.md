**Contract Drift**

1. `finding_id`: `R5-F01`
   `severity`: `high`
   `change_type`: `correctness`
   `message`: `The rewrite introduces a routing-contract contradiction around reviewer tags. §1 and the routing table say #109 cutover renames artifact-review tags to role-distinct values \`quality-claude|scope-claude|quality-codex|scope-codex\` (spec lines 17-18, 96-109), but the per-finding filename contract still restricts \`<reviewer-tag>\` to \`claude|scope-claude|codex|scope-codex\` (line 73), the Codex splitter examples still write \`codex.finding-F01.md\` / \`scope-codex.finding-F01.md\` (lines 191-205), and the sample file/clean marker still use \`reviewer: claude\` (lines 356-380). If implemented literally, Questions/Research quality Codex and all quality Claude outputs will be emitted under tags the Expected-Reviewer Matrix does not recognize, so step-2 routing/guard logic will misclassify valid files as unrouted or missing. Make every filename example, frontmatter example, and enum reference use the same role-distinct tag set.`
   `referenced_files`: `["docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md"]`

2. `finding_id`: `R5-F02`
   `severity`: `medium`
   `change_type`: `correctness`
   `message`: `The affected-file counts are internally inconsistent, and the wrong count appears in places that drive implementation/tests. The spec says #109 migrates “only the 16 artifact-level reviewers” and gives “the 16 artifact-level reviewers enumerated in §2” as test scope (lines 63 and 446), but §2’s own concrete file list is 14 files: 8 quality reviewers plus 6 scope reviewers because Questions/Research have no scope reviewer (lines 231-235), and §9 step 4 also correctly says 14 migrations (line 498). Inspection of \`agents/qrspi-{goals,questions,research,design,phasing,structure,parallelize,replan}-reviewer.md\` plus \`agents/qrspi-{goals,design,phasing,structure,parallelize,replan}-scope-reviewer.md\` confirms 14 files, not 16. This leaves the migration/test surface ambiguous; fix the counts everywhere before anyone writes the grep-based tests.`
   `referenced_files`: `["docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md","agents/qrspi-goals-reviewer.md","agents/qrspi-questions-reviewer.md","agents/qrspi-research-reviewer.md","agents/qrspi-design-reviewer.md","agents/qrspi-phasing-reviewer.md","agents/qrspi-structure-reviewer.md","agents/qrspi-parallelize-reviewer.md","agents/qrspi-replan-reviewer.md","agents/qrspi-goals-scope-reviewer.md","agents/qrspi-design-scope-reviewer.md","agents/qrspi-phasing-scope-reviewer.md","agents/qrspi-structure-scope-reviewer.md","agents/qrspi-parallelize-scope-reviewer.md","agents/qrspi-replan-scope-reviewer.md"]`

3. `finding_id`: `R5-F03`
   `severity`: `high`
   `change_type`: `correctness`
   `message`: `R1-F02 is still not actually resolved: the migration sequence still claims steps 1-3 are independently shippable, but steps 2 and 3 each depend on cutover-only behavior. Step 2 says to land only the splitter script, with no prompt changes yet (line 492), but test #3 also asserts every #109 Codex prompt already contains the worked one-finding/zero-finding examples and delimiter rules (lines 448-449), which the spec explicitly postpones to step 4 (line 499). Step 3 says \`verifier_enabled\` is documented but “not yet read by any protocol” (line 494), but test #7 asserts the field is already read by every artifact-level Apply-fix invocation (lines 456-457), which again is step-4 behavior. So the pre-cutover commits are still not green in isolation. Either narrow those pre-cutover tests to the additive surface actually landing in that commit, or move the tests into the cutover commit.`
   `referenced_files`: `["docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md"]`

**Codex / Assembly Path**

4. `finding_id`: `R5-F04`
   `severity`: `high`
   `change_type`: `correctness`
   `message`: `R1-F04 is only partially resolved. The spec now makes stdout the canonical Codex source of truth (lines 182-220), but its failure mapping still assumes \`await\` failures are only the non-zero exit cases 10/11/12/13/14 (lines 216 and 398). The current wrapper can also exit 0 while surfacing failure text on stdout via \`storedJob.rendered\`, \`job.errorMessage\`, or \`storedJob.errorMessage\` (scripts/codex-companion-bg.sh lines 578-600; the existing wrapper tests explicitly cover “failed job … exits 0 and surfaces rendered text”). Under this design, those exit-0 failure payloads fall into the splitter’s missing-delimiter fallback and become synthetic \`F00\` findings instead of \`<reviewer-tag>.crash.md\` reviewer-failure records. That changes infrastructure failures into pseudo-findings and corrupts the audit semantics the crash path is supposed to preserve. The design needs an explicit classifier for exit-0 non-review payloads before invoking the splitter.`
   `referenced_files`: `["docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md","scripts/codex-companion-bg.sh","tests/unit/test-codex-companion-bg.bats"]`

5. `finding_id`: `R5-F05`
   `severity`: `high`
   `change_type`: `correctness`
   `message`: `The proposed shell assembly/enumeration commands are not valid for common successful rounds. Step 1 uses \`ls reviews/{step}/round-NN/*.finding-*.md reviews/{step}/round-NN/*.clean.md reviews/{step}/round-NN/*.crash.md\` (line 147), and step 7/dataflow use \`cat reviews/{step}/round-NN/*.finding-*.md *.clean.md *.crash.md\` (lines 150 and 328-331). Two problems: unmatched globs make \`ls\`/\`cat\` fail in normal cases (for example, an all-clean round has no \`*.finding-*.md\`, and a no-crash round has no \`*.crash.md\`), and the latter command only prefixes the first glob with \`reviews/{step}/round-NN/\`, so \`*.clean.md\` and \`*.crash.md\` resolve in the current working directory, not the round directory. As written, valid rounds will fail or assemble the wrong files. The design needs a nullglob-safe enumeration strategy with fully qualified paths for every pattern.`
   `referenced_files`: `["docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md"]`

**Verifier File Shape**

6. `finding_id`: `R5-F06`
   `severity`: `medium`
   `change_type`: `correctness`
   `message`: `R1-F08’s state-machine contradictions are still present in the verifier file-shape section. The contract says the verifier appends a unique HTML sentinel immediately before \`## Verifier\` and the preserve guard hard-fails when that sentinel is missing on a file that was supposed to be verified (lines 78, 154-155, 400-405). But the canonical sample per-finding file omits the sentinel entirely and shows only a bare \`## Verifier\` block (lines 354-370), and the prose immediately below still says missing \`## Verifier\` covers “a verifier that silently failed without returning VERIFY_FAILED” and is kept (line 372), which directly conflicts with step 6’s “missing sentinel on an expected verified file aborts the protocol” rule. If an implementer follows the sample, the preserve guard will reject the output shape the sample told them to generate. Update the sample and the missing-block prose so they match the hard-fail preserve-guard contract.`
   `referenced_files`: `["docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md"]`
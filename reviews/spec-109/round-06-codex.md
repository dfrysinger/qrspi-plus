1. `finding_id`: `R6-F01`

   `severity`: `high`
   `change_type`: `correctness`
   `message`: `The round-5 rewrite turns the ≥80 keep filter into an effective “100 only” gate. §1 claims this faithfully copies /code-review’s “0/25/50/75/100 rubric with the ≥80 threshold” (line 21), but the verifier procedure now requires EXACTLY one discrete bucket and explicitly snaps off-bucket scores down to those buckets, including `87 -> 75` (lines 55-58). Apply-fix then keeps only `score >= 80` for `style|clarity|correctness` findings (line 171). Because 80/90/95 can no longer exist, anything short of `100` is dropped, which is materially stricter than /code-review step 5’s actual “0-100 scale with rubric anchors” contract. That will suppress many real reviewer findings the design says it wants to keep. Fix by either allowing arbitrary 0-100 verifier scores, or by lowering the threshold to match the bucketed scheme and updating the “faithful copy” claim.`
   `referenced_files`: `["docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md","/Users/dfrysinger/.claude/plugins/cache/claude-plugins-official/code-review/unknown/commands/code-review.md"]`

2. `finding_id`: `R6-F02`

   `severity`: `high`
   `change_type`: `correctness`
   `message`: `The new exit-0 failure classifier can misclassify valid Codex findings as crash payloads. §2 says that before splitting stdout, any line containing `errorMessage:` outside YAML frontmatter should be treated as a wrapper failure marker and routed to `<reviewer_tag>.crash.md` (line 229). But the post-#109 Codex contract allows arbitrary prose message bodies after the frontmatter, and a legitimate finding can easily mention or quote `errorMessage:` when reviewing code or logs. In that case a successful review stream is discarded before `scripts/codex-finding-splitter.sh` ever runs. The underlying wrapper behavior in `scripts/codex-companion-bg.sh` only needs classification for its own rendered failure shapes (`storedJob.rendered`, `job.errorMessage`, `storedJob.errorMessage` at lines 578-600); substring-matching arbitrary review prose is too broad. Tighten the classifier to exact wrapper-produced failure forms/prefixes instead of scanning for `errorMessage:` anywhere in the review body.`
   `referenced_files`: `["docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md","scripts/codex-companion-bg.sh"]`

3. `finding_id`: `R6-F03`

   `severity`: `medium`
   `change_type`: `correctness`
   `message`: `R5-F02 is still not fully resolved: the spec still defines two incompatible F00 `finding_id` shapes. The canonical fallback section now says the valid form is `R{NN}-F00-<reviewer_tag>` and documents a regex that accepts that shape (lines 424-428). But §4’s Codex-splitter failure-mode summary still says the missing-delimiter fallback writes `finding_id: R{NN}-<reviewer-tag>-F00` (line 440). Those are different strings, and only one can satisfy the documented schema guard/tests. A developer following §4 will generate files that disagree with the contract in §3. Unify every F00 reference on one shape and keep the regex/test text aligned to that single form.`
   `referenced_files`: `["docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md"]`

4. `finding_id`: `R6-F04`

   `severity`: `medium`
   `change_type`: `correctness`
   `message`: `R5-F06 is not actually closed: the data-flow section still reintroduces the “missing verifier block => keep” behavior that the rewrite claims to eliminate. In §3 step 9, `style|clarity|correctness` findings are described as all-kept when `verifier_enabled=false OR ## Verifier block missing` (lines 357-360). But the normative Apply-fix text says missing verifier output is only legal in two cases: disabled rounds or explicit `VERIFY_FAILED`; otherwise preserve-guard must abort on the missing sentinel/block (lines 167, 392). Those two contracts produce different implementations for the same failure mode. Fix the data-flow section so it matches the step-6/step-7 preserve-guard invariant, or explicitly relax the invariant everywhere if silent keep is actually intended.`
   `referenced_files`: `["docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md"]`
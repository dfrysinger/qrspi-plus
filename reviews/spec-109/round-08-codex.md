1. `finding_id`: `R8-F01`

   `severity`: `high`
   `change_type`: `correctness`
   `message`: `R7-F01 is still not actually resolved, and the rewrite now leaves disabled-mode assembly without a coherent input set. §2 correctly says crash-tag findings must be staged out in step 4 and that step 7 must cat the post-staging arrays (lines 156-165, 174). But §3 still says step 7 uses “the path-qualified arrays from step 1” (lines 372-378), which reintroduces the stale-path bug from R7-F01. On top of that, verifier-disabled rounds skip steps 4-6 entirely (line 157 / lines 306-309), so the crash-staging/re-glob step never runs even though crash precedence at step 2 says those findings must be excluded from assembly (line 156). In disabled mode, a reviewer that emitted both `<tag>.crash.md` and partial finding files will therefore either leak those partial findings into `round-NN-verified.md` or hit an undefined “post-staging arrays” reference. Split crash staging out of the verifier-only path, or make disabled rounds still run the step-4 staging/re-glob half before jumping to assembly. Also fix §3 so it matches the post-staging-array contract.`
   `referenced_files`: `["docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md"]`

2. `finding_id`: `R8-F02`

   `severity`: `medium`
   `change_type`: `correctness`
   `message`: `R7-F03 is still not fully resolved. §2 defines empty Codex stdout as a structured crash file whose first non-blank line is `# @@QRSPI-EMPTY-CODEX-STDOUT@@`, and step 7/test #6 rely on that marker to count `empty-codex` separately from generic `crashed` files (lines 234-245, 174, 536). But §4’s “Codex splitter failure modes” still describes empty input as only “a `<reviewer-tag>.crash.md` with a `## Splitter Note` body” (line 479), with no first-line marker. An implementer following §4 loses the only machine-readable signal the totals-header logic depends on, so `empty-codex` becomes non-deterministic again. Carry the structured first-line marker into §4’s empty-input contract, or drop the separate `empty-codex` counter everywhere.`
   `referenced_files`: `["docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md"]`

3. `finding_id`: `R8-F03`

   `severity`: `medium`
   `change_type`: `correctness`
   `message`: `The `verifier_enabled` start-of-run contract is internally contradictory, and the smoke plan depends on a behavior the spec later says is out of scope. The config section says `verifier_enabled` is “set by the user's /qrspi invocation at run start” (line 194), and §9 step 5 requires a smoke run with `verifier_enabled: false` “from start” (line 593). But §8 then says a pipeline-wide opt-out via CLI flag at run start is out of scope for #109 (line 564). The current `using-qrspi` config-write contract also only creates `created`, `pipeline`, `codex_reviews`, and `route` at run creation today ([skills/using-qrspi/SKILL.md](/Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus/skills/using-qrspi/SKILL.md:375)). As written, the spec both requires and forbids start-time opt-out. Either remove the “from start” path and the corresponding smoke case, or explicitly scope in the Goals/config-write changes needed to let `/qrspi` create `config.md` with `verifier_enabled: false` on day one.`
   `referenced_files`: `["docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md","skills/using-qrspi/SKILL.md"]`
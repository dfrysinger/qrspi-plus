**Routing and Reviewer Topology**

1. `finding_id`: `R4-F01`
   `severity`: `high`
   `change_type`: `correctness`
   `message`: `R1-F02 is still not resolved. The rewrite's selector assumes unique `(step, reviewer_tag)` pairs and even enumerates `scope-claude` / `scope-codex` as active tags (spec lines 96-123, 127-140), but the current dispatchers still pass `reviewer_tag: claude` for both quality and scope Claude reviewers and `reviewer_tag: codex` for both quality and scope Codex reviewers (for example [skills/goals/SKILL.md] lines 228-240 and 247-260; same pattern in [skills/design/SKILL.md] lines 122-132 and 143-151). That means the routing table cannot distinguish migrated quality reviewers from migrated scope reviewers, let alone deferred reviewers that also reuse `claude`/`codex`. As written, Apply-fix step 2 will either false-fail on every scope-reviewed artifact or route the wrong contract branch. Fix by changing the dispatch contract itself in the same cutover so scope reviewers emit distinct tags, or key routing on something actually unique today (agent family/output-path pattern), not the reused `reviewer_tag` field.`
   `referenced_files`: `["docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md","skills/goals/SKILL.md","skills/design/SKILL.md"]`

2. `finding_id`: `R4-F02`
   `severity`: `high`
   `change_type`: `scope`
   `message`: `The rewrite drops Plan-round reviewers that still participate in the same artifact-level Apply-fix loop. The spec says #109 covers Plan, but the Expected-Reviewer Matrix only expects `plan:{claude,scope-claude,codex,scope-codex}` (spec lines 127-140) and the out-of-scope list defers the five plan-artifact reviewer families (spec lines 225-225, 451-457). In the real Plan round, those five Claude reviewers and five Codex reviewers are still dispatched alongside the unified reviewer and scope reviewer ([skills/plan/SKILL.md] lines 234-307). After cutover, step 1 only enumerates `round-NN/` per-finding outputs (spec lines 148-156), while §4 also says legacy single-file presence in a #109-scope round is a fail-loud trigger (spec line 372). So every Plan round either ignores ten live reviewer outputs or hard-fails because they are still legacy files. This is a load-bearing topology mismatch. Either keep Plan entirely out of #109 until all plan reviewers migrate, or migrate the plan-artifact reviewers and include them in the expected-reviewer/source-of-truth tables now.`
   `referenced_files`: `["docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md","skills/plan/SKILL.md"]`

**Codex and File Contracts**

3. `finding_id`: `R4-F03`
   `severity`: `high`
   `change_type`: `correctness`
   `message`: `The missing-delimiter Codex fallback still violates the file contract it is supposed to recover into. The per-finding contract requires frontmatter with `finding_id`, `severity`, `change_type`, `referenced_files`, `artifact`, `round`, and `reviewer`, with findings numbered from `F01` upward (spec lines 73-78). But the fallback writes `<reviewer-tag>.finding-F00.md` with only four fields and no `artifact`, `round`, `reviewer`, or body `message` at all (spec lines 197-203). That means the exact malformed-stdout recovery path produces a malformed per-finding file, so Apply-fix step 2's schema/contract guard has to reject it. Either make the fallback synthesize a fully valid per-finding file, or treat delimiterless Codex stdout as a crash file only instead of inventing a pseudo-finding that does not satisfy the protocol.`
   `referenced_files`: `["docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md","skills/reviewer-protocol/SKILL.md"]`

4. `finding_id`: `R4-F04`
   `severity`: `high`
   `change_type`: `correctness`
   `message`: `The preserve-guard algorithm contradicts itself on whether the original trailing newline is part of the hashed prefix. Apply-fix step 6 says the recovered prefix includes the original trailing newline and must match the step-4 snapshot byte-for-byte (spec lines 151-155). But §4's helper-script contract says `check` splits at the sentinel and hashes everything before it "excluding the trailing newline" (spec lines 382-383). Those two descriptions cannot both be implemented against the same snapshot: step 4 explicitly snapshots the full pre-verify file content ending with that newline. One reading will therefore false-abort a correct verifier write. Pick one byte-level rule and make step 4, step 6, and the helper-script contract say the same thing.`
   `referenced_files`: `["docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md"]`

5. `finding_id`: `R4-F05`
   `severity`: `medium`
   `change_type`: `correctness`
   `message`: `The rewritten test plan now pins behavior that contradicts the runtime contract for empty Codex stdout. The runtime sections say empty stdout is a failure: write `<reviewer-tag>.crash.md` and route to the reviewer-failure pause path (spec lines 205-206 and 377-378). But test #3 says empty input should produce a clean marker with `## Splitter Note` (spec line 428). That makes the suite validate the wrong behavior and will let a broken splitter pass. Align the test with the crash-file contract, or explicitly change the runtime contract if a clean-marker-on-empty path is actually intended.`
   `referenced_files`: `["docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md"]`
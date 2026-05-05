1. `finding_id`: `R7-F01`

   `severity`: `high`
   `change_type`: `correctness`
   `message`: `The crash-staging path is internally broken because step 7 reuses the step-1 file arrays after step 4 has moved some of those files out of the round directory. Step 1 materializes \`findings=( "$D"/*.finding-*.md )\` / \`cleans\` / \`crashes\` (lines 147-154). Step 4 then moves crashed-tag finding files into \`.crash-skipped/\` (line 158). But step 4 and the data-flow both say assembly later uses "the same ... arrays from step 1" (lines 158, 167, 351-357). Those array entries still point at the old paths, so the synthesized crash case in §9 step 5 will either make \`cat\` fail on missing files or force the implementation to diverge from the spec. Rebuild or filter the \`findings\` array after staging, and make step 5/step 7 explicitly operate on the post-staging list instead of the original step-1 arrays.`
   `referenced_files`: `["docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md"]`

2. `finding_id`: `R7-F02`

   `severity`: `medium`
   `change_type`: `correctness`
   `message`: `§2 and §3 still disagree on where verifier snapshots live. The normative Apply-fix step says step 4 writes \`.snapshots.txt\` to disk specifically so the dispatcher can re-read it after \`/compact\` (lines 158-160). The §3 data-flow diagram then describes the same snapshot as "Stored in memory keyed by path" (lines 302-306). Those are not equivalent implementations: the in-memory version reopens the exact compaction/re-entry failure the rewrite claims to close. Make §3 match §2 and say the snapshot map is persisted to \`reviews/{step}/round-NN/.snapshots.txt\`, then re-read from disk at step 6.`
   `referenced_files`: `["docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md"]`

3. `finding_id`: `R7-F03`

   `severity`: `medium`
   `change_type`: `correctness`
   `message`: `The totals header includes an \`empty-codex\` count, but the spec no longer defines any machine-readable artifact that lets assembly compute that number. Empty Codex stdout is normalized into a plain \`<reviewer-tag>.crash.md\` with a free-text note (line 227), and step 7 says the header is injected by \`awk\` while counting \`scored/kept/dropped/failed/clean/crashed/empty-codex/crash-skipped\` (line 167; also reflected in §3 and Test #6 at lines 361-362 and 515). With the current file model, empty-stdout cases are indistinguishable from other crash files unless assembly starts scraping crash-note prose, which the spec never defines as part of the contract. Either drop the \`empty-codex\` header field or add a structured empty-stdout marker that assembly can count deterministically.`
   `referenced_files`: `["docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md"]`
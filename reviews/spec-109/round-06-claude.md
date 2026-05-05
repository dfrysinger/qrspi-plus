# Round 6 review — spec-109 (claude)

Scope: NEW issues introduced by the round-5 rewrite (commit `826ce75`),
or round-5 issues not actually resolved by the rewrite. Round-5 fixes
that landed cleanly (role-distinct `reviewer_tag` rename consistency
across examples/tests/prose, F00 `R{NN}-F00-{tag}` format with
permissive guard regex `^R\d+-F\d+(-[a-z-]+)?$`, sample sentinel
inclusion, `.snapshots.txt` re-entry idempotence, audit-trail
asymmetry doc, smoke matrix synth-crash wording, exit-0 failure-
payload classifier insertion, nullglob-safe shell enumeration with
fully path-qualified patterns, pre-cutover test narrowing) are NOT
re-flagged.

---

1. `finding_id`: `R6-F01`
   `severity`: `high`
   `change_type`: `correctness`
   `message`: `Exit-0 failure-payload classifier markers do not match what scripts/codex-companion-bg.sh actually emits — the round-5 fix is load-bearing on markers that aren't there. §2 line 229 specifies the classifier triggers on stdout whose first non-blank line matches one of: \`^Codex job failed:\`, \`^Codex companion error:\`, or any line containing \`errorMessage:\` outside a YAML frontmatter block. But the wrapper (scripts/codex-companion-bg.sh lines 596-601) extracts \`job.errorMessage\` / \`storedJob.errorMessage\` JSON values and emits them VERBATIM with no \`Codex job failed:\` / \`Codex companion error:\` / \`errorMessage:\` prefix. The existing wrapper bats fixtures confirm this: \`Cancelled by user.\` (test line 426), \`Stored-only error message.\` (line 447), \`Codex turn ended with failure\` (line 406). None of those literal strings exist anywhere in scripts/ or tests/ in the repo (verified by grep). When Codex actually returns an exit-0 failure payload in production, the classifier as specified will not fire — the payload will fall through into the splitter's missing-delimiter F00 fallback (creating a pseudo-finding with \`change_type: intent\`) instead of being routed to \`<reviewer_tag>.crash.md\` as the round-5 fix intended. R5-F04 is therefore not actually resolved. The fix needs to anchor on the wrapper's render.mjs:421-445 source-of-truth set: (a) walk the same JSON-extraction chain the wrapper uses (storedJob.result.rawOutput → storedJob.result.codex.stdout → storedJob.rendered → job.errorMessage → storedJob.errorMessage) and treat content sourced from \`job.errorMessage\`/\`storedJob.errorMessage\` (links d/e) as failure payloads — these are structurally distinguishable in the JSON before the wrapper coalesces them to text — OR (b) extend the wrapper itself in the cutover commit to emit a leading classifier marker (e.g., a \`<<<CODEX-FAILURE>>>\` header line on links d/e) so the stdout-only classifier has something to grep. As written, every exit-0 failure shape produced by the existing wrapper bypasses the classifier; the audit-trail-corruption hazard the round-5 fix was meant to close is still open.`
   `referenced_files`: `["docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md","scripts/codex-companion-bg.sh","tests/unit/test-codex-companion-bg.bats"]`

2. `finding_id`: `R6-F02`
   `severity`: `low`
   `change_type`: `clarity`
   `message`: `Stale "step 14" reference in §3 data-flow contradicts the 12-step Apply-fix protocol. §3 line 392 reads: "The dispatcher in step 14 treats absence of the \`## Verifier\` block as 'keep this finding without scoring'..." But §2's Apply-fix protocol enumerates steps 1-12 (steps 1-12 at lines 147-178) — there is no step 14. The "missing-block → keep" rule actually lives in step 7 (assembly, line 167) and step 9 (filter and dispatch, lines 169-175). The "step 14" wording appears to be left over from a prior numbering. An implementer cross-referencing the data-flow text against the protocol won't find step 14 and won't know which step to read. Fix: rewrite line 392 as "The dispatcher's filter step (§2 step 9) treats absence of the \`## Verifier\` block as 'keep this finding without scoring'..." OR cite both step 7 (assembly preserves the file) and step 9 (filter applies the keep branch).`
   `referenced_files`: `["docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md"]`

3. `finding_id`: `R6-F03`
   `severity`: `low`
   `change_type`: `clarity`
   `message`: `Totals-header field-name drift between §3 data-flow and Test #6 will produce a false-failing test. §3 line 167 lists the assembly totals header fields as "scored/kept/dropped/failed/clean/crashed/empty-codex/crash-skipped" (singular \`scored\`). Test #6 at line 498 asserts the header field set as "verifier_enabled, total_scored, kept, dropped, failed, clean, crashed, empty-codex, crash-skipped" (\`total_scored\`, not \`scored\`). Whichever name the implementer picks, the other location's grep will fail. The verifier-enabled fixture in test #6 ("asserts \`verifier_enabled: true\` row + non-zero \`scored\`") then re-uses the singular \`scored\` form, contradicting the same test's earlier list. Pin one canonical field name (preferably \`scored\` — shorter, matches the disabled-row's \`scored: 0\` wording at §2 line 167) in both §3 and §7 test #6.`
   `referenced_files`: `["docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md"]`

---

Findings: 3 total — 1 high, 0 medium, 2 low.

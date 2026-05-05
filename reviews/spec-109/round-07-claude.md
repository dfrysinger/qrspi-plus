# Round 7 review — spec-109 (claude)

Scope: NEW issues introduced or surfaced by the round-6 rewrite (rubric
restored to continuous 0–100, classifier marker moved into the wrapper,
F00 form unified to `R{NN}-F00-<tag>`, missing-block enumeration,
"step 14"→step 9, `total_scored`→`scored`). Round-6 fixes that landed
cleanly (rubric continuity, marker shape `# @@QRSPI-CODEX-FAILURE@@:
<source>`, F-number-first F00 form across §2/§3/§4, scored field name
unified across §3 and test #6, snapshot disk-backing, `.crash-skipped/`
staging) are NOT re-flagged.

---

1. `finding_id`: `R7-F01`
   `severity`: `high`
   `change_type`: `correctness`
   `message`: `The unspoofability claim for the exit-0 failure-payload classifier cites the wrong stdout shape — the cited shape contradicts the #109 Codex stdout contract. §2 line 238 argues the marker `# @@QRSPI-CODEX-FAILURE@@:` is unspoofable as review content because "the per-finding contract REQUIRES every Codex review payload to start with either `` 1. `finding_id`: ... `` (numbered finding block) or the literal `NO_FINDINGS` sentinel — neither shape can begin with `# @@QRSPI-CODEX-FAILURE@@:`." But the actual post-#109 Codex stdout contract is documented at §2 line 196 ("emit findings ONLY to stdout, with a `<<<FINDING-BOUNDARY>>>` delimiter on its own line BEFORE each finding (including the first)") and reinforced at lines 267–269 ("worked one-finding example showing `<<<FINDING-BOUNDARY>>>` on its own line immediately before the YAML frontmatter `---`" and "Emit only finding blocks (each preceded by `<<<FINDING-BOUNDARY>>>`) or the `NO_FINDINGS` sentinel"). So the actual first non-blank line of any valid Codex review payload is `<<<FINDING-BOUNDARY>>>` (delimiter-prefixed), not `` 1. `finding_id` `` (a numbered-block shape that lives nowhere in the post-#109 prompt-template requirements at lines 266–271). The classifier itself anchors on first non-blank line matching `^# @@QRSPI-CODEX-FAILURE@@:`, which is genuinely safe vs `<<<FINDING-BOUNDARY>>>` and `NO_FINDINGS` — so the classifier is fine, but the spec's *justification* for why it's safe is wrong and will mislead an implementer trying to verify the safety argument or write tests around it. Fix line 238 to assert unspoofability against the actual contract first non-blank lines: `<<<FINDING-BOUNDARY>>>` (for non-empty findings) or `NO_FINDINGS` (zero-findings sentinel) — neither begins with `# @@QRSPI-CODEX-FAILURE@@:`. Also worth adding to test #3 a negative fixture asserting that a payload whose first non-blank line is `<<<FINDING-BOUNDARY>>>` is NOT classified as failure (matches the actual contract) rather than the current `1. \`finding_id\`` shape (which doesn't reflect anything the prompt template requires).`
   `referenced_files`: `["docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md"]`

2. `finding_id`: `R7-F02`
   `severity`: `medium`
   `change_type`: `correctness`
   `message`: `Verifier brief-return shape is inconsistent between §2 and §3, and the discrepancy breaks the orchestrator's ability to map a brief return back to its source file when two reviewers emit the same F-number in the same round. §2 step 8 (line 58) specifies the verifier returns "`<finding_id>: <score>`" with example `R3-F02: 87` (full canonical finding_id including the round prefix). But §3 data-flow line 321 says the verifier returns `"F##: <int 0..100>"` (just the F## fragment, no round prefix, no tag). Pick one: but more importantly, *neither shape* carries `reviewer_tag`, and per §3 line 442 canonical `finding_id` is unique only "per `(round, reviewer_tag)`" — i.e., `quality-claude.finding-F02.md` and `scope-claude.finding-F02.md` can both exist in the same round with both carrying `finding_id: R3-F02`. When the orchestrator at §2 step 6 / §3 step 9 needs to consult brief returns to identify which file's verifier returned `VERIFY_FAILED:`, an `R3-F02: VERIFY_FAILED:...` return is ambiguous between the two files. The dispatcher dispatched one Haiku per FILE PATH (§2 step 5: "Dispatch one `qrspi-finding-verifier` per non-crashed-tag finding-file path in parallel"), so the dispatch-keyed mapping is by path, but the returns are keyed by `finding_id` which is not unique by itself across reviewers. Fix by either: (a) requiring the verifier brief return to include the path or `<reviewer_tag>:<finding_id>` (e.g., `quality-claude:R3-F02: 87`), OR (b) making the orchestrator use positional/path-keyed correlation (the i-th dispatch's i-th return is for the i-th file path), and explicitly documenting that the returned `finding_id` is advisory/audit only. Pin the chosen mechanism in §2 step 8 AND §3 line 321 AND test #4. The case (b) preserve-guard skip rule at line 166 ("dispatcher knows from the verifier's brief return [which files VERIFY_FAILED]... and skips them in the preserve-guard pass") relies on this mapping being unambiguous.`
   `referenced_files`: `["docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md"]`

3. `finding_id`: `R7-F03`
   `severity`: `low`
   `change_type`: `clarity`
   `message`: `Stale step-number reference in §6 cost discipline survived the round-6 step-numbering cleanup. §6 line 495 reads: "Net delta: ~N × 10 tokens (verifier brief returns at step 9). At typical N=8, ~80 tokens." Verifier brief returns are produced at §2 step 5 (the parallel-dispatch step at line 163), not step 9. Step 9 is the change_type partition / filter step (line 169) which does not produce verifier returns. Round-6 fixed the same class of stale-step-numbering issue in §3 (the prior "step 14" → §2 step 9 fix per round-6 R6-F02-claude) but missed §6. Fix line 495 to read "verifier brief returns at step 5" (matching §2 line 163 and §3 lines 307–322, and consistent with §2 step 7's "the dispatcher consults the verifier brief returns captured at step 5" at line 167).`
   `referenced_files`: `["docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md"]`

---

Findings: 3 total — 1 high, 1 medium, 1 low.

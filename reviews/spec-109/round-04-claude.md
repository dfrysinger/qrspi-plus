# Round 4 review — spec-109 (claude)

Scope: NEW issues introduced by the round-3 rewrite (commit `f1fea46`), or
round-3 issues not actually resolved by the rewrite. Round-3 fixes that
landed cleanly (routing-table key pair, Expected-Reviewer Matrix,
verifier_enabled carve-out, missing-block case decomposition,
trailing-newline mandate, unrouted-key fail-loud, snap tie-break,
.crash-skipped/ subdir, option-1 mid-protocol guard, helper-script stderr,
routing-table location, option-2 snapshot reuse, §9 step 0, always-on
footer intent, sentinel-collision fixture realism) are NOT re-flagged.

---

1. finding_id: R4-F01
   severity: high
   change_type: correctness
   referenced_files: [docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md]
   message: Snapshot storage is "in memory" with no /compact survivability
   contract. §2 Apply-fix step 4 (line 151) says: "Store the snapshot in memory
   keyed by file path. The snapshot is the input to the preserve guard at
   step 6." The dispatcher is main chat (Claude); its "memory" is conversation
   transcript. Apply-fix steps 4 → 5 → 6 flow without an explicit `/compact`
   between them, so under nominal conditions the snapshot survives. But
   step 5 dispatches N parallel Haiku verifiers — N = 8–15 typical, each
   with its own subagent context. The orchestrator's transcript can grow
   substantially between step 4 and step 6 (verifier brief returns, parallel
   coordination, stderr from any failures). If main chat hits its compaction
   threshold or a user/auto-`/compact` interleaves between step 4 and step 6
   for any reason, the in-memory snapshot map is lost — and step 6 cannot
   invoke `scripts/verifier-preserve-guard.sh check <path> <sha>` because the
   `<sha>` argument is gone. Helper script's check subcommand requires the
   expected SHA as input (§4 line 383). The spec must either: (a) write the
   snapshot to disk at step 4 (e.g., `reviews/{step}/round-NN/.snapshots.txt`
   with one `<path> <sha>` line per finding file, gitignored or scoped under
   `.crash-skipped/` semantics — see R4-F03), so step 6 reads from disk and
   is `/compact`-resilient; or (b) explicitly forbid `/compact` between
   steps 4 and 6 with a contract that the dispatcher must batch the verifier
   round atomically. Recommend (a) — disk-backed snapshots are durable, the
   helper script can absorb a `--snapshot-file` argument, and the audit trail
   gains the snapshot map for free. Without one of these, the preserve guard
   has a latent flake mode that won't surface until a long-tail verifier run.

2. finding_id: R4-F02
   severity: medium
   change_type: correctness
   referenced_files: [docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md]
   message: `verifier_enabled` backfill has two contradictory paths.
   §2 line 178 says the field's missing-field carve-out is "backfilled on
   first verifier-aware Apply-fix to make the carve-out time-bounded" —
   i.e., RUNTIME backfill, on first-touch by an in-flight resumed run.
   §9 step 4 (line 478, "atomic cutover commit") says: "cutover backfills
   the field into in-flight config.md files." That phrasing reads as a
   COMMIT-TIME backfill — a script run as part of the cutover that walks
   `docs/qrspi/<date>-<bundle>/` directories and writes `verifier_enabled:
   true` into every in-flight `config.md` it finds. The two are not the
   same: commit-time backfill mutates user files outside the repo's
   skills/agents/scripts trees as a side effect of merging the cutover
   commit (surprising and not git-revertible); runtime backfill mutates
   files only when the user resumes a run (clean revert semantics). The
   spec must pick one. Recommend runtime backfill: (i) it's revertible
   (revert step 4 → the runtime carve-out code goes with it → no orphan
   mutations on user disks); (ii) it doesn't require executing scripts
   inside a merge commit (which most CI/PR flows can't do); (iii) the
   "with a one-line stderr warning surfaced once per resume" mechanism
   already implies runtime. Drop the §9 step 4 claim ("cutover backfills
   the field into in-flight config.md files") or rewrite it as "the
   runtime backfill code in `using-qrspi/SKILL.md` is part of this
   commit — actual file mutation happens on resume."

3. finding_id: R4-F03
   severity: medium
   change_type: correctness
   referenced_files: [docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md]
   message: `.crash-skipped/` subdir git semantics are unspecified.
   §2 step 4 (line 151) creates `reviews/{step}/round-NN/.crash-skipped/`
   on demand and moves crashed-tag finding files into it. §2 step 12
   (line 167) says the per-round commit covers the `round-NN/` subdir.
   By default, a recursive add of `round-NN/` will include `.crash-skipped/`
   in the commit. That has audit-trail value (the run record permanently
   captures what reviewers crashed and what their partial output looked
   like) — but the spec doesn't say whether it's intentional. Two
   adjacent concerns: (a) if `.crash-skipped/` is committed, future
   inspectors looking at git history will see a permanent record of every
   crashed reviewer's partial findings, which may include reviewer-internal
   prose the team did not intend to surface; (b) if `.crash-skipped/` is
   meant to be ephemeral (volatile staging for the assembly glob), then a
   re-run of the round on a different machine wouldn't reproduce it from
   git. Spec needs to state the intent: either "committed as audit trail"
   (recommend — already inside `reviews/`, follows the existing audit
   convention) or "gitignored / not committed" (then add a `.gitignore`
   rule for `**/round-*/.crash-skipped/` and document that the staging
   is local-only). Update §2 step 4 line 151 and step 12 line 167.

4. finding_id: R4-F04
   severity: medium
   change_type: clarity
   referenced_files: [docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md]
   message: Trailing-newline schema-violation guard is a hard-fail on a
   stochastic reviewer behavior with no normalize-then-flag fallback.
   §2 line 71 mandates "EXACTLY ONE trailing newline character" on every
   per-finding file emitted by a reviewer; §2 step 2 (line 149) "rejects
   per-finding files with malformed trailing-newline shape (zero or
   two-or-more trailing newlines) per the trailing-newline mandate" —
   hard fail of the round. Reviewers are LLM subagents; LLM `Write` tool
   output is stochastic about trailing whitespace. A reviewer that emits
   two trailing newlines (a common artifact of markdown body
   construction) hard-fails an otherwise-valid round, forcing a manual
   re-run with no recovery path. The mandate is needed for the preserve
   guard's checksum to reproduce, but the dispatcher could
   normalize-then-flag instead of fail-fast: at step 2, if a per-finding
   file has malformed trailing-newline shape, the dispatcher rewrites it
   to canonical one-trailing-newline form (deterministic byte-level fix)
   and surfaces a one-line warning ("normalized trailing newline on
   <path>") to the round audit. The snapshot at step 4 is then taken
   over the normalized file, so the preserve guard checksum stays
   reproducible. Hard fail is reserved for unrecoverable shape errors
   (missing frontmatter, corrupt YAML). Update §2 lines 71 and 149.

5. finding_id: R4-F05
   severity: medium
   change_type: clarity
   referenced_files: [docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md]
   message: Verifier-disabled `round-NN-verified.md` totals header shape
   is undocumented relative to verifier-enabled. §2 step 7 (line 156)
   says the totals header carries "scored/kept/dropped/failed/clean/
   crashed/empty-codex/crash-skipped" rows. In a verifier-disabled round
   (option 1 mid-run, or `verifier_enabled: false` from start), there
   are no scores: `scored=0`, `kept=N` (all findings), `dropped=0`,
   `failed=0`. The header still RENDERS those rows, just with zero
   values — but that's not stated. Future inspectors reading a
   verifier-disabled `round-NN-verified.md` will see a header that
   structurally matches the enabled-round shape but with semantically
   distinct meaning (kept ≠ "score ≥80 survivor"; kept = "all findings
   passed through"). §7 test #8 (line 438) covers the dispatch behavior
   on disabled rounds but doesn't pin the header format. Two fixes:
   (a) in §2 step 7, add one sentence: "verifier-disabled rounds emit
   the same header rows with `scored=0`, all findings counted under
   `kept`, and an additional row `verifier_enabled: false` for inspector
   disambiguation"; (b) extend §7 test #6 (line 434) or test #8 (line
   438) to assert the disabled-round header includes the
   `verifier_enabled: false` row. Without this, `round-NN-verified.md`
   audit interpretation is mode-ambiguous.

6. finding_id: R4-F06
   severity: medium
   change_type: clarity
   referenced_files: [docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md]
   message: Codex prompt template for `<<<FINDING-BOUNDARY>>>` delimiter
   reliability has no worked example. §9 step 4 (line 479) says Codex
   prompts in 9 skills are amended to "inject the `<<<FINDING-BOUNDARY>>>`
   delimiter, the `NO_FINDINGS` sentinel instruction, and to retire the
   `output:` path-arg." §2 lines 192–204 describe the splitter's
   handling of delimiter-bearing input, the `NO_FINDINGS` clean path,
   and the F00 missing-delimiter fallback. The fallback is a real
   safety net, but its existence makes it tempting to skip rigor in
   the Codex prompt itself. Codex (GPT-5.x) is reliable but stochastic
   about emitting structural delimiters when the prompt is terse —
   "emit `<<<FINDING-BOUNDARY>>>` before each finding" without a
   one-shot example will trigger the F00 fallback ~5–15% of runs in
   practice. The spec should require the Codex prompt template to
   include: (i) a worked one-finding example showing the delimiter
   placement (delimiter on its own line, immediately before the YAML
   frontmatter `---`); (ii) a worked zero-findings example showing
   the literal `NO_FINDINGS` sentinel as the entire stdout body; and
   (iii) an explicit "do not emit any prose outside finding blocks
   or the NO_FINDINGS sentinel" constraint. Add to §2 around line 229
   ("The Codex reviewer prompt … is amended to inject…") and pin in
   §7 test #3 (line 428) by asserting the worked-example shape grep.
   Without this, the F00 fallback becomes routine rather than rare.

7. finding_id: R4-F07
   severity: medium
   change_type: scope
   referenced_files: [docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md]
   message: Cutover commit (§9 step 4) has grown to ~50+ files with no
   sub-commit decomposition. The commit lands: 1 reviewer-protocol skill
   amendment, 16 reviewer agent file migrations, 9 Codex-dispatching
   skill amendments, 1 helper script, 1 using-qrspi Apply-fix protocol
   revision, 8 test file additions/updates (#2, #4, #5, #6, #8, #9, #10,
   #11), and possibly the `verifier_enabled` runtime backfill code (per
   R4-F02). That's ~36 files of skills/agents/scripts plus ~8 test files.
   The spec's atomicity argument (line 485) is sound — split commits
   leave main contradictory — but the resulting commit is large enough
   that PR review is genuinely difficult, smoke-test scope is broad, and
   `git bisect` becomes uninformative for any post-cutover regression
   (the bisect lands on this single commit and the operator has no
   sub-commit granularity). Two pragmatic options the spec should
   evaluate: (a) accept the largeness and add a contract that the
   pre-merge validation is exhaustive (existing reviewer-test bats
   pass + every new bats passes + smoke covers all 9 artifact steps,
   not just Goals/Questions per line 487); (b) split into a "main-track"
   commit (skill amendments, agent files, helper script, dispatching
   skill changes — runtime behavior change) and a "test-track" follow-up
   commit (the new bats fixtures), accepting that the test-track lags
   the runtime-track by minutes-to-hours but does not introduce
   contradictory runtime state. Recommend (a) plus an explicit smoke
   matrix in §9 step 5 (currently "Goals or Questions on a fixture spec"
   — broaden to all 9 steps, or at least one per family: Questions
   (no scope reviewer), Goals (all 4 reviewers), Plan (4 reviewers +
   adjacent to deferred plan-artifact reviewers, exercises routing
   pair disambiguation)). Update §9 step 4 line 485 + step 5 line 487.

8. finding_id: R4-F08
   severity: low
   change_type: clarity
   referenced_files: [docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md]
   message: Step 0 follow-up issue rollback contract is incomplete.
   §9 step 0 (lines 467–469) files the follow-up issue BEFORE any code
   commits, so test #2 can cite a real issue number. §9 rollback
   contract (line 489) says: "Step 0's follow-up-issue filing is
   non-revertible (a GitHub issue) but harmless." "Harmless" assumes
   the issue's text refers to spec language that survives a step-4
   revert. But the issue body, written at step 0 time, will reference
   "the bifurcated reviewer-protocol contract introduced in #109 step
   4" and "the 16 deferred reviewers per §2 of the cutover spec." If
   step 4 is reverted, those references describe infrastructure that
   no longer exists on main — the open follow-up issue then references
   a non-existent contract, which is confusing for anyone triaging
   issues post-rollback. Two fixes: (a) the rollback contract
   explicitly closes the follow-up issue with a comment ("Spec for
   #109 was rolled back; this follow-up is moot until #109 lands
   again") as part of the revert procedure; (b) the follow-up issue
   text is written defensively, citing the spec by stable path
   (`docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-
   design.md §8`) rather than the merged commit's file paths, so the
   issue stays self-coherent post-rollback. Recommend (b) — it's
   write-once and survives any number of rollback/re-land cycles.
   Add as a one-liner to §9 step 0 around line 469.

9. finding_id: R4-F09
   severity: low
   change_type: scope
   referenced_files: [docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md]
   message: Expected-Reviewer Matrix sustainability after the deferred
   migration is unaddressed. §2 lines 127–142 define the matrix for the
   9 #109 artifact steps × 2–4 tags = ~30 cells, mostly homogeneous
   (`claude, scope-claude, codex, scope-codex` with `if codex_reviews=
   true` qualifiers). When the follow-up issue migrates the 16 deferred
   reviewers (per-task implementation × 8, plan-artifact × 5,
   implement-gate × 1, security-integration × 1, integration-quality
   × 1), the matrix will need to expand to ~12 artifact_steps with
   significantly heterogeneous tag sets — Implement has 8 reviewers per
   task with different names (`code-quality`, `security`, etc.), Plan
   gains 5 plan-artifact reviewers with their own tags. The textual
   matrix shape from §2 lines 130–140 doesn't compose well: a Plan row
   would be 4 + 5 = 9 tags wrapped across multiple lines. The spec
   doesn't need to redesign the matrix now — but it should acknowledge
   that the post-deferred-migration matrix may want a different
   representation (per-step subsections, or a fenced YAML block parsed
   by the schema-violation guard) and that the follow-up issue scope
   includes "evaluate matrix representation if the textual form
   becomes unwieldy." A two-sentence note in §8 (out of scope) under
   the deferred-migration bullet (around line 453) is sufficient. This
   is forward-looking maintenance hygiene, not a blocker for #109
   landing.

10. finding_id: R4-F10
    severity: low
    change_type: clarity
    referenced_files: [docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md]
    message: `scripts/verifier-preserve-guard.sh check` behavior on
    `.crash-skipped/` finding files is not stated. §2 step 4 (line 151)
    moves crashed-tag finding files into `.crash-skipped/` BEFORE the
    snapshot pass. §2 step 6 (line 155) invokes the helper only on
    "files from step 4's snapshot whose verifier did NOT return
    `VERIFY_FAILED:`" — i.e., the un-skipped, un-failed set.
    `.crash-skipped/` files are never input to the snapshot, never
    input to the helper. That's correct behavior, but the spec
    doesn't say so explicitly; an implementer reading §4 (helper
    script docs, lines 380–385) sees no mention of `.crash-skipped/`
    and might either (a) try to feed those files to the helper "for
    completeness" (causes exit-2 missing-sentinel false alarms), or
    (b) wonder if the helper should reject `.crash-skipped/` paths
    explicitly. One sentence in §4 around line 385: "Files staged
    into `.crash-skipped/` at Apply-fix step 4 are never input to
    the helper; the dispatcher invokes the helper only on the
    non-crashed-tag finding-file set from step 4's snapshot." This
    closes the loop and makes the helper's input contract explicit.

---

Findings: 10 total — 1 high, 6 medium, 3 low.

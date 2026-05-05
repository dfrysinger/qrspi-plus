# Round 5 review — spec-109 (claude)

Scope: NEW issues introduced by the round-4 rewrite (commit `4592431`),
or round-4 issues not actually resolved. Round-4 fixes that landed
cleanly (disk-backed `.snapshots.txt`, runtime-only `verifier_enabled`
backfill, `.crash-skipped/` committed-as-audit-trail, normalize-then-warn
trailing-newline rule, `verifier_enabled` totals row, Codex prompt
worked-example mandate, smoke matrix expansion, follow-up issue stable
spec-path citation, helper-script `.crash-skipped/` exclusion, role-
distinct `reviewer_tag` rename, F00 7-field frontmatter, byte-level
preserve-guard rule, Test #3 alignment to crash-file contract) are NOT
re-flagged.

---

1. finding_id: R5-F01
   severity: medium
   change_type: correctness
   referenced_files: [docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md]
   message: Per-finding YAML `reviewer:` field semantics relative to the
   role-distinct `reviewer_tag` rename are unspecified, and the spec's
   own canonical example contradicts the rename. The reviewer-protocol
   contract (line 76) lists frontmatter fields including `reviewer`. The
   cutover (line 1, line 17, line 96) keys routing on the role-distinct
   `reviewer_tag` (`quality-claude`/`scope-claude`/`quality-codex`/
   `scope-codex`) and mandates the per-finding filename prefix carry the
   same role-distinct value. The F00 fallback (line 205) writes
   `reviewer: {reviewer_tag}` — i.e., uses the role-distinct value in the
   YAML field. But the canonical per-finding-file example at line 356–363
   still shows `reviewer: claude` (the pre-rename collapsed value). Two
   problems: (a) stale example contradicts the rename — it should read
   `reviewer: quality-claude` (or whichever role-distinct value the
   example artifact's reviewer would emit) so future implementers don't
   write the old collapsed value into the YAML; (b) the relationship
   between the YAML `reviewer:` field, the filename prefix, and the
   dispatcher's `reviewer_tag` parameter is not pinned anywhere. The
   schema-violation guard (line 148) lists "missing required fields"
   and "malformed change_type enum" as hard-fail triggers but says
   nothing about whether the YAML `reviewer:` value must equal the
   filename prefix or the dispatcher-passed `reviewer_tag`. If a
   reviewer agent writes `reviewer: claude` (collapsed) into a
   `quality-claude.finding-F01.md` file, does the guard catch it?
   Spec must (i) update the line 362 example to use a role-distinct
   value, and (ii) add one sentence to §2 reviewer-protocol or §2
   step 2 stating "the YAML `reviewer:` field MUST equal the filename
   prefix and the dispatcher-passed `reviewer_tag`; mismatch is a
   hard-fail at step 2."

2. finding_id: R5-F02
   severity: medium
   change_type: correctness
   referenced_files: [docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md]
   message: F00 fallback `finding_id` format violates the canonical
   `R{NN}-F<NN>` pattern with no documented schema-guard regex carve-out.
   The canonical finding_id format is shown in the per-finding example
   at line 356 as `R3-F02` — `R{NN}-F<NN>`, two-digit zero-padded F##.
   The F00 fallback at line 199 uses `R{NN}-{reviewer_tag}-F00` — e.g.,
   `R3-quality-codex-F00`. The spec at line 214 asserts this "satisfies
   the schema-violation guard" but the guard's finding_id regex is never
   documented. If the guard's regex is the strict `^R\d+-F\d{2}$`
   pattern (which is what test #2 or future inspectors would naturally
   write given the canonical example), the fallback file is rejected
   at step 2 — and the fallback's whole purpose (recovering from
   malformed Codex stdout into a routable pause-class finding) is
   defeated. Two fixes: (a) document the finding_id schema as a
   permissive regex that accepts BOTH `R\d+-F\d{2}` and
   `R\d+-[a-z-]+-F00` — and pin this regex in §2 step 2 OR in the
   reviewer-protocol Per-Finding File Contract; (b) extend test #3
   line 448 to explicitly assert the F00 fallback file passes the
   schema-violation guard end-to-end (not just "FULL 7-field synthetic
   frontmatter"). Without either, the fallback's contract is
   load-bearing-on-undocumented-guard-behavior, which is exactly the
   class of bug the round-4 rewrite was trying to close.

3. finding_id: R5-F03
   severity: low
   change_type: clarity
   referenced_files: [docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md]
   message: Smoke matrix synth-crash scenario wording is ambiguous about
   what gets synthesized. §9 step 5 line 512 says: "One run with a
   synthesized crash file in `.crash-skipped/` — verifies step-4 staging
   keeps assembly clean." But `.crash-skipped/` is created BY step 4;
   it's the destination for finding files moved out of the assembly
   glob, not for crash files themselves. The crash file (`<tag>.crash.md`)
   stays in `round-NN/` per §2 line 92 and §3 line 264. To exercise the
   step-4 staging, the smoke fixture must synthesize TWO things in
   `round-NN/`: a `<tag>.crash.md` AND one or more `<tag>.finding-*.md`
   files for the same crashed tag — step 4 then moves the finding files
   to `.crash-skipped/`. The current wording reads as "drop a crash file
   into `.crash-skipped/`" which is the post-step-4 state, not the
   pre-step-4 input. Rewrite line 512 as: "One run with a synthesized
   `<tag>.crash.md` plus matching `<tag>.finding-*.md` files for the
   same crashed tag in `round-NN/` — verifies step-4 staging moves the
   finding files into `.crash-skipped/` and keeps assembly clean."

4. finding_id: R5-F04
   severity: low
   change_type: clarity
   referenced_files: [docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md]
   message: `.snapshots.txt` write semantics on Apply-fix re-entry are
   undefined. §2 step 4 line 150 says "Write the snapshot map to disk
   at `reviews/{step}/round-NN/.snapshots.txt`" with one line per
   finding file. Apply-fix nominally runs once per round, but two
   re-entry paths exist: (a) option-2 re-dispatch at the verifier
   failure menu (§2 step 6 / §5 line 417) explicitly says "reuses the
   step-4 snapshots... no re-snapshot" — implying step 4 does NOT
   re-run on option 2; (b) `/compact`-recovery mid-round, where main
   chat re-enters Apply-fix because the transcript was compacted and
   step 4 is the natural point to re-establish the snapshot map. The
   disk-backed snapshot was added precisely to survive (b) per round-4
   findings. But the spec doesn't say whether re-entry should re-read
   the existing `.snapshots.txt` (preserve original snapshots, skip
   the re-write) or truncate-and-rewrite (which would overwrite valid
   snapshots with post-verifier-write content if any verifier had
   already mutated a file before the compact, producing a guaranteed
   step-6 mismatch). Only the first behavior is correct; the spec
   should pin it. Add one sentence to §2 step 4: "If
   `.snapshots.txt` already exists for the current round, step 4 is
   a no-op (re-read the existing file at step 6); never truncate-and-
   rewrite. This makes step 4 idempotent across `/compact`-recovery
   and option-2 re-dispatch."

5. finding_id: R5-F05
   severity: low
   change_type: clarity
   referenced_files: [docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md]
   message: `.snapshots.txt` audit-trail asymmetry between enabled and
   disabled rounds is undocumented. §2 step 4 line 150 writes
   `.snapshots.txt` only on verifier-enabled rounds (step 3 line 149
   short-circuits to step 7 on disabled rounds, skipping steps 4–6).
   §2 step 12 commits the `round-NN/` subdir, so `.snapshots.txt`
   gets committed on enabled rounds and is absent on disabled rounds.
   Future inspectors comparing round-NN/ contents across rounds will
   see this asymmetry without context. The audit-trail asymmetry is
   correct (no verifier ran → no snapshot to record) but the spec
   should state it explicitly so post-#109 inspectors don't read the
   absence as a missing-file bug. One sentence in §2 step 4 around
   line 150: "On verifier-disabled rounds, `.snapshots.txt` is not
   written (no verifier dispatch occurred); its absence in
   `round-NN/` is the audit signal that the round ran in disabled
   mode, complementing the `verifier_enabled: false` totals row in
   `round-NN-verified.md`."

---

Findings: 5 total — 0 high, 2 medium, 3 low.

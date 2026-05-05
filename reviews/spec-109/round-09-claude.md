# Round 9 review — spec-109 (claude)

Scope: NEW issues introduced or surfaced by the round-8 rewrite (step 3/4
restructure that moved crash-staging unconditionally into step 3 with the
verifier-enabled gate as step 3's last sub-step; §4 splitter empty-input
contract aligned to §2's first-line marker; agent-file description rename
to `<reviewer_tag>.<finding_id>: <score>`; smoke-fixture clarification for
`verifier_enabled: false` from start). Round-8 fixes that landed cleanly
are NOT re-flagged.

Convergence trajectory: r6=7 findings → r7=6 → r8=5. The user's instruction
on this final-round-of-budget pass was to apply a high bar — substantive
issues only, no pedantic nitpicks.

---

Verification pass against the four targeted regression areas:

1. **Step 3/4 restructure propagation.** Searched for stale "step 4"
   crash-staging references. §2 step 7 (line 177), §3 ASCII step 7
   (lines 379–392), §2 step 2 (line 156), §2 step 6 / preserve-guard
   prose (line 176), and §9 step 5 smoke (line 604) all correctly cite
   step 3 as the crash-staging site. Remaining "step 4" references are
   the snapshot site (correct), the snapshot-skipped-on-disabled-rounds
   note (correct), the preserve-guard step-4-snapshot input (correct),
   the cutover commit (§9 step 4, semantically distinct), or the
   `/code-review` step 4–5 examples cite (cross-document, correct).
   Propagation is consistent.

2. **`.snapshots.txt` re-entry semantics under new layout.** Re-entry
   semantics block at line 170 is unchanged from r7; under the new
   layout, on re-entry step 3's crash-staging is naturally idempotent
   (already-staged finding files do not match the `*.finding-*.md`
   glob in the round-NN/ root and so re-staging is a no-op), the
   re-glob produces the same post-staging arrays, the gate re-reads
   `verifier_enabled` (which option 1 may have flipped), and step 4's
   idempotent snapshot subcommand preserves existing entries. The
   semantics hold.

3. **Internal contradictions from the restructure.** §2 step 2 closing
   sentence ("stage them out of the assembly globbing per step 3
   below — staging runs unconditionally") matches §2 step 3's
   substep 1 ("Crash-staging (always)") and §3 ASCII step 3 ("Stage
   crashed-tag finding files into .crash-skipped/ UNCONDITIONALLY").
   §2 step 3's gate ("If `false`, skip steps 4–6") matches §3 ASCII
   ("If false: jump to step 7 with the post-staging arrays, all
   findings kept (no scoring; skip steps 4-6)"). The audit-trail
   asymmetry note (line 172) correctly attributes `.crash-skipped/`
   to step 3 (regardless of mode) and `.snapshots.txt` to step 4
   (verifier-enabled only). No contradictions surfaced.

4. **§4 splitter empty-input contract vs §2.** §2 line 237 specifies
   `<round-subdir>/<reviewer-tag>.crash.md` whose first non-blank line
   is `# @@QRSPI-EMPTY-CODEX-STDOUT@@` (on its own line) followed by a
   `## Splitter Note` body. §4 line 488 now reads "writes a
   `<reviewer-tag>.crash.md` (NOT a clean marker — empty Codex stdout
   is failure, not success) whose first non-blank line is the
   structured marker `# @@QRSPI-EMPTY-CODEX-STDOUT@@` (on its own
   line — required by §2's empty-input contract; the §2 step 7
   totals-header `awk` keys on this marker to count `empty-codex`
   separately from generic `crashed`), followed by a `## Splitter
   Note` body." The two sections agree on the marker shape, the
   first-non-blank-line position, and the awk-counter wiring.
   Codex R8-F02 is fully resolved.

Other passes:
- Verifier brief-return shape: agent-file description (line 31), procedure
  step 8 (line 58), §3 ASCII step 5 (lines 344–350), §4 verifier-failure
  (line 479), test #1 (line 535) all use `<reviewer_tag>.<finding_id>:
  <score>`. Consistent. (Claude R8-F02 resolved.)
- Disabled-mode crash-staging: §2 step 3 substep 1 + step 3 substep 3 +
  §3 ASCII step 3 all explicitly call crash-staging unconditional.
  (Codex R8-F01 resolved.)
- `verifier_enabled` start-of-run: §2 config note (line 197) explicitly
  scopes CLI-flag opt-out OUT and routes "from start" through smoke-
  fixture config.md edit. §9 step 5 (line 602) consistent. §8 (line 573)
  consistent. (Codex R8-F03 resolved.)

NO_FINDINGS

---

Findings: 0 total — 0 high, 0 medium, 0 low.

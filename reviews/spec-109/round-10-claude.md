# Round 10 review — spec-109 (claude)

Scope: NEW issues introduced or surfaced by the round-9 rewrite (pristine-check
on VERIFY_FAILED via `fullhash-check`; round-local `verifier_round_state` split
from persisted `config.md.verifier_enabled`; per-state assembly contract; test
#6 three-state fixtures). Round-9 fixes that landed cleanly (audit-trail
asymmetry across the three states; pristine-check helper at step 6; step 7
totals-header second row) are NOT re-flagged. Convergence trajectory:
r6=7 → r7=6 → r8=5 → r9=2 (Codex) / 0 (Claude). High bar applied.

---

Verification pass against the targeted regression areas:

1. **`verifier_round_state` propagation.** §2 step 7 (lines 186–200) defines
   the three states, the per-state assembly contract, and the totals-header
   second row. §3 ASCII step 7 (lines 411–420) was updated to mention
   `verifier_round_state` in the totals-header description. §5 (line 545)
   sets the round-local state on option 1 alongside the persisted-config
   mutation. Audit-trail asymmetry (lines 173–176) covers all three states.
   Test #6 (lines 574–578) gains three fixtures, one per state.

   §2 step 9's filter prose at line 204 ("filter at score ≥80
   (verifier-enabled rounds) or keep-all (verifier-disabled rounds)") still
   uses the boolean phrasing rather than the round-local state name. The
   resulting partition is functionally equivalent (the binary correctly
   collapses {disabled-from-start, disabled-after-failure} → keep-all and
   {enabled-clean} → ≥80), so this is below the substantive bar — flagged
   here for visibility, not as a finding.

2. **`fullhash-check` composition with re-entry.** Pristine-check at step 6
   (line 180) runs on VERIFY_FAILED files BEFORE the menu; if exit 1, the
   protocol hard-aborts so corrupted state never reaches the menu. Option 2's
   re-dispatch path reuses the step-4 snapshot per line 182 ("the failed
   verifiers' files are still pre-verify shape (verified by the pristine-
   check above) so their step-4 snapshots remain valid"). On a second
   iteration, if the re-dispatched verifier ALSO returns VERIFY_FAILED,
   pristine-check runs again against the same step-4 snapshot — catching
   any partial mutation introduced by iteration 2. The contract composes.

3. **Internal contradictions from the r9 restructure.** Most invariants
   composed cleanly. ONE substantive contradiction surfaced — see R10-F01.

---

1. `finding_id`: `R10-F01`

   `severity`: `medium`
   `change_type`: `correctness`
   `message`: `The re-entry semantics block at §2 step 4 (line 170) asserts
   that option-2 re-dispatch is a step-4 re-entry path: "if Apply-fix step 4
   runs again on the same round (option-2 re-dispatch path or post-\`/compact\`
   recovery), the existing \`.snapshots.txt\` is PRESERVED — never truncated."
   But step 6's option-2 narrative (line 182) explicitly says option 2 does
   NOT re-enter step 4: "Option 2 re-dispatches ONLY the failed verifiers
   (NOT all verifiers — the un-failed ones already wrote their \`## Verifier\`
   blocks; re-dispatching would invalidate the step-4 snapshot for files
   already verified). Option 2 reuses the step-4 snapshots for the un-failed
   verifiers (no re-snapshot); the failed verifiers' files are still
   pre-verify shape (verified by the pristine-check above) so their step-4
   snapshots remain valid." §3 ASCII step 6 (lines 383–390) agrees with line
   182 ("Option 2 → re-dispatch ONLY the failed verifiers ... step-4
   snapshots remain valid and are reused — no re-snapshot"). Two contradictory
   procedural shapes are in the spec: line 170 says option-2 re-enters step 4
   (snapshot subcommand idempotently re-runs); line 182 + §3 say option-2
   stays at step 5 (no step-4 re-entry; snapshots reused as-is). An
   implementer reading line 170 will wire a step-4 re-entry into the
   option-2 handler; an implementer reading line 182 / §3 will jump
   directly to step 5. The two implementations behave the same on
   already-snapshotted finding files (idempotent), but they differ on what
   happens if the round dir gained NEW finding files between iterations
   (e.g., a re-globbed crash-staging change): the line-170 path would
   snapshot the new files, the line-182 path would not. Fix: drop the
   "option-2 re-dispatch path" enumeration from line 170's parenthetical
   (keep only "post-\`/compact\` recovery" as the re-entry trigger), so the
   re-entry semantics describe a path that only fires on transcript-level
   resumption, not on the option-2 path which by spec stays at step 5.
   Alternatively, change line 182 / §3 to say option-2 IS a step-4 re-entry
   and remove the "no re-snapshot" claim. Either resolves the contradiction;
   the first is the smaller edit and matches the §3 ASCII current shape.`
   `referenced_files`: `["docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md"]`

---

Findings: 1 total — 0 high, 1 medium, 0 low.

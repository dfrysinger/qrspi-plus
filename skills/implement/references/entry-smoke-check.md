# Implement-Entry Smoke Check (One-Shot, Per Phase)

Before dispatching the first per-task wave, run this one-shot smoke check. Any failure aborts the phase with a named diagnostic; no per-task dispatch fires. Three conditions:

1. **Verifier agent exists and is readable.** `agents/qrspi-finding-verifier.md` must exist on disk. Failure: `"Implement smoke check failed: agents/qrspi-finding-verifier.md not found or not readable — verifier wiring cannot be activated for this phase."`.
2. **Sidecar write path is reachable.** `reviews/tasks/` must be a writable directory. Probe `.smoke-probe-NN` (NN = `config.md` `phase:`). Before the leftover-probe check, branch on the `phase:` field state:
   - **Field absent (fresh run):** runtime-backfill. Scan phase-bearing artifacts under the run's artifact directory — at minimum `reviews/tasks/.smoke-probe-NN` leftover probe filenames and `reviews/integration/round-NN-commit.txt` files. If no phase-bearing artifacts exist in any scanned source, choose `1`. If every observed ordinal is well-formed, choose `max(NN observed) + 1`. If any scanned source contains a malformed ordinal, or the sources conflict or are ambiguous, halt rather than silently selecting `1`. Before writing, assert no stale `reviews/tasks/.smoke-probe-NN` exists for the chosen ordinal; if it exists, halt with the leftover-probe diagnostic rather than overwriting. Write `phase: NN` back to `config.md` (preserving all other fields), then re-read `config.md` and confirm round-trip. On write failure or read-back mismatch, halt: `"Implement smoke check failed: could not backfill missing phase field to config.md — check write permissions"`.
   - **Field present but non-integer or < 1:** halt immediately: `"Implement smoke check failed: config.md has a malformed phase field (found: <raw value>). Expected positive integer."` — malformed values are not eligible for backfill (corrupted state, not a missing default).
   Read `references/process-steps.md` when the `phase:` field is absent or the backfill scan finds ambiguous/malformed phase ordinals — full backfill procedure, audit YAML schemas, and conflict-resolution rules.
3. **`config.md` carries a parseable `verifier_enabled` field.** Value must be exactly `true` or `false` (YAML boolean, case-sensitive). **Recorded as the phase-start snapshot — authoritative for the entire phase.** Held in main-chat context, NOT written to disk. `config.md` is orchestrator-exclusive-writer; subagents MUST NOT modify it. The HARD-GATE (§ Review Fix Loop step 5) compares against this snapshot, not a gate-time re-read.

All three pass → log `"Implement smoke check passed — verifier_enabled: <value>."` and proceed. When `verifier_enabled: false`, conditions 1 and 2 still apply; verifier dispatch and HARD-GATE are inactive for the phase.

<HARD-GATE>
Do NOT dispatch the first per-task wave before this smoke check passes. A failure halts the phase.
</HARD-GATE>

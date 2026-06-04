---
finding_id: R3-F02
severity: low
change_type: clarity
referenced_files:
  - tests/unit/test-verifier-fan-in-script.bats
reviewer_tag: code-quality-claude
round: 3
task: 02
---

Redundant test: stderr-emission assertion for unreadable finding is covered twice.

- Existing R1: `fix F05: unreadable finding file emits I/O diagnostic to stderr` (lines 354-365)
- New R2: `R2 fix 3: unreadable finding file still emits cannot-read message to stderr` (lines 457-465)

Both tests are structurally and behaviorally identical (same write_finding/write_sidecar/chmod 000 fixture, same `"cannot read"` assertion). The "still" in the R2 name signals intent (verify R2 didn't regress R1's diagnostic), but R1's test still being present and passing already satisfies that intent.

The R2-specific NEW assertion (`R2 fix 3: ...records halt cause finding_unreadable`, lines 445-455) genuinely tests new behavior (new halt cause in audit JSON) — KEEP that.

**Fix:** Remove the duplicate stderr test (lines 457-465). Optionally add a comment to `fix F05` noting it also covers the R2 regression.

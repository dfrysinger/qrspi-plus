---
finding_id: R3-F02
severity: medium
change_type: correctness
artifact: design
round: 3
reviewer: quality-claude
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/design.md:L440-L450
  - docs/qrspi/2026-05-30-v072-release/design.md:L675
---

## CD-4 H.7 audit-log destination contradicts Component E (path, owner, schema, timing)

**Location:** `design.md` CD-4 § H.7 (L675) vs § Component E (L440–450).

**Problem.** Component E locks `.verifier-fan-in-audit.json`:
- Path: `<round-dir>/.verifier-fan-in-audit.json` (L440 + the C-script invocation form at L431 fixes the directory anchor as `<round-dir>`)
- Writer: `scripts/verifier-fan-in.sh` (Component C, L431)
- Schema: `{scored, kept, dropped, halts, thresholds}` (L442–448)
- Timing: written when the script exits, after all sidecars exist (L435–436)

H.7 (L675) "Audit-log entry" then says:

> "Every round-start invocation of the detection script writes `<run-dir>/.verifier-fan-in-audit.json` → `interaction_mode_resolution: {platform, detection_type, verdict, evidence}` ..."

Four incompatibilities:

1. **Directory.** `<run-dir>` (H.7) vs `<round-dir>` (Component E). These are different anchors — `<run-dir>` is the top-level `docs/qrspi/<date>-<slug>-release/` directory; `<round-dir>` is `reviews/{step}/round-NN/`. The same filename in two different directories is two different files.
2. **Owner.** `scripts/detect-interaction-mode.sh` (H.7) vs `scripts/verifier-fan-in.sh` (Component E). Two different scripts writing the same filename.
3. **Schema.** H.7 adds an `interaction_mode_resolution` top-level key; Component E's locked schema does not include it.
4. **Timing.** "Every round-start invocation" (H.7) vs "after fan-in completes" (Component E). The detection script runs at round-start; the fan-in script runs at round-end. If both write the same file, one writer would clobber the other unless explicit merge semantics are locked.

**Impact.** An implementer reading the design cannot reconcile these. Three forks all read as compatible with the prose:

- **(a)** H.7's `<run-dir>` is a typo for `<round-dir>`, the two scripts co-write the same file, and Component E's schema needs an `interaction_mode_resolution` slot plus locked merge semantics (atomic read-modify-write, ordering guarantee that fan-in does not overwrite detection's earlier write, etc.).
- **(b)** H.7 means a *different* audit file (e.g., `<run-dir>/.interaction-mode-audit.json` or `<round-dir>/.detect-interaction-mode-audit.json`) and the shared filename is a copy-paste error.
- **(c)** The detection script does not write JSON at all — it returns its verdict on stdout (per the contract block at L640–664), and the orchestrator persists the resolution into some *other* audit surface (which would also need to be named).

Each fork has different test, lint, and consumer implications. As written, H.7 reads as if it co-owns the verifier-fan-in audit file, which conflicts with Component E's single-owner contract.

**Suggested fix.** Pick one:

- **Rename H.7's destination** to a separate file (e.g., `<round-dir>/.interaction-mode-audit.json`) and update H.7 + the H.7 acceptance fixtures (L683–688) to use the new path. Cheapest; preserves Component E's single-owner property.
- **Extend Component E's schema** to add `interaction_mode_resolution: {...}` as an optional top-level key AND fix the path to `<round-dir>` AND lock the co-write semantics: detection script writes a partial JSON at round-start; verifier-fan-in.sh later reads the existing file (if present), merges in its own fields, and atomically rewrites.
- **Move H.7's persistence** to a non-JSON surface (e.g., as a line in `.round-complete.json` per CD-1 component #4) and remove the `.verifier-fan-in-audit.json` reference from H.7 entirely.

Whichever path is chosen, H.7's acceptance criteria (L683–688) and the round-summary surface (referenced in H.3, see R3-F01) should be updated together so the audit file's full schema and writer/reader contract are consistent across CD-4.

---
reviewer_tag: silent-failure-claude
round: 3
artifact: plan.md
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/plan.md
---

# F03 — T12 `await-round.sh` zero-background-entries success path conflates "manifest empty by design" with "manifest missing or unreadable"

## What is wrong

T12 (`G4 canonical cumulative diff helper`) creates `scripts/await-round.sh` as the manifest-driven drain step. Its DoD includes:

> *"`scripts/await-round.sh` exists and performs the manifest-driven drain, split, status-update, `.round-complete.json` write, dispatch-prompt cleanup, and zero-background-entry success behavior."*

The Test Expectations exercise the success cases:

> *"Exercise `await-round.sh` against pending background entries and zero-entry manifests; verify awaited entries are split, manifest statuses update, `.round-complete.json` is written, round-scoped dispatch prompt files are removed after completion, and zero-entry rounds exit successfully."*

What is **not** specified anywhere in T12's DoD or Test Expectations: what happens when `.dispatch-manifest.json` is **missing entirely** in the round directory (e.g., dispatcher crashed before manifest creation, the directory was cleaned between dispatch and await, or a parallel orchestration step removed it).

T20's DoD echoes the same gap: *"`await-round.sh` resolves all pending background manifest entries ... and is safe to call when the round is first-party-only."* — but "safe to call when first-party-only" can be read two ways: (a) "the dispatcher wrote a manifest with zero background entries → drain succeeds" or (b) "no manifest exists because no background dispatch happened → also succeeds."

If reading (b) is the implementation, then a silently aborted dispatch round is indistinguishable from a legitimate first-party-only round. Both result in `await-round.sh` exiting 0 and writing `.round-complete.json` — but the first case represents a lost round whose findings were never collected.

## Why this is a silent-failure class

This is the textbook SILENT_FALLBACK shape:

- **Empty manifest content** (manifest exists, has `[]` or only resolved first-party entries) → legitimate success.
- **Missing manifest input** (manifest file does not exist) → error condition (dispatcher should always write the manifest, even with zero background entries, per T11's atomic-append contract).

Treating them identically means callers cannot distinguish "the round had no background work" from "the round's bookkeeping was lost." Downstream orchestration (Implement's per-task review loop → integrate → release-PR gate) will accept the empty `.round-complete.json` as a clean signal and advance to the next round, silently skipping the failed dispatch's findings.

The hazard is amplified by T11 sitting upstream of T20 in the dependency graph: T11 writes the manifest, T20's `await-round.sh` reads it, and the two contracts must agree on "manifest always present" as an invariant. If T11's write fails silently (see F02 — no fail-loud requirement on unresolved fields) AND T12's read silently treats a missing manifest as zero entries, the failure mode becomes invisible end-to-end.

design.md ## G7b / #204 (referenced in the round-03 dispatch prompt as the historical anti-pattern this release exists to close) is exactly this shape: an upstream silent miss + a downstream "absence-treated-as-success" reader.

## Where this is in the artifact

- plan.md `### Task 12: G4 canonical cumulative diff helper ...` →
  - `**Definition of done**` bullet *"`scripts/await-round.sh` exists and performs the manifest-driven drain, split, status-update, `.round-complete.json` write, dispatch-prompt cleanup, and zero-background-entry success behavior."*
  - `**Test expectations**` bullet *"Exercise `await-round.sh` against pending background entries and zero-entry manifests; ... zero-entry rounds exit successfully."*
- plan.md `### Task 20: G3 dispatch-script rename collapse ...` → `**Definition of done**` *"`await-round.sh` ... is safe to call when the round is first-party-only."*

## What a fix looks like

Add one DoD bullet and one Test Expectations bullet to T12 (and an aligned tweak to T20's wording):

**T12 DoD addition:** *"If `.dispatch-manifest.json` does not exist in the round directory passed to `await-round.sh`, the script exits non-zero with a diagnostic naming the missing manifest path; the script never treats a missing manifest as an empty-manifest success. Zero-background-entry success requires the manifest to exist with a parseable (possibly empty) entries array."*

**T12 Test Expectations addition:** *"Exercise a missing-manifest fixture (no `.dispatch-manifest.json` in the round directory) and verify `await-round.sh` exits non-zero with the missing-manifest diagnostic and does not write `.round-complete.json`."*

**T20 DoD wording tweak:** Replace *"is safe to call when the round is first-party-only"* with *"is safe to call when the manifest exists and contains zero background entries; missing manifest is a halt condition, not a success path."*

## Confidence

high — DoD and Test Expectations cover the empty-content path but are silent on the missing-input path; T20 reinforces the ambiguity. The G7b/#204 anti-pattern lineage explicitly motivates fail-loud on absence-as-input.

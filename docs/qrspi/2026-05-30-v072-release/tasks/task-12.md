---
status: approved
task: 12
phase: 1
pipeline: full
goal_ids: [G4]
task_type: code
model: opus
sizing_exception: reusable primitives
---

# Task 12: G4 canonical cumulative diff helper (`round-prepare.sh` + `await-round.sh` + section-anchor manifest + per-skill anchors JSON)

- **Target files:** scripts/round-prepare.sh (create), scripts/await-round.sh (create), scripts/g4-section-anchor-manifest.json (modify), skills/using-qrspi/SKILL.anchors.json (modify), skills/reviewer-protocol/SKILL.anchors.json (modify), skills/plan/SKILL.anchors.json (modify)
- **Dependencies:** none. **Blocks:** T13 (per-task review orchestration consumes `round-prepare.sh` diff / scope / commit-anchor artifacts), T20 (dispatch-script rename and reviewer-dispatch migration update `await-round.sh` and consume the round-drain primitive).
- **LOC estimate:** ~280

**Overview**

Create the canonical round-preparation and round-drain primitives that replace hand-reconstructed cumulative diff bases, stale in-memory round bookkeeping, and repeated reviewer-dispatch cleanup rituals. The task also refreshes the G4 section-anchor manifest and per-skill anchor JSON tables so narrow-read lookups remain current for the dispatch, round-preparation, reviewer-protocol, and plan-classification sections touched by this release. (Why: see goals.md ### G4. Approach: see design.md ## G4.)

**Scope**

- **In:**
  - Create `scripts/round-prepare.sh` as the deterministic owner for commit-anchor capture, prior-round bookkeeping validation, convergence-based narrow-or-broaden decisions, backward-loop flag consumption, safe diff-file creation, and `.round-prepare.json` sidecar emission before reviewer dispatch consumes round inputs.
  - Create `scripts/await-round.sh` as the uniform post-dispatch drain step that reads the dispatch manifest, awaits background entries, invokes split commands, updates manifest status, writes `.round-complete.json`, removes round-scoped dispatch prompt files after completion, and succeeds with zero background entries.
  - Update `scripts/g4-section-anchor-manifest.json` and the three per-skill anchor JSON files so refreshed windows cover the dispatch, round-preparation, reviewer-protocol, and plan-classification sections changed by this release.

- **Out:**
  - Adding per-task scope-tagger dispatch, Implement-phase orchestration prose, and tests that consume the new per-task round artifacts — T13 owns.
  - Renaming the dispatch / companion / splitter scripts, migrating review-producing skills to shared reviewer-dispatch prose, and updating renamed dispatch call sites — T20 owns.
  - Creating and including the Evergreen-Output Rule snippet in artifact-producing skills — T27 owns.
  - Re-authoring the G4 problem statement or redesigning the narrow/broaden convergence table — goals.md ### G4 and design.md ## G4 are authoritative.

**Definition of done**

- `scripts/round-prepare.sh` exists and writes `round-NN.diff`, `.round-prepare.json`, and the round commit anchor on valid inputs, with deterministic repeated output and no sidecar corruption under parallel dispatch.
- Per-task preparation rejects partial commit provenance with exit 10, mismatched worktree head with exit 11, and an unadvanced implementer commit with exit 12, each with diagnostics that identify the documented recovery path.
- Prior-round validation fails loudly when the previous commit anchor is missing or malformed, or when a required prior scope-set is missing or empty; reviewer dispatch cannot proceed from stale or absent bookkeeping.
- Convergence handling broadens on missing, empty, full-artifact, superset, overlap, or disjoint scope sets; narrows only for equal sets or proper-subset-with-safety-margin cases; and broadens if the previous commit anchor no longer matches `HEAD~1`.
- Backward-loop flag handling is consume-once: a present flag forces base-branch preparation for the next round, deletes the flag when possible, and surfaces a diagnostic if deletion fails.
- Non-git workspaces return the documented no-diff status without fabricating a diff path or scope hint.
- `scripts/await-round.sh` exists and performs the manifest-driven drain, split, status-update, `.round-complete.json` write, dispatch-prompt cleanup, and zero-background-entry success behavior.
- `scripts/await-round.sh` never echoes captured reviewer payloads or prompt bodies to stdout or stderr; terminal output remains bounded to a short status summary and diagnostics.
- The anchor manifest and per-skill anchor JSON files remain valid JSON and contain refreshed windows for the dispatch, round-preparation, reviewer-protocol, and plan-classification sections changed by this release.

**Test expectations**

- Run file-existence checks for `scripts/round-prepare.sh` and `scripts/await-round.sh`; run JSON validation for `scripts/g4-section-anchor-manifest.json`, `skills/using-qrspi/SKILL.anchors.json`, `skills/reviewer-protocol/SKILL.anchors.json`, and `skills/plan/SKILL.anchors.json`.
- Exercise `round-prepare.sh` happy-path inputs and verify it writes `round-NN.diff`, `.round-prepare.json`, and the round commit anchor; rerun with the same inputs and verify deterministic output without corrupting sidecars under parallel dispatch.
- Exercise per-task preparation failure fixtures for partial commit provenance (exit 10), implementer SHA / worktree HEAD mismatch (exit 11), and unadvanced implementer commit (exit 12), verifying each diagnostic names the correct recovery path.
- Exercise prior-round validation fixtures for missing / malformed `round-(NN-1)-commit.txt` and missing / empty required `round-(NN-1)-scope-set.txt`; verify reviewer dispatch is blocked on each failure.
- Exercise convergence fixtures for missing, empty, full-artifact, superset, overlap, disjoint, equal, and proper-subset-with-safety-margin scope sets, plus the `HEAD~1` mismatch fallback case.
- Exercise backward-loop flag handling and verify the next round is forced to base-branch preparation, the flag is consumed once, and deletion failure is diagnosed.
- Exercise a non-git workspace and verify the documented no-diff status returns without a fabricated diff path or scope hint.
- Exercise `await-round.sh` against pending background entries and zero-entry manifests; verify awaited entries are split, manifest statuses update, `.round-complete.json` is written, round-scoped dispatch prompt files are removed after completion, and zero-entry rounds exit successfully.
- Audit combined stdout and stderr from `await-round.sh` with captured reviewer payload and prompt-body fixtures; verify no captured payload or prompt body is echoed and output stays bounded to the short status / diagnostic surface.
- Grep or diff the refreshed anchor JSON windows to confirm they cover the dispatch, round-preparation, reviewer-protocol, and plan-classification sections changed by this release.

**References**

- goals.md ### G4 — problem framing for canonical cumulative `round-NN.diff` construction and avoiding hand-computed merge-base drift.
- design.md ## G4 — detailed `round-prepare.sh` solution, exit-code recovery table, prior-bookkeeping validation, convergence behavior, sidecar shape, and acceptance criteria.
- structure.md ### `scripts/round-prepare.sh` — Slice 1.4 creation block for the canonical preparation helper and its HEAD-correctness contract.
- structure.md ### `scripts/await-round.sh` — Slice 1.4 creation block for the manifest-driven async drain helper and output-bound contract.
- structure.md ### `scripts/g4-section-anchor-manifest.json` — manifest refresh responsibility for narrow-read section anchors.
- structure.md ### `skills/using-qrspi/SKILL.anchors.json` — per-skill anchor refresh for using-qrspi windows touched by this release.
- structure.md ### `skills/reviewer-protocol/SKILL.anchors.json` — per-skill anchor refresh around reviewer-protocol windows touched by this release.
- structure.md ### `skills/plan/SKILL.anchors.json` — per-skill anchor refresh around Plan classification and reviewer-dispatch windows.

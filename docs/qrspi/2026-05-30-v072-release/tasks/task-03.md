---
status: approved
task: 3
phase: 1
pipeline: full
goal_ids: [G6]
task_type: code
model: opus
---

# Task 3: G6 reviewer disk-write contract across first-party and third-party emission paths

- **Target files:** skills/reviewer-protocol/SKILL.md (modify), skills/reviewer-protocol/first-party-emission.md (create), skills/reviewer-protocol/third-party-emission.md (create), tests/unit/test-per-finding-file-emission.bats (modify)
- **Dependencies:** Task 01. **Blocks:** [Task 04, Task 35] (both modify `skills/reviewer-protocol/SKILL.md` after the G6 protocol split lands).
- **LOC estimate:** ~150

**Overview**

Split reviewer emission guidance into an emission-agnostic reviewer protocol plus first-party and third-party emission contracts, so every reviewer path has one authoritative output channel and wrong-channel output fails loudly instead of masquerading as a clean round. This task pins the file-contract layer in unit coverage while preserving the existing transport-neutral schema and routing content in the protocol core. (Why: see goals.md ### G6. Approach: see design.md ## G6.)

**Scope**

- **In:**
  - Modify `skills/reviewer-protocol/SKILL.md` so it retains only emission-agnostic protocol content: finding schema, classifier, untrusted-data handling, phase routing, dispatch contract, and untrusted scope-hint guidance.
  - Create `skills/reviewer-protocol/first-party-emission.md` with the first-party Write-tool contract, required per-finding paths, clean sentinel path, path rules, and wrong-channel failure surface.
  - Create `skills/reviewer-protocol/third-party-emission.md` with the third-party stdout-boundary contract, `NO_FINDINGS` sentinel, splitter materialization requirements, and wrong-channel failure surface.
  - Modify `tests/unit/test-per-finding-file-emission.bats` to pin the on-disk shape, clean sentinel, third-party materialization, no-findings sentinel, and wrong-channel diagnostic behavior.

- **Out:**
  - Creating `scripts/detect-interaction-mode.sh` and host interaction-mode detection tests — T24 owns.
  - Changing reviewer frontmatter from `category` to `change_type` or partition-routing behavior — T04 owns after this protocol split.
  - Adding the reviewer-protocol anti-fabrication fail-loud rule and acceptance coverage — T35 owns after this protocol split.
  - Modifying dispatch architecture, host/vendor routing, or model-routing tiers — outside this task's target files.

**Definition of done**

- `skills/reviewer-protocol/SKILL.md` contains no emission-contract prose requiring the Write tool or stdout emission; it keeps only the transport-neutral protocol surfaces named above.
- `skills/reviewer-protocol/first-party-emission.md` exists with sections for the first-party emission contract, Write-tool requirements, and path rules.
- The first-party contract requires `<round_subdir>/<reviewer_tag>.finding-F<NN>.md` per finding or `<round_subdir>/<reviewer_tag>.clean.md` for zero findings, and states that any other channel produces zero findings for that tag with the expected loud failure surface.
- `skills/reviewer-protocol/third-party-emission.md` exists with sections for the third-party emission contract, stdout boundary, and splitter requirements.
- The third-party contract requires `<<<FINDING-BOUNDARY>>>` blocks or literal `NO_FINDINGS` on stdout, states that `third-party-finding-splitter.sh` materializes on-disk files, and does not use the word `override` in prose.
- `tests/unit/test-per-finding-file-emission.bats` covers per-finding files, the clean sentinel, third-party boundary materialization, the no-findings sentinel, and wrong-channel output reporting `expected tag produced no output` rather than silently passing.
- Protocol-surface regression checks confirm no pre-rename references to `run-codex-review`, `codex-emission-override`, or `codex-finding-splitter` remain in `skills/reviewer-protocol/SKILL.md`.

**Test expectations**

- Grep audit of `skills/reviewer-protocol/SKILL.md` confirms emission-contract matches for Write-tool or stdout instructions are absent from the core protocol.
- File-existence checks confirm both `skills/reviewer-protocol/first-party-emission.md` and `skills/reviewer-protocol/third-party-emission.md` exist.
- Section-heading checks confirm `first-party-emission.md` includes first-party contract, Write-tool requirements, and path-rules sections, and `third-party-emission.md` includes third-party contract, stdout-boundary, and splitter-requirements sections.
- Path/sentinel grep checks confirm the first-party file names `<round_subdir>/<reviewer_tag>.finding-F<NN>.md` and `<round_subdir>/<reviewer_tag>.clean.md`, while the third-party file names `<<<FINDING-BOUNDARY>>>`, `NO_FINDINGS`, and `third-party-finding-splitter.sh`.
- Grep audit confirms `skills/reviewer-protocol/third-party-emission.md` prose does not contain the word `override`.
- `tests/unit/test-per-finding-file-emission.bats` asserts per-finding file paths, the clean sentinel, third-party boundary materialization, the no-findings sentinel, and wrong-channel emission reporting `expected tag produced no output`.
- Rename-surface grep confirms `skills/reviewer-protocol/SKILL.md` has no `run-codex-review`, `codex-emission-override`, or `codex-finding-splitter` matches.

**References**

- goals.md ### G6 — problem framing for reviewer disk-write contract failures and chat-only reviewer output under task-tool transport.
- design.md ## G6 — selected solution: emission-agnostic protocol core plus first-party and third-party emission siblings with iron-law wrong-channel clauses.
- structure.md ### `skills/reviewer-protocol/SKILL.md` — per-file responsibility for stripping emission prose and retaining only transport-neutral protocol content.
- structure.md ### `skills/reviewer-protocol/first-party-emission.md` — first-party Write-tool contract, path rules, and iron-law insertion source.
- structure.md ### `skills/reviewer-protocol/codex-emission-override.md` → `skills/reviewer-protocol/third-party-emission.md` — verified rename block for the third-party stdout-boundary contract and splitter requirements.
- structure.md ### `tests/unit/test-per-finding-file-emission.bats` — unit coverage surface for per-finding files, clean sentinel, third-party materialization, and wrong-channel failure reporting.

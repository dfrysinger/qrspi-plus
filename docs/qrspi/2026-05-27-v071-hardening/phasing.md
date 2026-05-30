---
status: approved
---

# Phasing: qrspi-plus v0.7.1 hardening

## Slices

Vertical, end-to-end demonstrable delivery units. Iron Law 1 applies: each slice must be demonstrable on its own across every layer it touches.

### Slice 1: POSIX control-char detection rewrite (goal IDs: G1)

The control-char detection in the third-party LLM dispatch script is rewritten to be POSIX-clean and BSD-grep-safe: it catches all 33 control bytes (including LF) and removes the silent-fallback failure mode under BSD grep. This slice touches the dispatch script and the unit suite that pins detection behavior -- the pre-flight detection layer is exercised end-to-end from header input through the die-path trigger through CI. It is a vertical slice because it changes the full path from user-supplied header input to die-path trigger, not just one detection step in isolation.

### Slice 2: Scratch commit-message file added to committed gitignore (goal IDs: G2)

The committed gitignore gains the scratch-commit-message entry, closing the structural gap where the implementer's add-all command staged the scratch file on fresh clones and worktrees. This slice touches the committed gitignore plus the two new unit assertions that pin the gitignore match and confirm the scratch file's absence from the staged index. It is a vertical slice because it exercises the full path from implementer commit flow through gitignore enforcement through CI.

### Slice 3: Fence-aware extract helper promoted to shared library (goal IDs: G3)

The fence-aware section-extraction helper is promoted from an inline duplicate in the SKILL.md content-patterns unit suite to a dedicated function in the shared test-helper library. The consuming unit suite is migrated to the shared function, and new unit coverage pins the helper's behavior including fenced-code blocks. This slice touches the shared helper, the consuming test, and the unit tests that pin the new function's behavior -- the full path from helper authorship through call-site migration through test coverage.

### Slice 4: Wave-grouped Branch Map presentation (goal IDs: G4)

The Parallelize SKILL's flat Branch Map presentation is reorganized so that tasks are grouped per Wave, matching the underlying dependency structure. The matching reviewer-side guidance and the worked-example artifacts are updated to reflect the new presentation. This slice exercises the full path from skill prose through reviewer guidance through worked examples through CI verification.

### Slice 5: Drop evergreen-lint path carve-outs (goal IDs: G5)

All five path-shaped exemption groups are removed from the evergreen-lint helper; the inline opt-out comment mechanism is retained as the sole escape hatch. No new test code is added -- the existing scan run against the full repo with zero carve-outs is the acceptance gate. This slice touches the evergreen-lint test and any prose lines that must be updated or marked exempt to achieve zero violations.

### Slice 6: Cross-CLI Codex detection and per-host dispatch transport (goal IDs: G6)

Host detection (via a deterministic Copilot CLI environment-variable probe) and per-host Codex availability checks are added to the dispatch helper and the using-qrspi skill. Under Copilot CLI, Codex dispatches use the native subagent transport; under Claude Code the shell-pipeline transport is retained. A one-line diagnostic is emitted when the detected host disagrees with the codex-reviews config value. This slice exercises the full path from host-probe through availability check through dispatch routing through unit and integration coverage.

### Slice 7: Cache mechanism retirement (goal IDs: G7a)

Four artifacts are deleted (the cache-probe script, the stub spike report, and two cache-related unit suites), and the cache-control branches are removed from the using-qrspi skill and the dispatch script. The acceptance suite is updated to drop the deleted-suite references. This slice is mechanical -- no new logic is introduced -- and is end-to-end demonstrable by CI staying green after all deletions land.

### Slice 8: Agent model-field deletion with tier vocabulary preserved (goal IDs: G7b)

The model field is deleted from every agent-file frontmatter. Tier names (haiku, sonnet, opus) are preserved as platform-agnostic vocabulary in dispatcher prose; per-host concrete-model resolution stays in the config artifact's existing host-aware resolution table. A structural lint unit test pins that no agent frontmatter carries a top-level model field. This slice touches every agent file, the lint test, and the config resolution table -- the full path from frontmatter removal through dispatcher prose through host-resolution verification.

## Phases

Phase grouping with replan-gate criteria. The Phase 1 PoC guideline applies: Phase 1 should prove the full stack end-to-end whenever possible, with any departure named explicitly.

### Phase 1: PoC -- v0.7.1 hardening release (slices: Slice 1, Slice 2, Slice 3, Slice 4, Slice 5, Slice 6, Slice 7, Slice 8)

**Phase 1 PoC justification.** This release IS the PoC: all 8 slices land together as one coordinated hardening PR, and the release itself constitutes the end-to-end proof. The canonical PoC guideline (full-stack end-to-end in Phase 1) does not map literally to a hardening release with no new pipeline mechanism -- departure is warranted for three explicit reasons. First, each slice carries its own targeted test layer (unit, integration, structural lint, or smoke) as named in `design.md`'s Test Strategy section; the slice-level demonstration requirement is satisfied per-slice, not by a separate PoC phase. Second, splitting 8 independent hardening slices into multiple phases would create artificial coordination boundaries inside a single-PR release, adding replan overhead without surfacing any new integration risk. Third, the one genuine cross-cutting integration risk in this release -- host-detection consistency between G6 (dispatch transport selection) and G7b (host-aware model resolution defaults) -- is exercised by the Slice 6 + Slice 8 combination landing together in Phase 1, exactly where DKR10 requires it (one host-probe implementation serving both goals). The full stack this release exercises is: plugin source --> install --> CI suite --> dual-vendor reviewer dispatch across hosts.

**Replan gate criteria.**

1. The existing CI suite (Lint job + BATS-under-bash-3.2 job) passes on the hardening branch with no regressions against the Phase 1 baseline.
2. A full pipeline dry-run on a freshly installed copy of the hardening branch emits zero "model not available" warnings across all agent dispatches (G7b acceptance, per `goals.md` G7b probe results).
3. Codex reviewer dispatches succeed end-to-end on both Claude Code and Copilot CLI hosts using the host-appropriate transport (G6 acceptance, per `design.md` DKR7).
4. The evergreen-lint scan runs across the full repo with all path carve-outs removed and reports zero violations (G5 acceptance, per `design.md` DKR5).
5. The control-char detection in the third-party LLM dispatch script correctly triggers the die path on a raw LF byte input without a silent grep fallback under a BSD-grep environment (G1 acceptance, per `design.md` DKR1).
6. A simulated implementer commit flow confirms the scratch commit-message file is absent from the staged index (G2 acceptance, per `design.md` DKR2).
7. The fence-aware section-extraction helper exists as a dedicated function in the shared test-helper library, the inline duplicate is removed from the consuming unit suite, and unit coverage pins the helper's behavior including fenced-code blocks (G3 acceptance, per `design.md` DKR3).
8. The Parallelize SKILL presents its Branch Map grouped per Wave, with reviewer-side guidance and worked-example artifacts updated to match (G4 acceptance, per `design.md` DKR4).

## Goal-ID Consistency

Every goal ID in `roadmap.md` (G1, G2, G3, G4, G5, G6, G7a, G7b) maps to exactly one slice above and appears in `goals.md`, `questions.md`, `research/summary.md`, and `design.md`. G8 is a deliberate non-entry on the roadmap and is documented under `## Orphan IDs` below.

## Orphan IDs

- **G8** -- closed at Design DKR11 as out-of-scope for v0.7.1; not on the roadmap by design. The "broader subagent-dispatch port" question was absorbed by DKR7 (per-host dispatch transport); broader retirement of the shell pipeline is deferred to v0.8.

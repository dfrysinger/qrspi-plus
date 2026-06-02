---
step: plan
round: 1
artifact: docs/qrspi/2026-05-30-v072-release/plan.md
verifier_enabled: true
scored: 34
kept: 11
dropped: 23
failed: 0
clean: 1
---

## Auto-applied correctness fixes (7)

- **quality-claude.F02 + scope-claude.F01** — T05 Target files: `scripts/verifier-fan-in.sh (create)` → `(modify)`. T02 owns creation; T05 is hardening. Single edit resolved both findings.
- **quality-claude.F01** — T25 Blocks line corrected. Replaced misleading `T27 (reviewer-protocol consumer), T28-T31 (remaining G31 consumers)` with the actual downstream block list: `T26 (G31 !cat include sites + skill-frontmatter preloads), T39 (G32 build pipeline's defensive copy of skills/_shared/prompt-prose-detection.md)`.
- **quality-codex.F01** — 3 unowned files now have task owners. Added `tests/lint/test-design-altitude-boundary-include.bats` to T29 Target files. Added `skills/structure/owns-defers.md` and `tests/lint/test-structure-altitude-boundary-include.bats` to T37 Target files.
- **quality-codex.F02** — `sizing_exception` enum normalized to hyphenated form `schema-migration` across 4 sites (T16 overview L63; T16 body L984; T33 Scope/Out L2049; T33 Test expectations L2067). Prose mentions of "schema migration" the concept remain unchanged.
- **security-claude.F02** — T39 DoD and Test expectations now require symlink canonicalization in `tools/build-plugin.mjs`: every `!cat` target path canonicalized via `fs.realpathSync` before its bytes are read; canonical-outside-`$REPO_ROOT` rejected with `resolves outside repository` diagnostic. Mirrors T21's `assert_path_under_repo_root` guard in `scripts/dispatch-agent.sh`. Closes the symlink-escape exfiltration surface where a checked-in symlink could inline `/etc/passwd` into a shipped `build/` file.
- **spec-claude.F01** — Option A applied. T20 Dependencies expanded from `Task 12, Task 19` to `Task 09, Task 11, Task 12, Task 13, Task 19` (T09 modifies `run-codex-review.sh` for `actual_model:`; T11 modifies it for dispatch-manifest provenance; T13 modifies `round-prepare.sh`). Blocks edges added to T09, T11, T13 each pointing at T20. Dependency Graph gained a new cluster #4 describing the rename-collapse fan-in.
- **test-coverage-codex.F01** — T27 extended to cover the two CD-2 acceptance surfaces it previously deferred to Out. Added `skills/reviewer-protocol/SKILL.md` and `skills/using-qrspi/SKILL.md` to Target files. Added In bullets for the using-qrspi pointer line and the reviewer-protocol antagonist-pattern enforcement clause. Added matching DoD bullets and Test expectations bullets. Removed the matching Out deferral.

## Pause-gate dispositions (4 scope findings, all bypass-filter)

- **scope-claude.F01** — Skipped. Duplicate of quality-claude.F02; resolved by the same T05 `(create)` → `(modify)` edit.
- **scope-codex.F01** (verifier 55) — Skipped. scope-claude OPPOSES. Per-task Phase-1 acceptance bullets in plan tasks are intentional per-task wiring at the plan altitude, not duplication of phasing.md's phase-level acceptance.
- **scope-codex.F02** (verifier 22) — Skipped. scope-claude OPPOSES. Verifier scored 22 (signaling false positive). Verbatim implementation-anchor specificity (e.g., `realpath`, `JOB_ID=<id>`) is deliberate per the T25-pilot brainstorm — implementers need exact anchors to grep against.
- **scope-codex.F03** (verifier 20) — Skipped. scope-claude OPPOSES. Verifier scored 20. The 2733-line single-file size is the pre-approval authoring contract; post-approval split into per-task files is owned by G5 / T34 (Plan post-approval split idempotency).

## Verifier drops (23 — summary)

- 4 clarity findings dropped at score <80.
- 19 correctness findings dropped at score <70 (typical patterns: verifier judged the artifact already covers the concern via cross-references or existing prose; verifier flagged Plan author altitude as the wrong place for the concern; verifier flagged the finding as opinion-shaped rather than defect-shaped).

## Round commit

See `round-01-commit.txt` for the per-round commit SHA (step 11 of the Apply-fix protocol; consumed by round 2's HEAD~1 anchor).

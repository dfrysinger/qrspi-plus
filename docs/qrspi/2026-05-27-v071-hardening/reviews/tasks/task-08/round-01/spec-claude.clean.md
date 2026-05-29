---
reviewer_tag: spec-claude
round: 1
verdict: CLEAN
---

# T8 spec-reviewer (Claude) — round 01 — CLEAN

All 11 BATS-introspectable TEs (TE1–TE10) directly observable in the worktree. TE11 (CI green) is external.

Implementer-surfaced concerns adjudicated:

1. **Slice 7 C-1/C-2 removal beyond literal spec wording — IN SCOPE.** Spec mandates removal of `SPIKE` export + `run_pin` invocations; sibling test bodies that dereference `$SPIKE` after the spike file deletion break the CI-green acceptance gate if retained. Removal is consequential maintenance required by the spec's explicit CI-green TE11. Explanatory comment block at test-phase1-acceptance.bats:172–181 is appropriate inline documentation.

2. **`skills/using-qrspi/SKILL.anchors.json` regeneration (88 lines, not in Target Files) — IN SCOPE (advisory).** Generated metadata indexed by SKILL.md line offsets; stale index breaks `test-section-anchor-narrow-read.bats` which Slice 7 C-4 invokes. Auxiliary-correctness work required by the SKILL.md modification.

3. **Stale `supports_prompt_cache:` / `emit_cache_control_markers:` YAML in fixture helpers — SPEC-COMPLIANT.** TE5/TE6/TE7 mandate absence only in SKILL.md and run-third-party-llm.sh. Dispatcher's awk parser ignores those keys silently. Fixture cleanup is out of T8 scope.

Verdict: CLEAN. Correctness reviewers (quality + security, ± Codex per config) may proceed.

Procedural note (orchestrator side): agent reported it could not find the diff file. Diff file exists at the expected absolute path; agent's worktree resolution may have looked relative to integration worktree. Fallback (direct worktree reads) successfully closed the loop.

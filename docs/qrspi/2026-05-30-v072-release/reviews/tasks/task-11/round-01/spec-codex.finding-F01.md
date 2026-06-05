---
finding_id: R1-F01
reviewer: spec-codex
severity: high
change_type: correctness
referenced_files:
  - scripts/run-codex-review.sh
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats
---

# F01 — Manifest append is not concurrency-safe (lost-update race)

**Spec requirement (task-11.md lines 27, 39, 47):** "Make manifest writes atomic and append-safe for repeated invocations and multiple reviewer tags in the same round. … Manifest append behavior is atomic and append-safe across multiple reviewer tags in one round."

**Implementation defect:** `_append_manifest_entry` (scripts/run-codex-review.sh lines 205-217) is read-modify-write + `mv` with NO lock / CAS. The orchestrator dispatches multiple reviewer tags concurrently for the same task in the same round (spec-codex, cq-codex, sf-codex, sec-codex, etc. — see implement/SKILL.md § Dispatching Reviewers § Codex parallels — multiple reviewer subagents fire in the same wave, each invokes `scripts/run-codex-review.sh` independently). Two concurrent invocations can both read the same prior manifest, each compose its own tmp file, and the last `mv` wins — silently dropping all entries the loser wrote.

**Why this matches the spec's "multiple reviewer tags in one round" clause:** the concurrent-writers scenario IS the spec's stated requirement, not an edge case. Parallel reviewer dispatch is the dominant code path.

**Fix sketch:** wrap the read-modify-write in `flock` on the manifest file (or on a sentinel `.lock` neighbor), so only one writer holds the file at a time. macOS lacks `flock` natively; the existing helper pattern in this repo uses `mkdir <lockdir>` as a portable mutex — pick whichever matches existing repo idiom.

**Required test:** add an acceptance assertion that launches N≥2 concurrent `_append_manifest_entry` invocations against the same manifest path and asserts all N entries survive in the final JSON.

**Disposition:** in scope for T11 — closes the spec's atomic/append-safe clause for the realistic concurrent scenario.

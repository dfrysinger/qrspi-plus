---
status: approved
task: 27
phase: 1
pipeline: full
goal_ids: [G7]
task_type: tdd
tier: medium
---

# Task 27: Create tests/unit/test-narrow-round-anchor-lookup.bats

- **Target files:** `tests/unit/test-narrow-round-anchor-lookup.bats` (Create)
- **Dependencies:** T26
- **LOC estimate:** ~60
- **Description:** A bats test with four fixtures verifies the anchor-file lookup behaves correctly under the failure modes `HEAD~1` exposed. Fixture 1: round N+1 with an unrelated commit landed between rounds — the anchor-file-based diff returns round N's per-round commit content, the `HEAD~1`-based diff returns wrong content (regression guard against the v0.7.2 shifted-shape bug). Fixture 2: anchor file missing — the orchestrator's call exits non-zero with the `anchor-file-missing:` named diagnostic, no silent fallback to `HEAD~1`. Fixture 3: empty narrowed diff — the divergence sanity check fires with the `narrow-round-empty-diff:` named diagnostic. Fixture 4: malformed anchor-file content — the orchestrator's call halts with the `sha-format-invalid:` named diagnostic.
- **Test expectations:**
  - Dispatch order: test-writer first, implementer second (RED-verification gate between).
  - Fixture with an unrelated commit between rounds — anchor-file-based diff "returns the correct content (round N's per-round commit diff)" while `HEAD~1`-based diff "returns wrong content" (G7 Acceptance bullet 3 sub-bullet 1).
  - Missing anchor file — the orchestrator's call halts with the `anchor-file-missing:` named diagnostic and exits non-zero "with a clear error (no silent fallback)" (G7 Acceptance bullet 3 sub-bullet 2).
  - Empty-narrowed-diff — "the divergence sanity check fires with the `narrow-round-empty-diff` diagnostic" (G7 Acceptance bullet 3 sub-bullet 3).
  - Fixture with a malformed anchor file (e.g., uppercase hex, non-hex characters, or content outside the well-formed git object-name shape) — the orchestrator's call halts with the `sha-format-invalid:` named diagnostic and exits non-zero before any `git diff` runs against the malformed value.

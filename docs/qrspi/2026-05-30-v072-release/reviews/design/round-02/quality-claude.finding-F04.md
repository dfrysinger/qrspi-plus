---
finding_id: R2-F04
severity: medium
change_type: correctness
artifact: design
round: 2
reviewer: quality-claude
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/design.md
---

## G20 deliverable 2 — stale `scripts/run-codex-review.sh` reference not updated by R1 sweep

**Location:** `design.md` L1880 (G20 § Deliverables, item 2)

**Problem.** G20 deliverable 2 reads in part:

> "The orchestrator already resolves this value at dispatch site (it's the value passed to `Agent({ ..., model })` for Claude subagents and to the reviewer model flag of **`scripts/run-codex-review.sh`** for Codex subagents)."

`run-codex-review.sh` was renamed to `dispatch-agent.sh` under CD-1's hard-cutover rename inventory (design.md L194). The third-party (Codex) vendor routing is now handled by `dispatch-companion.sh` (renamed from `run-third-party-llm.sh`). Neither `run-codex-review.sh` nor its old "reviewer model flag" interface exists in v0.7.2.

The R1 rename sweep (fix 4) correctly updated G20 deliverables 3 and 4 (file names `third-party-emission.md`, `dispatch-companion.sh`, `third-party-finding-splitter.sh`), and G33 D2's script inventory. However, this inline prose sentence in deliverable 2 — describing where the `actual_model` dispatch parameter value comes from — was missed.

**Impact.** An implementer reading G20 deliverable 2 would look for a `-m`/`--model` flag on `run-codex-review.sh` that no longer exists. The actual source of the `actual_model` value for third-party dispatches is the `--model` flag (or equivalent) on `dispatch-companion.sh`. This mismatch would cause confusion at Plan/Structure time when locating the dispatch parameter injection point.

**Suggested fix.** Update the prose in deliverable 2 from "to the reviewer model flag of `scripts/run-codex-review.sh` for Codex subagents" to "to the model-resolution output consumed by `scripts/dispatch-companion.sh` for third-party (Codex) subagents" (or equivalent wording that names the post-rename script).

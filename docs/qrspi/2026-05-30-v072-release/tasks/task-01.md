---
status: approved
task: 1
phase: 1
pipeline: full
goal_ids: [G7]
task_type: lightweight
model: sonnet
---

# Task 01: G7 verifier-filter-rule shared snippet

- **Target files:** skills/_shared/verifier-filter-rule.md (create)
- **Dependencies:** none. **Blocks:** [Task 03] (reviewer disk-write contract work is ordered after this shared snippet).
- **LOC estimate:** ~60

**Overview**

Create the shared verifier-filter-rule snippet consumed by orchestrator prose so the filter boundary is visible at point of use without copying numeric threshold values into loaded skill text. The snippet makes `scripts/verifier-fan-in.sh` header constants the authoritative threshold source and gives downstream consumers a single reusable statement instead of another drift-prone paraphrase. (Why: see goals.md ### G7. Approach: see design.md ## G7 and design.md ### CD-4.)

**Scope**

- **In:**
  - Create `skills/_shared/verifier-filter-rule.md` with a `## Verifier Filter Rule` section.
  - State, in one short canonical passage, that verifier fan-in filters findings according to script-owned header constants and that consumers read the kept set produced by the fan-in flow.
  - Explicitly point consumers to `scripts/verifier-fan-in.sh` header constants for current filter floors while keeping numeric threshold values out of the snippet.
  - Apply R1-R7 plus the cross-cutting prompt-design principles from `skills/_shared/prompt-design-rules.md` to keep the snippet concise, reusable, positive, and load-bearing.

- **Out:**
  - Implementing `scripts/verifier-fan-in.sh` and the verifier-dispatch prose snippet — T02 owns.
  - Updating reviewer emission contracts, sidecar formats, or `change_type` schema enforcement — T03-T05 own those downstream surfaces.
  - Rewriting loaded consumer skill prose or adding `!cat` include sites beyond this new snippet file — downstream consumer tasks own those modifications.

**Definition of done**

- `skills/_shared/verifier-filter-rule.md` exists and contains exactly one `## Verifier Filter Rule` section.
- The snippet contains no inline numeric threshold values for the verifier filter floors.
- The snippet names `scripts/verifier-fan-in.sh` header constants as the authoritative source for current filter floors.
- The snippet explains the script-owned filter boundary clearly enough that consumers do not need to restate threshold values in loaded orchestrator prose.
- The snippet remains a short canonical reusable statement, not a historical explanation or duplicated apply-fix procedure.
- The text satisfies the applicable prompt-design rules: concise wording, shared-spine/reference discipline, anchor-phrase use, positive substitute, and load-bearing-rule clarity.

**Test expectations**

- File-existence check for `skills/_shared/verifier-filter-rule.md`.
- Grep check confirms a `## Verifier Filter Rule` heading exists in the snippet.
- Grep audit confirms verifier floor numerals are absent from the snippet while `scripts/verifier-fan-in.sh` and `header constants` are present.
- Prompt-design review applies R1-R7 plus cross-cutting principles from `skills/_shared/prompt-design-rules.md` and verifies the snippet is one concise canonical statement, not duplicated consumer prose.
- Anchor-phrase audit confirms the snippet directs readers to `scripts/verifier-fan-in.sh` header constants rather than restating current threshold values.

**References**

- goals.md ### G7 — problem framing for verifier threshold drift and missing point-of-use rule visibility.
- design.md ## G7 — chosen approach: script-owned threshold source and short pointer prose.
- design.md ### CD-4 → F / G7 acceptance — fan-in pipeline, orchestrator-side prose collapse, and no-threshold-in-skills acceptance checks.
- structure.md ### `skills/_shared/verifier-filter-rule.md` — per-file responsibility, required heading, no-inline-threshold constraint, and anchor pointer phrase.

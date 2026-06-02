---
status: approved
task: 6
phase: 1
pipeline: full
goal_ids: [G11]
task_type: code
model: sonnet
---

# Task 06: G11 verifier sidecar extension correction and orchestrator-bypass fix

- **Target files:** agents/qrspi-finding-verifier.md (modify), tests/unit/test-verifier-agent-file.bats (modify)
- **Dependencies:** Task 02. **Blocks:** T07 (G14 verifier rubric correction extends the same verifier agent and verifier-agent test file).
- **LOC estimate:** ~80

**Overview**

Lock the verifier's disk sidecar output to the single `.score.md` path consumed by the fan-in script, and make any chat-side score report non-load-bearing telemetry so verifier filtering cannot silently bypass the canonical disk contract. The paired verifier-agent test pins the extension, required `score:` field, and wrong-extension rejection behavior before later verifier-rubric work builds on the same files. (Why: see goals.md ### G11. Approach: see design.md ## G11 and design.md ### CD-4 — Verifier-Fan-In Pipeline (end-to-end flow specification) → B. Verifier sidecar.)

**Scope**

- **In:**
  - Constrain `agents/qrspi-finding-verifier.md` to write exactly one sidecar per finding at `<round-dir>/<reviewer-tag>.finding-F<NN>.score.md`.
  - Remove any instruction path, example, or allowed alternative that mentions `.score.yml` for verifier score sidecars.
  - Require verifier sidecar frontmatter to contain `score:` as an integer from 0 through 100, with human-readable verifier reasoning kept in the markdown body.
  - Mark any chat-side score summary as non-load-bearing telemetry; the disk sidecar is the canonical output consumed by the fan-in path.
  - Extend `tests/unit/test-verifier-agent-file.bats` to pin the locked extension, required `score:` field, absence of `.score.yml` allowance, and rejection of wrong-extension sidecar references through the fan-in-side contract.

- **Out:**
  - Creating or changing `scripts/verifier-fan-in.sh` itself — T02 owns the fan-in consumer that T06 aligns the verifier agent against.
  - Adding the G14 `Informational:` verifier rubric carve-out or reviewer-protocol convention — T07 owns.
  - Creating the interaction-mode detection helper for apply-fix orchestration — T24 owns the shared G11/G12/G6 helper surface.
  - Adding later verifier rubric calibration fields or cite-check behavior — T08-T10 own those downstream verifier-agent extensions.

**Definition of done**

- `agents/qrspi-finding-verifier.md` instructs the verifier to write exactly one sidecar per finding at `<round-dir>/<reviewer-tag>.finding-F<NN>.score.md`.
- No verifier instruction path, example, or allowed alternative in the target agent file mentions `.score.yml`.
- The verifier sidecar contract requires frontmatter containing `score:` as an integer from 0 through 100.
- The verifier sidecar contract leaves verifier reasoning in the markdown body for audit/debug reading.
- Any chat-side score summary, if still present, is explicitly described as non-load-bearing telemetry rather than the canonical filtering input.
- `tests/unit/test-verifier-agent-file.bats` asserts the locked extension, required `score:` field, absence of `.score.yml` allowance, and wrong-extension rejection behavior.
- Existing sidecar-extension assertions remain intact for T07 to extend without weakening this contract.

**Test expectations**

- Pre-implementation RED check: `tests/unit/test-verifier-agent-file.bats` fails while `agents/qrspi-finding-verifier.md` does not require sidecars at `<round-dir>/<reviewer-tag>.finding-F<NN>.score.md` with no `.score.yml` alternative.
- Post-implementation run of `tests/unit/test-verifier-agent-file.bats` passes only when the verifier agent file pins `.score.md`, requires `score:` in sidecar frontmatter, and contains no `.score.yml` allowance.
- Grep audit of `agents/qrspi-finding-verifier.md` confirms the canonical path shape `<round-dir>/<reviewer-tag>.finding-F<NN>.score.md` is present and `.score.yml` is absent.
- Test inspection confirms chat-side score output is non-load-bearing telemetry and the disk sidecar is the canonical fan-in input.
- Regression assertion confirms wrong-extension sidecar references remain rejected by the fan-in-side contract rather than accepted as a fallback.

**References**

- goals.md ### G11 — problem framing for extension drift plus orchestrator bypass of disk sidecars.
- design.md ## G11 — maps the goal to CD-4's locked `.score.md` sidecar and script-consumed disk contract.
- design.md ### CD-4 — Verifier-Fan-In Pipeline (end-to-end flow specification) → B. Verifier sidecar — exact verifier sidecar path, schema, and non-load-bearing chat-output rule.
- structure.md ### `agents/qrspi-finding-verifier.md` — Slice 1.1 verifier-agent responsibility for G11 sidecar path/extension and `score:` frontmatter.
- structure.md ### `tests/unit/test-verifier-agent-file.bats` — Slice 1.1 test responsibility for sidecar extension, required fields, and verifier-agent prose pins.

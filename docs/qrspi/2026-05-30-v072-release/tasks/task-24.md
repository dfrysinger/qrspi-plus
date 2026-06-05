---
status: approved
task: 24
phase: 1
pipeline: full
goal_ids: [G6, G11, G12]
task_type: code
model: sonnet
---

# Task 24: CD-4 `detect-interaction-mode.sh` helper

- **Target files:** create `scripts/detect-interaction-mode.sh`; create `tests/unit/test-detect-interaction-mode.bats`
- **Dependencies:** Task 02
- **LOC estimate:** ~110

**Overview**

Create the round-start interaction-mode detector that centralizes host-specific auto/interactive detection behind a stdout-only helper and dedicated bats coverage. This lets apply-fix orchestration decide halt, rescue, or safe-default behavior without duplicating host signals in skill prose or agent bodies. (Why: see goals.md ### G6, goals.md ### G11, goals.md ### G12. Approach: see design.md ### CD-4 → I.7 and structure.md ### `scripts/detect-interaction-mode.sh`.)

**Scope**

- **In:**
  - Create `scripts/detect-interaction-mode.sh` as a no-argument helper that emits one `KEY=VALUE` pair per line and exits 0 for successful detection, including safe-default branches.
  - Implement the three documented detection protocols: `shell-verdict`, `llm-context`, and `user-override-only`, including Copilot CLI, Claude Code, unknown-host, override, and safe-default behavior from design.md ### CD-4 → I.7.
  - Enforce `QRSPI_INTERACTION_MODE=auto|interactive` as the explicit override; invalid override values and positional arguments fail loud with diagnostics.
  - Keep the helper stdout/stderr-only: it never writes `.interaction-mode-audit.json` or any other file.
  - Include the required script-header material: locked platform directory, override chain, encapsulation rule, and implementation-start verification citation block.
  - Create `tests/unit/test-detect-interaction-mode.bats` to pin host branches, override behavior, invalid input failures, stdout parseability, no-file-write behavior, and grep regression coverage for host-specific literals.

- **Out:**
  - Verifier fan-in kept-set computation, `.verifier-fan-in-audit.json`, and verifier-dispatch prose — T02 owns.
  - Reviewer first-party / third-party emission contract splitting and wrong-channel reviewer output handling — T03 owns.
  - Verifier sidecar extension locking and score-sidecar canonicalization — T06 owns.
  - Writing `<round-dir>/.interaction-mode-audit.json` and caching the resolved tuple in orchestration — outside this helper; the script only returns the protocol the orchestrator consumes.
  - Adding host-specific auto-mode literals to SKILL prose, agent bodies, or shared snippets — explicitly prohibited by the encapsulation rule.

**Definition of done**

- `scripts/detect-interaction-mode.sh` exists, accepts no positional arguments, and fails non-zero with usage diagnostics when any argument is supplied.
- With `COPILOT_CLI=1`, the helper emits `PLATFORM=copilot-cli`, `DETECTION_TYPE=llm-context`, and an instruction for inspecting the active context for the Copilot autopilot marker and sentence.
- With Claude Code host signals and no `COPILOT_CLI`, the helper emits `PLATFORM=claude-code`, `DETECTION_TYPE=llm-context`, and an instruction for inspecting active context for the Claude auto-mode marker.
- With no recognized host and no override, the helper emits `PLATFORM=unknown`, `DETECTION_TYPE=user-override-only`, `VERDICT=interactive`, and evidence naming the safe default.
- With `QRSPI_INTERACTION_MODE=auto` or `QRSPI_INTERACTION_MODE=interactive`, the override wins and the helper emits a direct `VERDICT` with evidence naming the override value.
- With any other `QRSPI_INTERACTION_MODE` value, the helper exits non-zero and names the allowed values; it does not silently coerce the value to interactive.
- The helper never writes `.interaction-mode-audit.json` or any other file.
- The script header contains the locked platform directory, override chain, encapsulation rule, and implementation-start verification citation block required by design.md ### CD-4 → I.7.
- Shell output is parseable as one `KEY=VALUE` pair per line, contains no placeholder values, and uses only `shell-verdict`, `llm-context`, or `user-override-only` for `DETECTION_TYPE`.
- Host-specific auto-mode literals appear only in `scripts/detect-interaction-mode.sh` and this task's dedicated test fixtures; consumer skill prose and agent bodies do not gain those literals.

**Test expectations**

- Bats tests cover the Copilot CLI branch (`COPILOT_CLI=1`) and assert `PLATFORM=copilot-cli`, `DETECTION_TYPE=llm-context`, and the expected Copilot context-inspection instruction.
- Bats tests cover the Claude Code branch with no `COPILOT_CLI` and assert `PLATFORM=claude-code`, `DETECTION_TYPE=llm-context`, and the expected Claude context-inspection instruction.
- Bats tests cover unknown host with no override and assert `PLATFORM=unknown`, `DETECTION_TYPE=user-override-only`, `VERDICT=interactive`, and safe-default evidence.
- Bats tests cover `QRSPI_INTERACTION_MODE=auto` and `QRSPI_INTERACTION_MODE=interactive` and assert the override verdict and evidence win.
- Bats tests cover invalid `QRSPI_INTERACTION_MODE` values and positional arguments as non-zero failures with diagnostics.
- Tests verify the helper is stdout/stderr-only by asserting no `.interaction-mode-audit.json` or other files are created during execution.
- Header inspection asserts the locked platform directory, override chain, encapsulation rule, and implementation-start verification citation block are present.
- Grep-based regression coverage permits host-specific auto-mode literals only in `scripts/detect-interaction-mode.sh` and `tests/unit/test-detect-interaction-mode.bats` fixtures, and rejects those literals in consumer skill prose or agent bodies.
- Output-shape tests assert every stdout line is a `KEY=VALUE` pair, no placeholder values are present, and `DETECTION_TYPE` is one of `shell-verdict`, `llm-context`, or `user-override-only`.

**References**

- goals.md ### G6 — disk-write / chat-side fragility problem framing that CD-4 avoids extending into interaction-mode detection.
- goals.md ### G11 — sidecar pipeline drift problem framing; Task 24 stays limited to the interaction-mode helper used around CD-4 orchestration.
- goals.md ### G12 — fan-in automation motivation; Task 24 supports the orchestration mode decision around that automated path.
- design.md ### CD-4 → I.7 — locked platform directory, override chain, stdout protocol, audit-writer boundary, encapsulation rule, caching rule, and acceptance criteria for interaction-mode detection.
- design.md ## G6 — reviewer disk-write reliability context resolved structurally elsewhere; this task only prevents host-specific detection prose drift.
- design.md ## G11 — sidecar extension + orchestrator-bypass context resolved by CD-4 verifier fan-in, not by this helper.
- design.md ## G12 — verifier-fan-in script context that Task 02 owns; Task 24 only supplies the round-start mode detector.
- structure.md ### `scripts/detect-interaction-mode.sh` — per-file responsibility, interface, lifted header content, outline-only sections, and grep-lint surface.
- structure.md ### 12. Interaction-mode detector — cross-cutting schema for stdout shapes, override chain, locked platform directory pointer, and audit-file boundary.

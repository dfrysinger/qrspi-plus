---
finding_id: F04
artifact: design
reviewer: quality-claude
round: 1
severity: low
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/design.md
  - docs/qrspi/2026-05-30-v072-release/goals.md
---

## YAGNI — CD-4 halt-response protocol introduces substantial scope not requested by any of G7 / G8 / G11 / G12 / G13

### Where

`design.md` § CD-4, sections E–H and the `detect-interaction-mode.sh` fixture block
(approximately lines 450–632).

### What the five goals asked for

The five goals consolidated into CD-4 requested:

- **G7**: Move the verifier filter rule from 6 prose paraphrases into a single script
  (DRY threshold consolidation)
- **G8**: Enforce `change_type:` field name in reviewer agent bodies (prevent
  `category:` / `type:` / `kind:` drift)
- **G11**: Reject finding files with wrong extensions (not `.md`) at fan-in time
- **G12**: Consolidate the verifier filter rule into a single `scripts/verifier-fan-in.sh`
  entry point (the script itself)
- **G13**: Reject out-of-enum `change_type` values at the script level (enum lock)

None of the five goals mention fault-tolerance orchestration, interaction-mode detection,
rescue tiers, or drift counters.

### What CD-4 additionally introduces

Sections E–H of CD-4 add a halt-response and fault-tolerance system that includes:

1. **`orchestrator_rescue: true|false`** — a new `config.md` field that gates whether
   the orchestrator invokes a subagent-resident rescue tier on halt. No goal requested a
   new config field; G7/G12 requested a script.

2. **`drift_count` counter** and **`max_drift_per_round` config field** — a rate-limiting
   mechanism that caps rescue invocations per round. No goal requested a rate-limiting
   mechanism.

3. **`scripts/detect-interaction-mode.sh`** — a new 100+ line script that detects whether
   the current session is in auto or interactive mode by inspecting LLM context, shell
   environment, and an operator override. The script includes per-host verified signals
   (Claude Code `## Auto Mode Active` system-reminder; Copilot CLI `<autopilot_mode>`
   block), a three-layer detection chain, and a `QRSPI_INTERACTION_MODE` env override.
   This is a non-trivial new component. No goal requested auto vs. interactive mode
   detection.

4. **Three-tier rescue architecture** (§H.3): mechanical (script re-run), interpretive
   (orchestrator parses failure reason), and subagent-resident (new subagent spawned to
   present escalation menu). No goal requested a multi-tier rescue system.

5. **Per-finding escalation menus** (§H) with six labeled options (skip / retry /
   override / stop-round / escalate / abort). No goal requested multi-option escalation
   menus.

### Why this is a concern

The YAGNI check is: "no unnecessary components, layers, or abstractions beyond what the
goals require." The halt-response protocol components listed above are internally
self-consistent and technically coherent, but they address a failure-mode class
(orchestrator-halt recovery under auto-mode) that is materially larger than the
requested scope (script consolidation + enum enforcement).

Specific risk: `scripts/detect-interaction-mode.sh` is a platform-signal-dependent script
whose correctness relies on per-host context observation. It introduces a new class of
potential drift (host signals change as CLI tools update) and a new config surface
(`orchestrator_rescue:`, `max_drift_per_round:`). This implementation cost and maintenance
cost were not traded off against any goal that asked for them.

### Recommended action

Flag this explicitly in the design review so the author can confirm the halt-response
protocol scope was intentional (a deliberate extension to solve a real observed problem)
vs. speculative (added because it seemed useful). If intentional, add a rationale note to
CD-4 §§E–H explaining which failure event in v0.7.1 motivated the rescue tiers and
interaction-mode detection specifically. If the scope turns out to be speculative, strip
§§E–H to the minimal halt-and-require-human-intervention model and defer the rescue tiers
to a v0.7.3 goal (after self-host signal shows the need).

The finding is LOW severity because the components are internally consistent and the design
coherence is not broken — the YAGNI concern is about implementation cost and scope
discipline, not correctness.

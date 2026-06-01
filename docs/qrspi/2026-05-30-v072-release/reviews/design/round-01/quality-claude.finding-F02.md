---
finding_id: F02
artifact: design
reviewer: quality-claude
round: 1
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/design.md
---

## No top-level system diagram — component relationships not visible at the architecture level

### Where

`design.md` — entire file (2797 lines). The design quality check requires: "a Mermaid
system diagram is present in `design.md` and describes the system at a level that helps an
implementer understand component relationships."

### What is missing

The file contains exactly one Mermaid diagram: a `sequenceDiagram` inside CD-4 that
depicts the verifier-fan-in round-lifecycle flow. There is no diagram that shows the
overall system's component relationships after the v0.7.2 changes ship.

The architecture introduced by this release is substantial:

- `dispatch-agent.sh` (new — CD-1): the single entry point for all agent dispatches
- `dispatch-companion.sh` (new — CD-1): third-party transport off-LLM
- `second-reviewer-available.sh` (new — G27): probe for second-reviewer availability
- `detect-interaction-mode.sh` (new — CD-4): interaction-mode detection
- `verifier-fan-in.sh` (modified — CD-4): fan-in entry point
- `tools/build-plugin.mjs` (new — G32): `!cat`-expand and strip build pipeline
- `skills/_shared/prompt-prose-detection.md` and siblings (new — G31): shared snippets
- A host × vendor × tier matrix (CD-1) that routes 41 agents across three hosts and
  five tiers
- The relationship between orchestrator → dispatcher → skill → reviewer agent →
  verifier sidecar → verifier-fan-in → kept-findings.txt

An implementer building these 33 goals + 4 cross-goal decisions cannot quickly orient to
how CD-1's dispatch-agent.sh relates to G27's second-reviewer-available.sh, how the
host × vendor matrix interacts with the tier rubric from G22, or how the build output in
`build/` relates to the runtime paths that skill files reference. The sequenceDiagram in
CD-4 covers only one slice of this surface.

### Why this matters at design phase

The design-phase objective is to give an implementer enough architectural orientation that
they can author tasks, implementations, and tests without re-deriving the architecture from
prose. A component diagram (even a high-level one with ~8–12 nodes) would serve that
function. The current document requires reading all 37 sections to reconstruct the
component picture.

### Minimum adequate fix

A single Mermaid component diagram (C4 context level or simple `graph LR`) near the top
of `design.md` (after the Cross-Goal Decisions section headers, before the per-goal
blocks) showing:

- The three hosts (Claude Code, Copilot CLI, Codex CLI)
- The two dispatch-entry scripts (dispatch-agent.sh, dispatch-companion.sh)
- The reviewer agent and verifier agent roles
- The fan-in script and kept-findings.txt as the pipeline output
- The build pipeline (tools/build-plugin.mjs → build/ → plugin install)

A 10-node diagram at this level satisfies the quality check and is sufficient for
implementer orientation. Per-goal diagrams (optional per G1's template) remain optional.

---
finding_id: R1-F04
artifact: structure
severity: high
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
  - docs/qrspi/2026-05-30-v072-release/design.md
---

## Missing component: `scripts/detect-interaction-mode.sh` absent from file map and Interfaces

### What is missing

`scripts/detect-interaction-mode.sh` is not listed in any slice of structure.md's
file map, and its CLI contract does not appear in the `## Interfaces` section.

CD-4 §I.7 of the approved design.md locks a complete, named contract for this script,
including:

- A specific output format (KEY=VALUE pairs on stdout, one per line)
- Three distinct output shapes keyed on `DETECTION_TYPE`:
  - `shell-verdict` (PLATFORM, DETECTION_TYPE, VERDICT, EVIDENCE)
  - `llm-context` (PLATFORM, DETECTION_TYPE, INSTRUCTION)
  - `user-override-only` (DETECTION_TYPE, safe-default `interactive`)
- Exit codes: 0 on successful detection; nonzero only on internal script error
- An implementation-start verification procedure (Iron Law — direct runtime
  observation is mandatory before locking the Copilot-CLI / Claude-Code branches)

The design also carries a locked per-host directory table (verified at design time)
mapping host discriminators to their auto-mode signal and output shape. This is
load-bearing infrastructure for CD-4 §I's halt-response protocol: the orchestrator's
rescue behavior matrix (`orchestrator_rescue` × interaction mode) branches on the
verdict this script returns.

### Why this is a problem

Without a file-map entry, Plan phase will not schedule a task to create this script.
The halt-response protocol (CD-4 §I.1–I.6) is the design's resolution of how to
handle verifier-fan-in halt causes under the two interaction modes. Both modes
(interactive and auto) depend on the orchestrator correctly detecting auto vs.
interactive — which is entirely delegated to `scripts/detect-interaction-mode.sh`
per CD-4 §I.7's "script-encapsulated platform directory" design decision. Without
the script, every halt cause effectively becomes an unclassified escalation, and
the `orchestrator_rescue` config field becomes untestable.

The Interfaces section currently defines 12 interfaces. CD-4 §I.7's contract for
`scripts/detect-interaction-mode.sh` is equally concrete (specific output format
with locked shapes, exit-code semantics) as the other script interfaces defined in
`## Interfaces`. Its absence from that section means the downstream skills (Plan,
Implement) have no interface specification to implement against.

### Expected fix

**File map:** Add a Create entry to Slice 1.1 or Slice 1.2 (whichever carries the
verifier halt-response protocol work):

| `scripts/detect-interaction-mode.sh` | Create | Encapsulate per-host auto-mode detection; return shell-verdict, llm-context instruction, or user-override-only signal depending on the active host. | CD-4 |

**Interfaces section:** Add Interface #13 (or renumber as appropriate) for this
script, using the contract format locked in CD-4 §I.7:

```text
# scripts/detect-interaction-mode.sh
# Usage: detect-interaction-mode.sh (no arguments)
# Exit 0: detection succeeded (including safe-default branch)
# Exit non-zero: internal script error only
# Stdout: KEY=VALUE pairs, one per line; DETECTION_TYPE ∈ {shell-verdict, llm-context, user-override-only}
# shell-verdict: PLATFORM=<name> DETECTION_TYPE=shell-verdict VERDICT=auto|interactive EVIDENCE=<signal>
# llm-context:  PLATFORM=<name> DETECTION_TYPE=llm-context INSTRUCTION=<prose>
# user-override-only: DETECTION_TYPE=user-override-only
```

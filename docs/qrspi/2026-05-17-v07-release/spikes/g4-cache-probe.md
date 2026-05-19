---
run_id: stub-pending-live-execution
artifact: g4-cache-probe
generated_by: docs/qrspi/2026-05-17-v07-release/spikes/g4-cache-probe.md (stub authored at v0.7 T33; replaced verbatim by scripts/g4-cache-probe.sh on live execution)
---

# G4 Mechanism A Cache-Probe Report (STUB — pending live execution)

This file is the **stub** authored at v0.7 T33 implementation time. It
establishes the report shape and the load-bearing Decision section consumed
by T36 (`test-cache-hit-rate.bats`) and the conditional T43 marker-insertion
task (Wave 9). The script `scripts/g4-cache-probe.sh` replaces this file
verbatim — including the Decision section — when the operator runs it
against the live Anthropic API.

## Run

- run_id: stub-pending-live-execution
- invocation_timestamp: stub-pending-live-execution

## Measurement: Cache Metadata Exposure

Does the Claude Code Agent({}) dispatch response surface Anthropic cache-hit
metadata fields (`cache_creation_input_tokens`, `cache_read_input_tokens`)?

- metadata_exposed: pending

## Measurement: Captured Cache-Hit Values

Each row is one of the three probe dispatches. All three dispatches share a
byte-identical system-prompt prefix (the verbatim body of
`skills/reviewer-protocol/SKILL.md`); only the per-call tail varies.

| call | cache_creation_input_tokens | cache_read_input_tokens |
| ---- | --------------------------- | ----------------------- |
| 1    | pending                     | pending                 |
| 2    | pending                     | pending                 |
| 3    | pending                     | pending                 |

The `none` sentinel (used by the live script) means the response payload
did not include the field at all (distinct from a numeric `0`, which means
the field was present but no cache hit occurred). In this stub all six
cells are `pending` until the script runs against live API.

## Decision

Pending — operator runs scripts/g4-cache-probe.sh against live Anthropic API before this decision lands.

Derivation rule the live script applies (three possible branches):

1. **Metadata not exposed at all** — all six captured cells are the `none`
   sentinel. Path B is REQUIRED: Mechanism A scope expands to include
   `cache_control` marker insertion at the Anthropic SDK boundary, AND a
   follow-up measurement task must verify the markers produce surfaced hits.

2. **Metadata exposed but zero hits** — fields are numeric; `cache_read`
   on calls 2 and 3 both `== 0`. Path B selected: Mechanism A scope expands
   to include `cache_control` marker insertion at the Anthropic SDK boundary.

3. **Path A selected** — `cache_read` on call 2 OR call 3 `> 0`. Agent({})
   dispatch path already caches stable prefixes automatically. Mechanism A
   scope is instrument + measure only; `cache_control` marker insertion is
   NOT required.

## Consumers

- T36 `test-cache-hit-rate.bats` consumes this report's Decision section to
  select its Path-A vs Path-B fixture set (the Path-conditional fixture pin).
  Until the Decision section is populated by a live run, T36 treats the
  Path-conditional pin as deferred.
- Any follow-up `cache_control` marker-insertion task is gated by the
  Decision section above; T43 (conditional, Wave 9) is skipped when Path A
  is selected (or skipped while this stub stands pending — its conditional
  gate fails to fire against a Pending Decision).

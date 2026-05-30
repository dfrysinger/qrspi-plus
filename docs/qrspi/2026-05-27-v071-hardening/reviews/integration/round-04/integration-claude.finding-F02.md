---
finding_id: R4-F02
severity: high
change_type: correctness
referenced_files: [skills/using-qrspi/SKILL.md]
artifact: integration
round: 4
reviewer: integration-claude
materialized_by: orchestrator
materialization_reason: reviewer environment writes output to response text only; orchestrator materializes
---

# integration-claude F02 — `model_routing:` fail-loud contract is invisible to the shared Config Validation Procedure

**Category:** Cross-task interface mismatch (T10 fail-loud paragraph ↔ pre-existing Config Validation Procedure)

T10's R2 fail-loud paragraph at `skills/using-qrspi/SKILL.md:470` establishes three structural invariants for `model_routing:` and states the dispatcher "halts and reports the missing or invalid entry … never falls back silently to the agent-bundled default and never passes the dispatch through to the host CLI's silent re-routing." The vocab tests at `tests/unit/test-using-qrspi-vocab.bats:911-922` pin both the "halts and reports" wording and the absence of "silently fall back to the agent-bundled default" / "silently degrade" anti-patterns. Good.

But the **shared** Config Validation Procedure that "every skill that reads config.md applies … before using any field" (`SKILL.md:548-550`) does not list `model_routing` in its behavior-affecting-fields table (`SKILL.md:641-660`), and the existing `#### Missing model_routing: block in config.md` section (`SKILL.md:510-520`) documents the **absent-block** case as a one-time-warning + in-memory-defaults fallback. The "Dispatch routing blocks" preamble at `SKILL.md:422` still asserts they are "optional in the config.md frontmatter — their absence means dispatch falls back to agent-bundled defaults."

Two incompatible contracts now coexist for the same field:

| Source | Behavior on partial corruption | Behavior on absent block |
|---|---|---|
| T10 fail-loud paragraph (`L470`) | HALT, never fall back | (silent on absent — covered below) |
| Missing-block H4 (`L510-520`) | (silent on partial — covered above) | Warn once, apply in-memory defaults |
| Dispatch-blocks preamble (`L420-422`) | "optional"; absence → fall back | "optional"; absence → fall back |
| Behavior-affecting fields table (`L641-660`) | `model_routing` not listed at all | `model_routing` not listed at all |

A skill consumer following the canonical Config Validation Procedure literally has no obligation to apply the new fail-loud invariants — the field doesn't appear in the validation table. A skill consumer following the dispatch-blocks preamble would believe partial corruption falls back silently, contradicting the fail-loud paragraph. The G7b/#204 silent-fallback class re-opens one validation layer up.

**Concrete failure path:** a downstream skill (e.g. `skills/implement/SKILL.md` or `skills/parallelize/SKILL.md` doing per-task dispatch) reads `config.md`, applies the Config Validation Procedure (which says nothing about `model_routing`), passes validation with a corrupted-but-present `model_routing` (say, missing the `copilot-cli` sub-mapping), and proceeds to dispatch. The fail-loud paragraph at `L470` lives in the SKILL.md and asserts a dispatcher behavior, but no implementing skill is contractually bound to honor it because the validation table — which IS the cross-skill binding surface — omits the field.

**Fix:** Add a row for `model_routing` to the behavior-affecting-fields table at `SKILL.md:641-660` and define the exact missing-host / missing-tier / bare-short-form failure menus there. Cross-link the new row to the fail-loud paragraph at L470 so the dispatcher contract and the validation contract are co-located by reference. Optionally also reconcile the dispatch-blocks preamble at `L420-422` to distinguish "absent-block fallback (intentional)" from "partial-corruption hard-stop" so the two adjacent contracts no longer read as contradictions.

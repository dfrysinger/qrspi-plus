---
finding_id: F01
severity: high
change_type: correctness
referenced_files: [skills/using-qrspi/SKILL.md]
artifact: integration
round: 4
reviewer: integration-codex
materialized_by: orchestrator
materialization_reason: gpt-5.5 reviewer environment forbids file writes; finding returned inline
---

# integration-codex F01 — `model_routing` fail-loud not propagated to shared Config Validation Procedure

**Severity:** High
**Category:** Cross-task consistency / missing error handling at call boundary

T10 documents `model_routing:` as a dispatch-critical field whose host/tier invariants are validated "at config-load time and on every dispatch," and says the dispatcher halts on missing host/tier or bare short-form values (`skills/using-qrspi/SKILL.md:466-470`). However, the shared Config Validation Procedure that "every skill that reads config.md applies" (`skills/using-qrspi/SKILL.md:548-550`) does not include `model_routing` in the behavior-affecting fields table (`skills/using-qrspi/SKILL.md:641-653`). Nearby legacy prose still says the dispatch routing blocks are optional and absence falls back to agent-bundled defaults (`skills/using-qrspi/SKILL.md:420-422`), and the missing-`model_routing` section explicitly documents fallback behavior (`skills/using-qrspi/SKILL.md:510-520`).

This leaves two incompatible contracts for the same boundary: T10 says partial corruption must halt, while the shared validator contract gives consumers no validation obligation or menu for `model_routing`. A skill following the validation table can skip the new fail-loud checks and re-open the silent/default routing class T10 is trying to close.

**Fix:** Add `model_routing` to the Config Validation Procedure's behavior-affecting fields and define the exact missing/invalid-host/invalid-tier/bare-short-form failure menus, OR explicitly scope the fail-loud paragraph to "when the block is present" and keep absent-block fallback as intentional.

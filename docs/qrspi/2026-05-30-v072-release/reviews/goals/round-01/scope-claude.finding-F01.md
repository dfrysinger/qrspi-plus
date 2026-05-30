---
finding_id: R1-F01
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-30-v072-release/goals.md]
artifact: goals
round: 1
reviewer: scope-claude
---

**G27 "What we know so far" contains a preferred implementation commitment — verbatim bash code with a "(preferred)" label — that belongs in Design or Plan, not Goals.**

The OWNS rule for Goals permits solution IDEAS under "What we know so far" only "framed as candidates Design should weigh — never as commitments." G27's "Fix shape" section labels option 1 as "(preferred)":

> **Direct shell call at probe time (preferred):** `bash -c 'set -e; QRSPI_SOURCE_ONLY=1 source scripts/run-codex-review.sh; check_codex_available "$(detect_host)"'`

Two violations compound here:

1. **Commitment framing.** The "(preferred)" label converts what should be a candidate into a committed direction. Goals is pre-selecting the implementation approach before Design deliberation has occurred. If Design concludes the direct shell-call has drawbacks (e.g., sourcing a production script into the Goals-phase agent context carries test-isolation risk; the `QRSPI_SOURCE_ONLY=1` flag convention may not be stable), the pre-selected preference creates momentum against revisiting the decision.

2. **Implementation logic.** The verbatim bash command (`set -e`, `source scripts/run-codex-review.sh`, `check_codex_available "$(detect_host)"`) is implementation logic — specific flags, function invocations, and argument patterns. The Goals DEFERS rule explicitly assigns "Implementation logic, function signatures, assertion text → Structure / Plan / Implement." This level of specificity belongs at minimum in a Design decision (solution definition) and ultimately in the task spec or implementation artifact.

**Expected correction:** Remove the "(preferred)" label from option 1 and reframe both options as "Candidates Design should weigh:" with no preference indicated. The verbatim bash command may remain as a solution idea if it loses the commitment marker and is folded under a "Candidates Design should weigh" lead, but the specific bash invocation details (flags, exact function call) could be compressed to intent ("invoke `check_codex_available` via `detect_host` rather than replicating the probe inline") rather than literal code.

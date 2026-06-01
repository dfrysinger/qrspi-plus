---
finding_id: R4-F01
severity: high
change_type: correctness
referenced_files:
  - design.md (CD-4 § I.7)
---

## Issue
I.7 assigns `.interaction-mode-audit.json` to the wrong writer and leaves the write contract internally contradictory: the section says the audit file is written by `scripts/detect-interaction-mode.sh`, but the required `evidence` for `DETECTION_TYPE=llm-context` must be observed by the orchestrator from LLM context (which the script cannot access). The script contract also only specifies stdout key/value output, not a round-dir input needed to write a round-scoped file.

## Why it matters
This blocks deterministic implementation of interaction-mode auditing: implementers cannot satisfy both the script contract and the audit-file contract at once, and different implementations will diverge on who writes the file and when.

## Proposed change
Make ownership explicit and single-source: either (A) orchestrator writes `.interaction-mode-audit.json` after executing script output + context check, or (B) script writes only script-observable fields and orchestrator appends context evidence in a second step. Also lock the invocation surface needed for round-dir targeting.

## Citation
- design.md:L628-L637
- design.md:L653-L654
- design.md:L671-L677
